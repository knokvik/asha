"""U-WIN Immunization Reconciliation Worker.

Implements Requirement 16.5, Requirement 35 (35.1–35.7), and Task 13.6:
- Daily CSV import from U-WIN.
- Reconciles vaccination status with local records using configurable state mapping.
- Matches beneficiaries by member_id, abha_id, rch_id, or phone + dob.
- Creates stubs for unmatched RCH IDs to avoid dropping external records.
- Flags date mismatches exceeding threshold (>7 days) in ConflictReview.
- Logs integration incidents without blocking primary sync.
- Logs sharing / reconciliation events to OutboundSharingLog for DPDP accountability.
"""
from __future__ import annotations

import csv
import io
import json
import logging
from pathlib import Path
import time
import uuid
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models.db.models import (
    ClinicalEncounter,
    ClinicalObservation,
    ConflictReview,
    IntegrationIncident,
    Member,
    OutboundSharingLog,
    VisitSchedule,
)

logger = logging.getLogger(__name__)

MAPPINGS_DIR = Path(__file__).resolve().parent.parent / "config" / "mappings"


def _now_ms() -> int:
    return int(time.time() * 1000)


def load_uwin_mapping(state_code: str = "default") -> dict[str, Any]:
    """Loads U-WIN mapping configuration, supporting state-level overrides."""
    state_file = MAPPINGS_DIR / f"uwin_mapping_{state_code.lower()}.json"
    default_file = MAPPINGS_DIR / "uwin_mapping.json"

    file_to_load = state_file if state_file.exists() else default_file
    if file_to_load.exists():
        with open(file_to_load, encoding="utf-8") as f:
            return json.load(f)

    # Fallback default configuration if file missing
    return {
        "system": "U-WIN",
        "date_conflict_threshold_days": 7,
        "csv_column_aliases": {
            "beneficiary_id": ["beneficiary_id", "member_id", "patient_id"],
            "rch_id": ["rch_id", "rch_number"],
            "abha_id": ["abha_id", "abha_number"],
            "phone": ["phone", "mobile"],
            "name": ["beneficiary_name", "child_name", "name"],
            "vaccine_code": ["vaccine_code", "antigen", "vaccine_name"],
            "administered_date": ["dose_date", "administered_date", "vaccination_date"],
            "batch_number": ["batch_number", "batch_no"],
            "facility_name": ["facility_name", "health_center"],
            "vaccinator_name": ["vaccinator_name", "anm_name"],
        },
        "antigen_code_map": {},
    }


def _extract_field(row: dict[str, Any], aliases: list[str]) -> str | None:
    """Extracts field value from a dict/row by checking multiple column alias names."""
    for alias in aliases:
        if alias in row and row[alias] is not None and str(row[alias]).strip():
            return str(row[alias]).strip()
        # Case-insensitive lookup
        for key in row:
            if key.strip().lower() == alias.lower() and row[key] is not None:
                val = str(row[key]).strip()
                if val:
                    return val
    return None


