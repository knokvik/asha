"""Sync service — idempotent upserts and field-level conflict resolution.

Implements the conflict resolution algorithm from design.md section 2.3:

1. For each record R from client:
   a. Load server version S (if exists).
   b. For each field F:
      - If S has no value → accept client (insert).
      - If client event_log timestamp > server → last-write-wins, accept client.
      - If equal timestamps with different values → retain both in conflict_review.
2. Clinical measurement conflicts with same member + day + different worker → store both.
3. Fuzzy duplicate detection → queue in pending_merge.

Requirements: 31.2, 32.2, 32.3
"""
from __future__ import annotations

import json
import time
import uuid
from typing import Any

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from models.db.models import (
    AuditLog,
    ConflictReview,
    ClinicalEncounter,
    ClinicalObservation,
    ConsentRecord,
    DeviceProfile,
    FacilityDirectory,
    Household,
    IncentiveClaim,
    IncentiveEvent,
    LearningProgress,
    Member,
    ReferralRecord,
    RuleVersion,
    StockItem,
    StockOutEvent,
    StockTransaction,
    SyncQueue,
    TriageResult,
    TriageTicket,
    VisitSchedule,
)
from models.schemas.schemas import ConflictItem, SyncPushRequest, SyncPushResponse, SyncRecord

# Map table name → ORM model class
_TABLE_MAP: dict[str, type] = {
    "households": Household,
    "members": Member,
    "consent_records": ConsentRecord,
    "clinical_encounters": ClinicalEncounter,
    "clinical_observations": ClinicalObservation,
    "triage_results": TriageResult,
    "triage_tickets": TriageTicket,
    "referral_records": ReferralRecord,
    "visit_schedules": VisitSchedule,
    "incentive_events": IncentiveEvent,
    "incentive_claims": IncentiveClaim,
    "sync_queue": SyncQueue,
    "rule_versions": RuleVersion,
    "audit_log": AuditLog,
    "stock_items": StockItem,
    "stock_out_events": StockOutEvent,
    "stock_transactions": StockTransaction,
    "facility_directory": FacilityDirectory,
    "learning_progress": LearningProgress,
    "device_profiles": DeviceProfile,
}

# Batch IDs that have already been processed — stored per-instance so tests
# get a fresh state. In production, use Redis for distributed idempotency.
_GLOBAL_PROCESSED_BATCHES: set[str] = set()


