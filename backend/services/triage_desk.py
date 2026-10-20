"""PHC ticket desk and context-pack loop.

Merge rule: for each ward, week, and condition, the count with the later
observed_at is kept. When the timestamps are equal, an app-reported syndromic
flag wins over the authoritative baseline. The weekly job writes that merged
table into the next context pack. A pack version bump is what the on-device
engine reads on the next sync.
"""
from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import datetime, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models.db.desk import (
    ContextPackBlob,
    DeskIdempotency,
    DeskOutcome,
    DeskTicket,
    DiseaseCountRow,
)

RED_SLA = timedelta(hours=4)
BATCH_LIMIT = 50
POPULATION = 8000

@dataclass(frozen=True)
class CountPoint:
    ward_id: str
    week: int
    condition: str
    count: int
    source: str
    observed_at: datetime


def merge_counts(rows: list[CountPoint]) -> list[CountPoint]:
    best: dict[tuple[str, int, str], CountPoint] = {}
    for row in rows:
        key = (row.ward_id, row.week, row.condition)
        current = best.get(key)
        if current is None:
            best[key] = row
            continue
        if row.observed_at > current.observed_at:
            best[key] = row
        elif row.observed_at == current.observed_at and row.source == "app" and current.source != "app":
            best[key] = row
    return list(best.values())


def pack_etag(version: int) -> str:
    return f'W/"pcmc-{version}"'


def _parse_time(value: str | None) -> datetime:
    if not value:
        return datetime.utcnow()
    text = value.replace("Z", "+00:00")
    parsed = datetime.fromisoformat(text)
    if parsed.tzinfo is not None:
        return parsed.replace(tzinfo=None)
    return parsed