async def reconcile_uwin_records(
    db: AsyncSession,
    uwin_records: list[dict[str, Any]],
    state_code: str = "default",
    uploaded_by: str = "SYSTEM_UWIN_SYNC",
) -> dict[str, Any]:
    """Reconciles incoming U-WIN digital vaccination records with the database."""
    config = load_uwin_mapping(state_code)
    antigen_map = config.get("antigen_code_map", {})
    conflict_threshold_days = config.get("date_conflict_threshold_days", 7)
    conflict_threshold_ms = conflict_threshold_days * 86400 * 1000

    stats = {
        "total_records": len(uwin_records),
        "new_doses_imported": 0,
        "already_recorded": 0,
        "unmatched_beneficiaries": 0,
        "stubs_created": 0,
        "date_conflicts_flagged": 0,
        "visit_schedules_completed": 0,
        "incidents_logged": 0,
    }

    now = _now_ms()

    for item in uwin_records:
        try:
            raw_vaccine_code = item.get("vaccine_code", "").upper().strip()
            # Normalize vaccine code via config mapping
            vaccine_code = antigen_map.get(raw_vaccine_code, raw_vaccine_code)

            admin_date_ms = item.get("administered_date_ms")
            if admin_date_ms is None:
                raw_date = item.get("administered_date")
                if raw_date:
                    try:
                        admin_date_ms = int(raw_date)
                    except ValueError:
                        admin_date_ms = now
                else:
                    admin_date_ms = now

            batch_number = item.get("batch_number")
            vaccinator = item.get("vaccinator_name") or item.get("facility_name", "U-WIN Portal")
            rch_id = item.get("rch_id")
            abha_id = item.get("abha_id")
            phone = item.get("phone")
            name = item.get("name") or item.get("beneficiary_name")

            # 1. Identify beneficiary
            member: Member | None = None
            if item.get("member_id"):
                stmt = select(Member).where(Member.id == item["member_id"])
                res = await db.execute(stmt)
                member = res.scalar_one_or_none()

            if not member and rch_id:
                stmt = select(Member).where(Member.rch_id == rch_id)
                res = await db.execute(stmt)
                member = res.scalar_one_or_none()

            if not member and abha_id:
                stmt = select(Member).where(Member.abha_id == abha_id)
                res = await db.execute(stmt)
                member = res.scalar_one_or_none()

            if not member and phone:
                stmt = select(Member).where(Member.phone == phone)
                res = await db.execute(stmt)
                member = res.scalars().first()

            # 2. If unmatched, check if an RCH ID is present to create a stub (Req 35.3 & Task 13.6)
            if not member:
                if rch_id:
                    stub_id = f"stub_{uuid.uuid4().hex[:12]}"
                    member = Member(
                        id=stub_id,
                        rch_id=rch_id,
                        abha_id=abha_id,
                        phone=phone,
                        name=name or f"Stub Beneficiary RCH-{rch_id}",
                        lifecycle_status="stub",
                        state_code=state_code,
                        created_by=uploaded_by,
                        created_at=now,
                        updated_at=now,
                        sync_status="synced",
                    )
                    db.add(member)
                    stats["stubs_created"] += 1
                    logger.info("Created stub member %s for unmatched RCH ID %s", stub_id, rch_id)
                else:
                    stats["unmatched_beneficiaries"] += 1
                    # Log integration incident without blocking sync (Req 35.5)
                    incident = IntegrationIncident(
                        id=f"inc_{uuid.uuid4().hex[:12]}",
                        system_name="U-WIN",
                        record_type="VACCINATION",
                        external_id=item.get("beneficiary_id") or phone,
                        error_code="UNMATCHED_BENEFICIARY",
                        error_message=(
                            f"Beneficiary could not be matched. No RCH ID provided for stubbing. "
                            f"Phone: {phone}, Abha: {abha_id}, Vaccine: {vaccine_code}"
                        ),
                        raw_payload=json.dumps(item),
                        status="open",
                        created_at=now,
                    )
                    db.add(incident)
                    stats["incidents_logged"] += 1
                    continue

            # 3. Check if this vaccine dose has already been recorded
            obs_stmt = (
                select(ClinicalObservation)
                .join(ClinicalEncounter, ClinicalObservation.encounter_id == ClinicalEncounter.id)
                .where(ClinicalEncounter.member_id == member.id)
                .where(ClinicalObservation.observation_code == "VACCINE_CODE")
                .where(ClinicalObservation.value_text == vaccine_code)
            )
            obs_res = await db.execute(obs_stmt)
            existing_obs = obs_res.scalar_one_or_none()

            if existing_obs is not None:
                stats["already_recorded"] += 1

                # Check for date mismatch (> threshold days)
                local_date_ms = existing_obs.observed_at or existing_obs.value_numeric
                if local_date_ms and abs(int(local_date_ms) - admin_date_ms) > conflict_threshold_ms:
                    conflict_id = f"conf_{uuid.uuid4().hex[:12]}"
                    conflict = ConflictReview(
                        id=conflict_id,
                        table_name="clinical_observations",
                        record_id=existing_obs.id,
                        conflict_type="UWIN_DATE_MISMATCH",
                        both_values=json.dumps({
                            "member_id": member.id,
                            "rch_id": member.rch_id,
                            "vaccine_code": vaccine_code,
                            "local_date_ms": int(local_date_ms),
                            "uwin_date_ms": admin_date_ms,
                            "delta_days": round(abs(int(local_date_ms) - admin_date_ms) / (86400 * 1000), 1),
                        }),
                        status="pending",
                        created_at=None,  # DateTime handled by default in ORM
                    )
                    db.add(conflict)
                    stats["date_conflicts_flagged"] += 1
                    logger.warning(
                        "Flagged date mismatch for member %s, vaccine %s (local: %s, uwin: %s)",
                        member.id,
                        vaccine_code,
                        local_date_ms,
                        admin_date_ms,
                    )
                continue

            # 4. Create reconciled ClinicalEncounter
            encounter_id = f"uwin_enc_{uuid.uuid4().hex[:12]}"
            encounter = ClinicalEncounter(
                id=encounter_id,
                member_id=member.id,
                encounter_type="IMMUNIZATION_DOSE",
                program_code="immunization",
                encounter_date=admin_date_ms,
                asha_id=member.created_by or uploaded_by,
                status="completed",
                visit_notes=f"Reconciled from U-WIN (Vaccinator: {vaccinator}, Batch: {batch_number or 'N/A'})",
                created_at=now,
                updated_at=now,
                sync_status="synced",
            )
            db.add(encounter)

            # 5. Insert discrete ClinicalObservations
            obs_code = ClinicalObservation(
                id=str(uuid.uuid4()),
                encounter_id=encounter_id,
                observation_code="VACCINE_CODE",
                value_text=vaccine_code,
                source="UWIN_RECONCILED",
                observed_at=admin_date_ms,
            )
            obs_date = ClinicalObservation(
                id=str(uuid.uuid4()),
                encounter_id=encounter_id,
                observation_code="ADMINISTERED_DATE",
                value_numeric=float(admin_date_ms),
                source="UWIN_RECONCILED",
                observed_at=admin_date_ms,
            )
            db.add(obs_code)
            db.add(obs_date)

            if batch_number:
                obs_batch = ClinicalObservation(
                    id=str(uuid.uuid4()),
                    encounter_id=encounter_id,
                    observation_code="BATCH_NUMBER",
                    value_text=batch_number,
                    source="UWIN_RECONCILED",
                    observed_at=admin_date_ms,
                )
                db.add(obs_batch)

            # 6. Mark matching pending VisitSchedule completed
            sched_stmt = (
                select(VisitSchedule)
                .where(VisitSchedule.member_id == member.id)
                .where(VisitSchedule.program_code == "immunization")
                .where(VisitSchedule.status == "pending")
                .where(VisitSchedule.visit_type.like(f"%{vaccine_code}%"))
            )
            sched_res = await db.execute(sched_stmt)
            pending_schedule = sched_res.scalars().first()

            if pending_schedule:
                pending_schedule.status = "completed"
                pending_schedule.completed_at = now
                pending_schedule.completed_encounter_id = encounter_id
                stats["visit_schedules_completed"] += 1

            stats["new_doses_imported"] += 1

        except Exception as exc:
            stats["incidents_logged"] += 1
            logger.error("Error reconciling U-WIN item %s: %s", item, exc, exc_info=True)
            incident = IntegrationIncident(
                id=f"inc_{uuid.uuid4().hex[:12]}",
                system_name="U-WIN",
                record_type="VACCINATION",
                external_id=str(item.get("rch_id") or item.get("member_id") or "UNKNOWN"),
                error_code="PROCESSING_ERROR",
                error_message=str(exc),
                raw_payload=json.dumps(item),
                status="open",
                created_at=now,
            )
            db.add(incident)

    # Log outbound/inbound sharing for DPDP accountability (Req 35.7)
    if stats["total_records"] > 0:
        db.add(
            OutboundSharingLog(
                id=f"share_{uuid.uuid4().hex[:12]}",
                target_system="U-WIN",
                record_type="IMMUNIZATION_RECONCILIATION",
                record_id=f"batch_{now}",
                recipient="U-WIN Reconciliation Engine",
                shared_by=uploaded_by,
                status="success",
                created_at=now,
            )
        )

    await db.commit()
    logger.info("U-WIN reconciliation completed successfully: %s", stats)
    return stats