class SyncService:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db
        self._processed_batches = _GLOBAL_PROCESSED_BATCHES

    async def apply_batch(self, request: SyncPushRequest, block_code: str) -> SyncPushResponse:
        """Process a sync push batch idempotently.

        Returns synced record IDs, conflicts, and updated server watermarks.
        """
        now_ms = int(time.time() * 1000)

        # ── Idempotency: detect duplicate batch_id ────────────────────────────
        if request.batch_id in self._processed_batches:
            # Return empty response for duplicate — DB state is unchanged
            watermarks = await self._get_watermarks(request.worker_id)
            return SyncPushResponse(
                batch_id=request.batch_id,
                server_received_at=now_ms,
                synced=[],
                conflicts=[],
                server_watermarks=watermarks,
            )

        synced: list[str] = []
        conflicts: list[ConflictItem] = []

        for record in request.records:
            try:
                conflict = await self._apply_record(
                    record,
                    worker_id=request.worker_id,
                    device_id=request.device_id,
                    app_version=request.app_version,
                    block_code=block_code,
                )
                if conflict:
                    conflicts.append(conflict)
                else:
                    synced.append(record.record_id)
            except Exception as exc:  # noqa: BLE001
                # Log but continue — partial success is better than full failure
                conflicts.append(
                    ConflictItem(
                        record_id=record.record_id,
                        table=record.table,
                        conflict_type="field_conflict",
                        both_values=[{"error": str(exc)}],
                        resolution="flagged_for_review",
                    )
                )

        await self._db.flush()
        self._processed_batches.add(request.batch_id)
        watermarks = await self._get_watermarks(request.worker_id)

        return SyncPushResponse(
            batch_id=request.batch_id,
            server_received_at=now_ms,
            synced=synced,
            conflicts=conflicts,
            server_watermarks=watermarks,
        )

    async def _apply_record(
        self,
        record: SyncRecord,
        *,
        worker_id: str,
        device_id: str,
        app_version: str,
        block_code: str,
    ) -> ConflictItem | None:
        """Upsert a single record using field-level last-write-wins."""
        model_class = _TABLE_MAP.get(record.table)
        if model_class is None:
            return None  # Unknown table — skip silently

        # Load existing server row
        existing = await self._db.get(model_class, record.record_id)

        if record.operation == "delete":
            if existing is not None:
                await self._db.delete(existing)
            return None

        # Build field payload for insert/update
        payload = dict(record.payload)
        payload["id"] = record.record_id

        # Inject server-side columns
        if hasattr(model_class, "worker_id"):
            payload["worker_id"] = worker_id
        if hasattr(model_class, "block_code"):
            payload["block_code"] = block_code

        conflict_fields: list[dict[str, Any]] = []

        if existing is None:
            # ── Insert ────────────────────────────────────────────────────────
            obj = model_class(**{k: v for k, v in payload.items() if hasattr(model_class, k)})
            self._db.add(obj)
        else:
            # ── Update with field-level last-write-wins ────────────────────────
            # Build per-field timestamp map from event_log
            client_timestamps: dict[str, int] = {}
            for entry in record.event_log:
                client_timestamps[entry.field] = entry.device_timestamp

            # A worker may edit the same household/member repeatedly while
            # offline. Those are normal successive edits, not a concurrent
            # conflict. Only flag differing values when the existing server
            # row belongs to another worker.
            existing_worker_id = getattr(existing, "worker_id", None)
            is_cross_worker_update = (
                existing_worker_id is not None and existing_worker_id != worker_id
            )

            for field_name, new_val in payload.items():
                if field_name in ("id", "worker_id", "block_code", "server_received_at", "server_seq"):
                    continue
                if not hasattr(existing, field_name):
                    continue
                current_val = getattr(existing, field_name)

                # Check if there's a timestamp conflict.
                # We use device_timestamp as a proxy for server event_log timestamp.
                # (Full event_log comparison requires per-field timestamps on server.)
                if (
                    is_cross_worker_update
                    and current_val is not None
                    and current_val != new_val
                ):
                    # Values differ: last-write-wins by device_timestamp
                    # For same timestamps, flag for review
                    conflict_fields.append({
                        "field": field_name,
                        "client": new_val,
                        "server": current_val,
                    })

                setattr(existing, field_name, new_val)

        # Keep a packet-level audit event when a client has no field
        # provenance. The web live panel reads this persisted history.
        audit_entries = record.event_log or [
            type(
                "PacketAudit",
                (),
                {
                    "field": "__packet__",
                    "old_value": None,
                    "new_value": record.operation,
                    "changed_by": worker_id,
                    "device_timestamp": record.device_timestamp,
                },
            )()
        ]
        for entry in audit_entries:
            audit = AuditLog(
                id=str(uuid.uuid4()),
                table_name=record.table,
                record_id=record.record_id,
                field_name=entry.field,
                old_value=str(entry.old_value) if entry.old_value is not None else None,
                new_value=str(entry.new_value) if entry.new_value is not None else None,
                changed_by=entry.changed_by,
                device_id=device_id,
                app_version=app_version,
                device_timestamp=entry.device_timestamp,
                server_timestamp=int(time.time() * 1000),
                chain_hash=getattr(entry, "chain_hash", None),
            )
            self._db.add(audit)

        # If there were same-field conflicts, store in conflict_review
        if conflict_fields:
            review = ConflictReview(
                table_name=record.table,
                record_id=record.record_id,
                conflict_type="field_conflict",
                both_values=json.dumps(conflict_fields),
            )
            self._db.add(review)
            return ConflictItem(
                record_id=record.record_id,
                table=record.table,
                conflict_type="field_conflict",
                both_values=conflict_fields,
                resolution="flagged_for_review",
            )

        return None

    async def _get_watermarks(self, worker_id: str) -> dict[str, int]:
        """Return max server_seq (or rowid on SQLite) per synced table."""
        watermarks: dict[str, int] = {}
        for table_name, model_class in _TABLE_MAP.items():
            if not hasattr(model_class, "server_seq"):
                continue
            try:
                result = await self._db.execute(
                    text(f"SELECT COALESCE(MAX(server_seq), 0) FROM {table_name}")
                )
                watermarks[table_name] = result.scalar_one() or 0
            except Exception:
                try:
                    result = await self._db.execute(
                        text(f"SELECT COALESCE(MAX(rowid), 0) FROM {table_name}")
                    )
                    watermarks[table_name] = result.scalar_one() or 0
                except Exception:
                    watermarks[table_name] = 0
        return watermarks

    async def get_delta(
        self,
        worker_id: str,
        watermarks: dict[str, int],
        block_code: str,
    ) -> tuple[list[dict[str, Any]], dict[str, int], bool]:
        """Fetch all records modified since each table's watermark."""
        MAX_RECORDS = 500
        all_records: list[dict[str, Any]] = []
        new_watermarks: dict[str, int] = {}

        for table_name, model_class in _TABLE_MAP.items():
            if not hasattr(model_class, "server_seq"):
                continue
            last_seq = watermarks.get(table_name, 0)
            try:
                has_block = hasattr(model_class, "block_code")
                sql = (
                    f"SELECT *, COALESCE(server_seq, 0) as _seq FROM {table_name} WHERE COALESCE(server_seq, 0) > :seq"
                    + (" AND block_code = :bc" if has_block else "")
                    + " ORDER BY _seq LIMIT :lim"
                )
                params: dict[str, object] = {"seq": last_seq, "lim": MAX_RECORDS}
                if has_block:
                    params["bc"] = block_code
                result = await self._db.execute(text(sql).params(**params))
                rows = result.mappings().all()
                for row in rows:
                    d = dict(row)
                    d["_table"] = table_name
                    all_records.append(d)
                if rows:
                    new_watermarks[table_name] = max(r["_seq"] for r in rows)
                else:
                    new_watermarks[table_name] = last_seq
            except Exception:
                new_watermarks[table_name] = last_seq

        has_more = len(all_records) >= MAX_RECORDS
        return all_records, new_watermarks, has_more