class TriageDesk:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def accept_batch(self, items: list[dict]) -> dict:
        if len(items) > BATCH_LIMIT:
            raise ValueError(f"batch max is {BATCH_LIMIT}")
        accepted: list[dict] = []
        for item in items:
            key = str(item.get("idempotency_key") or "")
            if not key:
                raise ValueError("idempotency_key is required")
            existing = await self.db.get(DeskIdempotency, key)
            if existing is not None:
                accepted.append({"idempotency_key": key, "ticket_id": existing.ticket_id, "duplicate": True})
                continue
            ticket_id = await self._apply_item(item, key)
            self.db.add(DeskIdempotency(key=key, item_type=str(item.get("type")), ticket_id=ticket_id))
            accepted.append({"idempotency_key": key, "ticket_id": ticket_id, "duplicate": False})
        await self.db.commit()
        return {"accepted": accepted}

    async def _apply_item(self, item: dict, key: str) -> str | None:
        kind = item.get("type")
        payload = item.get("payload") or {}
        if kind == "flag_count":
            source = str(payload.get("source") or "app")
            if source not in {"app", "idsp"}:
                source = "app"
            await self._upsert_count(payload, source=source)
            return None
        if kind not in {"referral", "assessment"}:
            raise ValueError(f"unknown item type {kind}")
        priority = str(payload.get("priority") or payload.get("flag") or "GREEN")
        if kind == "assessment" and priority == "GREEN":
            return None
        referral_id = str(payload.get("referral_id") or payload.get("id") or key)
        found = await self.db.execute(select(DeskTicket).where(DeskTicket.referral_id == referral_id))
        prior = found.scalar_one_or_none()
        if prior is not None:
            return prior.id
        created = _parse_time(payload.get("created_at"))
        ticket = DeskTicket(
            referral_id=referral_id,
            priority=priority,
            status="NEW",
            district_id=str(payload.get("district_id") or "PCMC"),
            ward_id=str(payload.get("ward_id") or "W3"),
            asha_id=str(payload.get("asha_id") or "ASHA-SUNITA"),
            created_at=created,
            sla_due_at=created + RED_SLA if priority == "RED" else None,
            payload_json=json.dumps(payload),
            idempotency_key=key,
        )
        self.db.add(ticket)
        await self.db.flush()
        return ticket.id

    async def _upsert_count(self, payload: dict, source: str) -> None:
        district = str(payload.get("district_id") or "PCMC")
        ward = str(payload["ward_id"])
        week = int(payload["week"])
        condition = str(payload["condition"])
        observed = _parse_time(payload.get("observed_at"))
        result = await self.db.execute(
            select(DiseaseCountRow).where(
                DiseaseCountRow.district_id == district,
                DiseaseCountRow.ward_id == ward,
                DiseaseCountRow.week_index == week,
                DiseaseCountRow.condition == condition,
                DiseaseCountRow.source == source,
            )
        )
        row = result.scalar_one_or_none()
        if row is None:
            self.db.add(
                DiseaseCountRow(
                    district_id=district,
                    ward_id=ward,
                    week_index=week,
                    condition=condition,
                    count=int(payload["count"]),
                    source=source,
                    observed_at=observed,
                )
            )
            return
        row.count = int(payload["count"])
        row.observed_at = observed

    async def list_tickets(self, status: str | None, priority: str | None) -> list[DeskTicket]:
        query = select(DeskTicket)
        if status:
            query = query.where(DeskTicket.status == status)
        if priority:
            query = query.where(DeskTicket.priority == priority)
        result = await self.db.execute(query)
        rows = list(result.scalars())
        order = {"RED": 0, "YELLOW": 1, "GREEN": 2}
        rows.sort(key=lambda row: (order.get(row.priority, 9), row.created_at))
        return rows

    async def get_ticket(self, ticket_id: str) -> DeskTicket | None:
        return await self.db.get(DeskTicket, ticket_id)

    async def acknowledge(self, ticket_id: str, now: datetime | None = None) -> DeskTicket:
        ticket = await self._require(ticket_id)
        if ticket.status == "NEW":
            ticket.status = "ACKNOWLEDGED"
            ticket.acknowledged_at = now or datetime.utcnow()
            await self.db.commit()
        return ticket

    async def start_consult(self, ticket_id: str) -> DeskTicket:
        ticket = await self._require(ticket_id)
        if ticket.status == "NEW":
            raise ValueError("acknowledge the ticket before consult")
        if ticket.status == "ACKNOWLEDGED":
            ticket.status = "IN_CARE"
            await self.db.commit()
        return ticket

    async def record_outcome(self, ticket_id: str, body: dict) -> DeskTicket:
        ticket = await self._require(ticket_id)
        if ticket.status in {"NEW"}:
            raise ValueError("acknowledge the ticket before an outcome")
        if ticket.status == "CLOSED":
            return ticket
        action = body.get("action")
        if action not in {"treated", "referred_up", "home"}:
            raise ValueError("action must be treated, referred_up, or home")
        diagnosis = str(body.get("diagnosis") or "").strip()
        if not diagnosis:
            raise ValueError("diagnosis is required")
        label = "home" if action == "home" else action
        fhir = {
            "resourceType": "Bundle",
            "type": "document",
            "entry": [
                {"resource": {"resourceType": "Condition", "code": {"text": diagnosis}}},
                {"resource": {"resourceType": "Encounter", "status": "finished"}},
            ],
        }
        self.db.add(
            DeskOutcome(
                ticket_id=ticket.id,
                diagnosis=diagnosis,
                action=action,
                note_for_asha=str(body.get("note_for_asha") or ""),
                outcome_label_for_ml=label,
                fhir_json=json.dumps(fhir),
            )
        )
        ticket.status = "CLOSED"
        await self.db.commit()
        return ticket

    async def escalate(self, now: datetime) -> list[dict]:
        result = await self.db.execute(select(DeskTicket).where(DeskTicket.priority == "RED", DeskTicket.status == "NEW"))
        notices = []
        for ticket in result.scalars():
            due = ticket.sla_due_at or (ticket.created_at + RED_SLA)
            if now <= due or ticket.escalated_level >= 1:
                continue
            ticket.escalated_level = 1
            notices.append(
                {
                    "to": "block-medical-officer",
                    "channel": "sms",
                    "body": f"ESC|{ticket.referral_id}|RED|{ticket.ward_id}|unacked>4h",
                }
            )
        await self.db.commit()
        return notices

    async def latest_pack(self, district_id: str) -> ContextPackBlob | None:
        result = await self.db.execute(
            select(ContextPackBlob)
            .where(ContextPackBlob.district_id == district_id)
            .order_by(ContextPackBlob.version.desc())
        )
        return result.scalars().first()

    async def heatmap(self, district_id: str, week: int) -> dict:
        result = await self.db.execute(
            select(DiseaseCountRow).where(
                DiseaseCountRow.district_id == district_id,
                DiseaseCountRow.week_index == week,
            )
        )
        points = [
            CountPoint(
                ward_id=row.ward_id,
                week=row.week_index,
                condition=row.condition,
                count=row.count,
                source=row.source,
                observed_at=row.observed_at,
            )
            for row in result.scalars()
        ]
        merged = merge_counts(points)
        by_ward: dict[str, int] = {}
        for point in merged:
            by_ward[point.ward_id] = by_ward.get(point.ward_id, 0) + point.count
        wards = [
            {
                "ward_id": ward_id,
                "flags": count,
                "per_thousand": round(count / POPULATION * 1000, 2),
            }
            for ward_id, count in sorted(by_ward.items())
        ]
        return {"district_id": district_id, "week": week, "wards": wards}

    async def asha_stats(self, asha_id: str) -> dict:
        result = await self.db.execute(select(DeskTicket).where(DeskTicket.asha_id == asha_id))
        rows = list(result.scalars())
        closed = [row for row in rows if row.status == "CLOSED"]
        return {
            "asha_id": asha_id,
            "cases": len(rows),
            "red": sum(1 for row in rows if row.priority == "RED"),
            "yellow": sum(1 for row in rows if row.priority == "YELLOW"),
            "completion_pct": 0 if not rows else round(len(closed) / len(rows) * 100),
        }

    async def publish_next_pack(self, district_id: str) -> ContextPackBlob:
        current = await self.latest_pack(district_id)
        version = 1 if current is None else current.version + 1
        result = await self.db.execute(select(DiseaseCountRow).where(DiseaseCountRow.district_id == district_id))
        points = [
            CountPoint(row.ward_id, row.week_index, row.condition, row.count, row.source, row.observed_at)
            for row in result.scalars()
        ]
        merged = merge_counts(points)
        dengue = [point for point in merged if point.condition == "dengue_like"]
        latest_week = max((point.week for point in dengue), default=0)
        hot = [point for point in dengue if point.week == latest_week and point.count >= 3]
        active = hot[0].ward_id if hot else None
        body = {
            "manifest": {
                "district_id": district_id,
                "pack_version": version,
                "languages": ["mr", "hi", "en"],
            },
            "active_dengue_ward": active,
            "disease_counts": [
                {"ward_id": point.ward_id, "week": point.week, "condition": point.condition, "count": point.count}
                for point in merged
            ],
        }
        pack = ContextPackBlob(
            district_id=district_id,
            version=version,
            etag=pack_etag(version),
            body_json=json.dumps(body),
        )
        self.db.add(pack)
        await self.db.commit()
        return pack

    async def _require(self, ticket_id: str) -> DeskTicket:
        ticket = await self.get_ticket(ticket_id)
        if ticket is None:
            raise KeyError(ticket_id)
        return ticket