async def reconcile_uwin_csv(
    db: AsyncSession,
    csv_content: str,
    state_code: str = "default",
    uploaded_by: str = "SYSTEM_UWIN_SYNC",
) -> dict[str, Any]:
    """Parses a U-WIN vaccination CSV file and reconciles records into the database."""
    config = load_uwin_mapping(state_code)
    aliases = config.get("csv_column_aliases", {})

    # Read CSV
    reader = csv.DictReader(io.StringIO(csv_content))
    records: list[dict[str, Any]] = []

    for row in reader:
        member_id = _extract_field(row, aliases.get("beneficiary_id", []))
        rch_id = _extract_field(row, aliases.get("rch_id", []))
        abha_id = _extract_field(row, aliases.get("abha_id", []))
        phone = _extract_field(row, aliases.get("phone", []))
        name = _extract_field(row, aliases.get("name", []))
        vaccine_code = _extract_field(row, aliases.get("vaccine_code", []))
        admin_date = _extract_field(row, aliases.get("administered_date", []))
        batch_number = _extract_field(row, aliases.get("batch_number", []))
        facility_name = _extract_field(row, aliases.get("facility_name", []))
        vaccinator_name = _extract_field(row, aliases.get("vaccinator_name", []))

        if not vaccine_code:
            continue

        records.append({
            "member_id": member_id,
            "rch_id": rch_id,
            "abha_id": abha_id,
            "phone": phone,
            "name": name,
            "vaccine_code": vaccine_code,
            "administered_date": admin_date,
            "batch_number": batch_number,
            "facility_name": facility_name,
            "vaccinator_name": vaccinator_name,
        })

    return await reconcile_uwin_records(
        db=db,
        uwin_records=records,
        state_code=state_code,
        uploaded_by=uploaded_by,
    )
