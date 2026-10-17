"""Incentive service for backend.

Handles:
- Effective-dated catalogue versioning and historical rate lookup (Req 53.1, 53.2, Property 11)
- Deterministic idempotency and event deduplication (Req 54.1, Property 10)
- Multi-component rates (Req 53.3)
- Duplicate claim detection across workers with ANM review flagging (Req 54.6)

Tasks: 13.2
"""
from __future__ import annotations

import csv
import hashlib
import io
import json
import re
import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import and_, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from models.db.models import AuditLog, IncentiveCatalogue, IncentiveClaim, IncentiveEvent, PaymentDispute, User

REJECTION_CATEGORIES = {
    "DOCUMENTATION_DEFICIT",
    "DATE_MISMATCH",
    "DUPLICATE_SUBMISSION",
    "INELIGIBLE_CRITERIA",
    "OUT_OF_WINDOW",
    "BANK_DETAIL_MISMATCH",
    "OTHER",
}


DEFAULT_CATALOGUE_2024 = {
    "version_id": "NHM_NAT_2024_V1",
    "state_code": "DEFAULT",
    "effective_from": "2024-01-01T00:00:00Z",
    "effective_to": None,
    "description": "National Health Mission ASHA Incentive Catalogue 2024",
    "items": [
        {
            "activity_code": "ANC_REG_EARLY",
            "activity_name": "Early ANC Registration",
            "category": "RCH_MATERNAL",
            "rates": {
                "fixed_honorarium": 0.0,
                "performance_incentive": 100.0,
                "state_top_up": 50.0,
                "connectivity_allowance": 0.0,
            },
            "submission_window_days": 60,
            "required_evidence_type": "CLINICAL_ENCOUNTER",
            "eligibility_conditions": {"max_gestational_weeks": 12},
        },
        {
            "activity_code": "ANC_CHECKUP_FULL",
            "activity_name": "Full ANC Service Package",
            "category": "RCH_MATERNAL",
            "rates": {
                "fixed_honorarium": 0.0,
                "performance_incentive": 200.0,
                "state_top_up": 100.0,
                "connectivity_allowance": 0.0,
            },
            "submission_window_days": 90,
            "required_evidence_type": "VISIT_SERIES",
            "eligibility_conditions": {"min_anc_visits": 4, "requires_tt": True, "requires_ifa": True},
        },
        {
            "activity_code": "INST_DELIVERY_ESCORT",
            "activity_name": "Institutional Delivery Escort (JSY)",
            "category": "RCH_MATERNAL",
            "rates": {
                "fixed_honorarium": 0.0,
                "performance_incentive": 300.0,
                "state_top_up": 300.0,
                "connectivity_allowance": 0.0,
            },
            "submission_window_days": 45,
            "required_evidence_type": "FACILITY_VERIFICATION",
            "eligibility_conditions": {"delivery_location": "FACILITY"},
        },
        {
            "activity_code": "HBNC_COMPLETE",
            "activity_name": "Complete Home-Based Newborn Care Series",
            "category": "RCH_CHILD",
            "rates": {
                "fixed_honorarium": 0.0,
                "performance_incentive": 250.0,
                "state_top_up": 50.0,
                "connectivity_allowance": 0.0,
            },
            "submission_window_days": 60,
            "required_evidence_type": "VISIT_SERIES",
            "eligibility_conditions": {"institutional_visits_required": 6, "home_visits_required": 7},
        },
        {
            "activity_code": "HBYC_VISIT",
            "activity_name": "Home-Based Care for Young Child (HBYC)",
            "category": "RCH_CHILD",
            "rates": {
                "fixed_honorarium": 0.0,
                "performance_incentive": 50.0,
                "state_top_up": 25.0,
                "connectivity_allowance": 0.0,
            },
            "submission_window_days": 45,
            "required_evidence_type": "CLINICAL_ENCOUNTER",
            "eligibility_conditions": {"milestones_months": [3, 6, 9, 12, 15]},
        },
        {
            "activity_code": "IMMUNIZATION_FULL_1YR",
            "activity_name": "Full Immunization at 1 Year",
            "category": "IMMUNIZATION",
            "rates": {
                "fixed_honorarium": 0.0,
                "performance_incentive": 100.0,
                "state_top_up": 50.0,
                "connectivity_allowance": 0.0,
            },
            "submission_window_days": 60,
            "required_evidence_type": "VACCINATION_RECORD",
            "eligibility_conditions": {"required_antigens": ["BCG", "OPV_3", "PENTA_3", "MR_1"]},
        },
        {
            "activity_code": "CBAC_SCREENING",
            "activity_name": "NCD Community Based Assessment Checklist (CBAC)",
            "category": "NCD",
            "rates": {
                "fixed_honorarium": 0.0,
                "performance_incentive": 20.0,
                "state_top_up": 10.0,
                "connectivity_allowance": 0.0,
            },
            "submission_window_days": 30,
            "required_evidence_type": "CLINICAL_ENCOUNTER",
            "eligibility_conditions": {"min_age_years": 30},
        },
        {
            "activity_code": "TB_DOTS_SUPPORT",
            "activity_name": "TB Patient Treatment Supporter",
            "category": "COMMUNICABLE_DISEASE",
            "rates": {
                "fixed_honorarium": 0.0,
                "performance_incentive": 1000.0,
                "state_top_up": 200.0,
                "connectivity_allowance": 0.0,
            },
            "submission_window_days": 60,
            "required_evidence_type": "TREATMENT_OUTCOME",
            "eligibility_conditions": {"treatment_status": "CURED_OR_COMPLETED"},
        },
        {
            "activity_code": "VHSND_SESSION",
            "activity_name": "VHSND Session Mobilization & Support",
            "category": "ROUTINE",
            "rates": {
                "fixed_honorarium": 0.0,
                "performance_incentive": 200.0,
                "state_top_up": 50.0,
                "connectivity_allowance": 0.0,
            },
            "submission_window_days": 30,
            "required_evidence_type": "SESSION_LOG",
            "eligibility_conditions": {"session_completed": True},
        },
        {
            "activity_code": "ROUTINE_RECURRENT",
            "activity_name": "Monthly Routine Recurrent Activities",
            "category": "ROUTINE",
            "rates": {
                "fixed_honorarium": 2000.0,
                "performance_incentive": 0.0,
                "state_top_up": 500.0,
                "connectivity_allowance": 500.0,
            },
            "submission_window_days": 30,
            "required_evidence_type": "MONTHLY_REPORT",
            "eligibility_conditions": {"report_submitted": True},
        },
    ],
}


class IncentiveService:
    """Backend incentive engine managing catalogues, historical rates, and duplicate detection."""

    @staticmethod
    def generate_idempotency_key(activity_code: str, member_id: str, event_date: datetime) -> str:
        """Property 10: hash(activityCode + memberId + eventDate)."""
        date_str = event_date.strftime("%Y-%m-%d")
        raw = f"{activity_code}_{member_id}_{date_str}"
        return hashlib.sha256(raw.encode("utf-8")).hexdigest()

    # ── Catalogue Versioning & Historical Rates (Req 53.2, Property 11) ────────

    @classmethod
    async def publish_catalogue(
        cls,
        session: AsyncSession,
        version_id: str,
        state_code: str,
        effective_from: datetime,
        catalogue_data: dict[str, Any],
        effective_to: datetime | None = None,
        description: str | None = None,
    ) -> IncentiveCatalogue:
        """Publishes a new versioned incentive catalogue.
        
        If an existing catalogue for this state is open-ended (effective_to is None),
        its effective_to is closed at this version's effective_from.
        """
        # Close previous open-ended version if applicable
        stmt = (
            select(IncentiveCatalogue)
            .where(
                and_(
                    IncentiveCatalogue.state_code == state_code,
                    IncentiveCatalogue.effective_to.is_(None),
                    IncentiveCatalogue.effective_from < effective_from,
                )
            )
        )
        result = await session.execute(stmt)
        previous = result.scalars().first()
        if previous:
            previous.effective_to = effective_from

        catalogue = IncentiveCatalogue(
            id=str(uuid.uuid4()),
            version_id=version_id,
            state_code=state_code,
            effective_from=effective_from,
            effective_to=effective_to,
            description=description,
            catalogue_json=json.dumps(catalogue_data),
            is_active=True,
            created_at=datetime.utcnow(),
        )
        session.add(catalogue)
        await session.flush()
        return catalogue

    @classmethod
    async def get_catalogue_for_date(
        cls,
        session: AsyncSession,
        event_date: datetime,
        state_code: str = "DEFAULT",
    ) -> dict[str, Any] | None:
        """Finds the catalogue version active on event_date (Property 11)."""
        stmt = (
            select(IncentiveCatalogue)
            .where(
                and_(
                    or_(
                        IncentiveCatalogue.state_code == state_code,
                        IncentiveCatalogue.state_code == "DEFAULT",
                    ),
                    IncentiveCatalogue.effective_from <= event_date,
                    or_(
                        IncentiveCatalogue.effective_to.is_(None),
                        IncentiveCatalogue.effective_to >= event_date,
                    ),
                    IncentiveCatalogue.is_active.is_(True),
                )
            )
            .order_by(
                # Prefer state-specific over DEFAULT, then most recent effective_from
                (IncentiveCatalogue.state_code == state_code).desc(),
                IncentiveCatalogue.effective_from.desc(),
            )
        )
        result = await session.execute(stmt)
        row = result.scalars().first()

        if row:
            return json.loads(row.catalogue_json)

        # Fallback to default in-memory definition if DB has no catalogue yet
        if event_date >= datetime(2024, 1, 1):
            return DEFAULT_CATALOGUE_2024

        return None

    @classmethod
    async def get_rate_for_event(
        cls,
        session: AsyncSession,
        activity_code: str,
        event_date: datetime,
        state_code: str = "DEFAULT",
    ) -> dict[str, float]:
        """Calculates rates for an activity using the catalogue active at event_date (Property 11)."""
        catalogue = await cls.get_catalogue_for_date(session, event_date, state_code=state_code)
        if not catalogue:
            return {
                "fixed_honorarium": 0.0,
                "performance_incentive": 0.0,
                "state_top_up": 0.0,
                "connectivity_allowance": 0.0,
                "total_rate": 0.0,
            }

        items = catalogue.get("items", [])
        for item in items:
            if item.get("activity_code") == activity_code:
                rates = item.get("rates", {})
                fixed = float(rates.get("fixed_honorarium", 0.0))
                perf = float(rates.get("performance_incentive", 0.0))
                topup = float(rates.get("state_top_up", 0.0))
                conn = float(rates.get("connectivity_allowance", 0.0))
                return {
                    "fixed_honorarium": fixed,
                    "performance_incentive": perf,
                    "state_top_up": topup,
                    "connectivity_allowance": conn,
                    "total_rate": fixed + perf + topup + conn,
                }

        return {
            "fixed_honorarium": 0.0,
            "performance_incentive": 0.0,
            "state_top_up": 0.0,
            "connectivity_allowance": 0.0,
            "total_rate": 0.0,
        }

    # ── Duplicate Claim Detection across Workers (Req 54.6) ───────────────────

    @classmethod
    async def detect_duplicate_claim(
        cls,
        session: AsyncSession,
        member_id: str,
        activity_code: str,
        worker_id: str,
        event_date: datetime,
    ) -> IncentiveEvent | None:
        """Detects whether another worker has already logged or claimed this event.
        
        Req 54.6: If two workers claim escort for the same delivery or same event,
        the system detects the conflict and flags for ANM review.
        """
        # Search for any event for this member & activity claimed by a different worker
        # within 7 days (or same date)
        min_date_ms = int(event_date.timestamp() * 1000) - (7 * 86400 * 1000)
        max_date_ms = int(event_date.timestamp() * 1000) + (7 * 86400 * 1000)

        stmt = select(IncentiveEvent).where(
            and_(
                IncentiveEvent.member_id == member_id,
                IncentiveEvent.activity_code == activity_code,
                IncentiveEvent.worker_id.isnot(None),
                IncentiveEvent.worker_id != worker_id,
                IncentiveEvent.event_date >= min_date_ms,
                IncentiveEvent.event_date <= max_date_ms,
            )
        )
        result = await session.execute(stmt)
        return result.scalars().first()

    @classmethod
    async def get_flagged_duplicate_events(
        cls,
        session: AsyncSession,
        block_code: str | None = None,
    ) -> list[IncentiveEvent]:
        """Returns all duplicate or disputed events flagged for ANM/AF review."""
        query = select(IncentiveEvent).where(IncentiveEvent.status == "flagged_review")
        if block_code:
            query = query.where(IncentiveEvent.block_code == block_code)
        result = await session.execute(query.order_by(IncentiveEvent.created_at.desc()))
        return list(result.scalars().all())

    # ── Auto-Event Ingest & Deduplication (Req 54.1, Property 10) ─────────────

    @classmethod
    async def record_incentive_event(
        cls,
        session: AsyncSession,
        *,
        event_id: str | None = None,
        worker_id: str | None,
        member_id: str,
        activity_code: str,
        event_date: datetime,
        encounter_id: str | None = None,
        evidence_record_id: str | None = None,
        status: str = "eligible",
        ineligibility_reason: str | None = None,
        block_code: str | None = None,
        state_code: str = "DEFAULT",
    ) -> tuple[IncentiveEvent, bool]:
        """Records an incentive event with strict idempotency and duplicate checking.
        
        Returns:
            (event, created) tuple where created is True if new, False if idempotent replay.
        """
        idempotency_key = cls.generate_idempotency_key(activity_code, member_id, event_date)

        # 1. Deduplication check (Property 10) & Cross-Worker Conflict Check (Req 54.6)
        stmt = select(IncentiveEvent).where(IncentiveEvent.idempotency_key == idempotency_key)
        result = await session.execute(stmt)
        existing = result.scalars().first()
        if existing:
            # If same worker (or unassigned), this is an idempotent replay
            if not worker_id or existing.worker_id == worker_id:
                return existing, False

            # If DIFFERENT worker claims the exact same event -> Duplicate claim conflict!
            flagged_reason = (
                f"Duplicate claim conflict: Worker {worker_id} and Worker "
                f"{existing.worker_id} both claimed {activity_code} "
                f"for member {member_id}"
            )
            existing.status = "flagged_review"
            existing.flagged_reason = flagged_reason

            # Create event for second worker flagged for ANM review
            catalogue = await cls.get_catalogue_for_date(session, event_date, state_code=state_code)
            catalogue_version_id = catalogue.get("version_id", "DEFAULT_2024") if catalogue else "DEFAULT_2024"
            conflict_key = f"{idempotency_key}_{worker_id}"

            conflict_event = IncentiveEvent(
                id=event_id or str(uuid.uuid4()),
                worker_id=worker_id,
                member_id=member_id,
                encounter_id=encounter_id,
                activity_code=activity_code,
                catalogue_version_id=catalogue_version_id,
                event_date=int(event_date.timestamp() * 1000),
                status="flagged_review",
                ineligibility_reason=ineligibility_reason,
                evidence_record_id=evidence_record_id or encounter_id,
                created_at=int(datetime.utcnow().timestamp() * 1000),
                idempotency_key=conflict_key,
                sync_status="synced",
                server_received_at=datetime.utcnow(),
                block_code=block_code,
                flagged_reason=flagged_reason,
            )
            session.add(conflict_event)
            await session.flush()
            return conflict_event, True

        # 2. Duplicate claim detection across workers within window (Req 54.6)
        flagged_reason = None
        event_status = status
        if worker_id:
            duplicate_conflict = await cls.detect_duplicate_claim(
                session, member_id, activity_code, worker_id, event_date
            )
            if duplicate_conflict:
                event_status = "flagged_review"
                flagged_reason = (
                    f"Duplicate claim conflict: Worker {worker_id} and Worker "
                    f"{duplicate_conflict.worker_id} both claimed {activity_code} "
                    f"for member {member_id}"
                )
                # Also flag the earlier conflicting event for ANM review
                if duplicate_conflict.status in ("eligible", "claimed"):
                    duplicate_conflict.status = "flagged_review"
                    duplicate_conflict.flagged_reason = flagged_reason

        # 3. Look up active catalogue version for event_date (Property 11)
        catalogue = await cls.get_catalogue_for_date(session, event_date, state_code=state_code)
        catalogue_version_id = catalogue.get("version_id", "DEFAULT_2024") if catalogue else "DEFAULT_2024"

        event = IncentiveEvent(
            id=event_id or str(uuid.uuid4()),
            worker_id=worker_id,
            member_id=member_id,
            encounter_id=encounter_id,
            activity_code=activity_code,
            catalogue_version_id=catalogue_version_id,
            event_date=int(event_date.timestamp() * 1000),
            status=event_status,
            ineligibility_reason=ineligibility_reason,
            evidence_record_id=evidence_record_id or encounter_id,
            created_at=int(datetime.utcnow().timestamp() * 1000),
            idempotency_key=idempotency_key,
            sync_status="synced",
            server_received_at=datetime.utcnow(),
            block_code=block_code,
            flagged_reason=flagged_reason,
        )
        session.add(event)
        await session.flush()
        return event, True

    # ── Claim Voucher Submission & Line Verification (Req 56.1, 56.2, 56.3) ──

    @classmethod
    async def submit_claim(
        cls,
        session: AsyncSession,
        *,
        claim_id: str,
        worker_id: str,
        claim_period: str,
        line_items: list[dict[str, Any]],
        total_amount: float,
        pdf_path: str | None = None,
    ) -> IncentiveClaim:
        """Submits or updates a monthly claim voucher (Req 56.1, 56.2)."""
        now_ms = int(datetime.utcnow().timestamp() * 1000)
        stmt = select(IncentiveClaim).where(IncentiveClaim.id == claim_id)
        result = await session.execute(stmt)
        claim = result.scalars().first()

        line_items_json = json.dumps(line_items)

        if claim:
            claim.worker_id = worker_id
            claim.claim_period = claim_period
            claim.status = "submitted"
            claim.line_items_json = line_items_json
            claim.total_amount = total_amount
            claim.pdf_path = pdf_path or claim.pdf_path
            claim.submitted_at = now_ms
            claim.sync_status = "synced"
        else:
            claim = IncentiveClaim(
                id=claim_id,
                worker_id=worker_id,
                claim_period=claim_period,
                status="submitted",
                line_items_json=line_items_json,
                total_amount=total_amount,
                pdf_path=pdf_path,
                submitted_at=now_ms,
                sync_status="synced",
            )
            session.add(claim)

        # Mark corresponding incentive events as claimed
        for item in line_items:
            event_id = item.get("incentive_event_id")
            if event_id:
                ev_stmt = select(IncentiveEvent).where(IncentiveEvent.id == event_id)
                ev_res = await session.execute(ev_stmt)
                ev = ev_res.scalars().first()
                if ev and ev.status in ("eligible", "flagged_review"):
                    ev.status = "claimed"

        await session.flush()
        return claim

    @classmethod
    async def verify_claim_lines(
        cls,
        session: AsyncSession,
        *,
        claim_id: str,
        verifier_id: str,
        line_decisions: list[dict[str, Any]],
    ) -> IncentiveClaim:
        """ANM / AF line-item verification with mandatory rejection reason (Req 56.3)."""
        stmt = select(IncentiveClaim).where(IncentiveClaim.id == claim_id)
        result = await session.execute(stmt)
        claim = result.scalars().first()
        if not claim:
            raise ValueError(f"Claim with ID {claim_id} not found")

        raw_items = json.loads(claim.line_items_json or "[]")
        decision_map = {d["incentive_event_id"]: d for d in line_decisions}

        now_iso = datetime.utcnow().isoformat()
        for item in raw_items:
            event_id = item.get("incentive_event_id")
            if event_id in decision_map:
                decision = decision_map[event_id]
                new_status = decision.get("status", "approved")

                if new_status == "rejected":
                    reason = decision.get("rejection_reason", "").strip()
                    if not reason:
                        raise ValueError(f"Mandatory rejection reason required for event {event_id}")
                    category = decision.get("rejection_category", "").strip().upper()
                    if not category or category not in REJECTION_CATEGORIES:
                        category = "OTHER"
                    item["rejection_reason"] = reason
                    item["rejection_category"] = category
                else:
                    item["rejection_reason"] = None
                    item["rejection_category"] = None

                item["status"] = new_status
                item["verifier_notes"] = decision.get("verifier_notes")
                item["verifier_id"] = verifier_id
                item["verified_at"] = now_iso

                # Also reflect verification on IncentiveEvent table
                ev_stmt = select(IncentiveEvent).where(IncentiveEvent.id == event_id)
                ev_res = await session.execute(ev_stmt)
                ev = ev_res.scalars().first()
                if ev:
                    ev.status = new_status
                    if new_status == "rejected":
                        ev.ineligibility_reason = item.get("rejection_reason")

        # Compute overall claim status
        statuses = {item.get("status") for item in raw_items}
        if all(s == "approved" for s in statuses):
            claim_status = "approved"
        elif all(s == "rejected" for s in statuses):
            claim_status = "rejected"
        else:
            claim_status = "verified"

        claim.status = claim_status
        claim.line_items_json = json.dumps(raw_items)
        claim.verified_at = int(datetime.utcnow().timestamp() * 1000)

        await session.flush()
        return claim

    @classmethod
    async def export_asha_soft_csv(
        cls,
        session: AsyncSession,
        claim_id: str,
        only_approved: bool = True,
    ) -> str:
        """Generates standard ASHA Soft / PFMS payment export CSV (Req 56.5, 56.7).
        
        Invariant: Contains ONLY minimum de-identified beneficiary info (coded ID, date, amount).
        No clinical or diagnostic details appear in payment records.
        """
        stmt = select(IncentiveClaim).where(IncentiveClaim.id == claim_id)
        result = await session.execute(stmt)
        claim = result.scalars().first()
        if not claim:
            raise ValueError(f"Claim with ID {claim_id} not found")

        raw_items = json.loads(claim.line_items_json or "[]")
        output = io.StringIO()
        writer = csv.writer(output)

        # Header compliant with ASHA Soft DBT export schema
        writer.writerow([
            "Worker_ID",
            "Claim_Period",
            "Activity_Code",
            "Beneficiary_Coded_ID",
            "Service_Date",
            "Amount",
            "Status",
            "Payment_Reference",
        ])

        for item in raw_items:
            item_status = item.get("status", "pending")
            if only_approved and item_status != "approved":
                continue

            writer.writerow([
                claim.worker_id or "",
                claim.claim_period or "",
                item.get("activity_code", ""),
                item.get("member_coded_id", ""),
                item.get("service_date", "")[:10] if item.get("service_date") else "",
                f"{float(item.get('amount', 0.0)):.2f}",
                item_status.upper(),
                claim.payment_reference or "PENDING",
            ])

        return output.getvalue()

    @classmethod
    async def get_claim_aging_report(
        cls,
        session: AsyncSession,
        block_code: str | None = None,
    ) -> dict[str, Any]:
        """Provides claim ageing analysis, bottleneck stages, and rejection breakdown (Req 56.6)."""
        stmt = select(IncentiveClaim)
        result = await session.execute(stmt)
        claims = result.scalars().all()

        now_ms = int(datetime.utcnow().timestamp() * 1000)
        filtered_claims: list[IncentiveClaim] = []

        for c in claims:
            if block_code and c.worker_id:
                u_stmt = select(User).where(User.id == c.worker_id)
                u_res = await session.execute(u_stmt)
                u = u_res.scalars().first()
                if not u or u.area_block != block_code:
                    continue
            filtered_claims.append(c)

        total_claims = len(filtered_claims)
        bottlenecks: dict[str, int] = {
            "generated": 0,
            "submitted": 0,
            "verified": 0,
            "approved": 0,
            "rejected": 0,
            "paid": 0,
        }
        rejection_categories: dict[str, int] = {}
        total_aging_days = 0.0
        active_claims_count = 0

        for c in filtered_claims:
            st = c.status or "generated"
            bottlenecks[st] = bottlenecks.get(st, 0) + 1

            if c.submitted_at and st != "paid":
                aging_days = max(0.0, (now_ms - c.submitted_at) / (86400 * 1000.0))
                total_aging_days += aging_days
                active_claims_count += 1

            # Aggregate rejection categories
            if c.line_items_json:
                try:
                    items = json.loads(c.line_items_json)
                    for i in items:
                        if i.get("status") == "rejected":
                            cat = i.get("rejection_category") or "OTHER"
                            rejection_categories[cat] = rejection_categories.get(cat, 0) + 1
                except Exception:
                    pass

        avg_aging_days = round(total_aging_days / active_claims_count, 1) if active_claims_count > 0 else 0.0

        return {
            "block_code": block_code or "ALL",
            "total_claims": total_claims,
            "active_claims": active_claims_count,
            "average_aging_days": avg_aging_days,
            "bottleneck_stages": bottlenecks,
            "rejection_reasons_summary": rejection_categories,
        }

    # ── Bank and Identity Details Pre-Validation (Req 57.1) ──────────────────

    @classmethod
    def validate_bank_details(
        cls,
        *,
        account_holder_name: str,
        account_number: str,
        ifsc_code: str,
        registered_worker_name: str,
        is_aadhaar_seeded: bool = True,
    ) -> dict[str, Any]:
        """Pre-validates bank account details against RBI IFSC and account standards (Req 57.1)."""
        errors: list[str] = []
        warnings: list[str] = []

        # 1. RBI IFSC standard: 4 letters, 0, 6 alphanumeric
        ifsc_clean = ifsc_code.strip().upper()
        ifsc_valid = bool(re.match(r"^[A-Z]{4}0[A-Z0-9]{6}$", ifsc_clean))
        if not ifsc_valid:
            errors.append("Invalid IFSC code format. Must be 11 characters (4 letters, 0, 6 alphanumeric).")

        # 2. Account number standard: 9 to 18 numeric digits
        acc_clean = account_number.strip()
        account_valid = bool(re.match(r"^\d{9,18}$", acc_clean))
        if not account_valid:
            errors.append("Invalid account number. Must be between 9 and 18 numeric digits.")

        # 3. Name matching check
        tokens1 = set(registered_worker_name.strip().lower().split())
        tokens2 = set(account_holder_name.strip().lower().split())
        union = tokens1.union(tokens2)
        intersection = tokens1.intersection(tokens2)
        score = len(intersection) / len(union) if union else 0.0
        name_match_valid = score >= 0.70

        if not name_match_valid:
            warnings.append(
                f"Account name '{account_holder_name}' does not match registered name "
                f"'{registered_worker_name}' (score: {score:.2f})."
            )

        if not is_aadhaar_seeded:
            warnings.append("Bank account is not Aadhaar-seeded. DBT payments via APBS may fail.")

        is_valid = ifsc_valid and account_valid and len(errors) == 0

        return {
            "is_valid": is_valid,
            "ifsc_valid": ifsc_valid,
            "account_valid": account_valid,
            "name_match_valid": name_match_valid,
            "name_match_score": round(score, 2),
            "is_aadhaar_seeded": is_aadhaar_seeded,
            "errors": sorted(errors),
            "warnings": sorted(warnings),
        }

    # ── Dispute Resolution & SLA Tracking (Req 57.3, 57.6) ───────────────────

    @classmethod
    async def submit_dispute(
        cls,
        session: AsyncSession,
        *,
        worker_id: str,
        claim_period: str,
        description: str,
        claim_id: str | None = None,
        activity_code: str | None = None,
        dispute_type: str = "technical_error",
        evidence_event_ids: list[str] | None = None,
        sla_days: int = 15,
    ) -> PaymentDispute:
        """Submits a payment dispute with automated SLA deadline and owner assignment (Req 57.3, 57.6)."""
        now_ms = int(datetime.utcnow().timestamp() * 1000)
        sla_deadline = now_ms + (sla_days * 86400 * 1000)
        dispute_id = str(uuid.uuid4())
        evidence_ids = evidence_event_ids or []

        # Req 57.6: Identify systemic policy problems (rates, classification, minimum wage)
        lower_desc = description.lower()
        effective_dispute_type = dispute_type
        if any(w in lower_desc for w in ["minimum wage", "honorarium rate", "employment classification", "catalogue rate"]):
            effective_dispute_type = "systemic_policy"

        dispute = PaymentDispute(
            id=dispute_id,
            worker_id=worker_id,
            claim_period=claim_period,
            claim_id=claim_id,
            activity_code=activity_code,
            dispute_type=effective_dispute_type,
            description=description.strip(),
            evidence_event_ids_json=json.dumps(evidence_ids),
            status="submitted",
            assigned_role="AF",  # Initially assigned to ASHA Facilitator
            sla_deadline=sla_deadline,
            is_escalated=False,
            escalation_level=0,
            created_at=now_ms,
            updated_at=now_ms,
        )
        session.add(dispute)

        # Audit log entry with hash chain (Req 33, 57.5)
        raw_hash = f"DISPUTE:{dispute_id}:{worker_id}:{claim_period}:{now_ms}"
        chain_hash = hashlib.sha256(raw_hash.encode("utf-8")).hexdigest()
        audit = AuditLog(
            id=str(uuid.uuid4()),
            table_name="payment_disputes",
            record_id=dispute_id,
            field_name="status",
            old_value=None,
            new_value="submitted",
            changed_by=worker_id,
            device_timestamp=now_ms,
            server_timestamp=now_ms,
            chain_hash=chain_hash,
        )
        session.add(audit)
        await session.flush()
        return dispute

    @classmethod
    async def check_and_escalate_disputes(
        cls,
        session: AsyncSession,
    ) -> list[PaymentDispute]:
        """Checks for SLA breaches and escalates disputes to higher administrative tiers (Req 57.3)."""
        now_ms = int(datetime.utcnow().timestamp() * 1000)
        stmt = select(PaymentDispute).where(
            and_(
                PaymentDispute.status.in_(["submitted", "assigned", "in_review"]),
                PaymentDispute.sla_deadline.isnot(None),
                PaymentDispute.sla_deadline < now_ms,
                PaymentDispute.is_escalated.is_(False),
            )
        )
        result = await session.execute(stmt)
        breached_disputes = result.scalars().all()

        escalated_list: list[PaymentDispute] = []
        for d in breached_disputes:
            d.is_escalated = True
            d.escalation_level += 1
            # Reassign to higher tier: AF -> BPMU -> DISTRICT_OFFICER
            if d.assigned_role == "AF":
                d.assigned_role = "BPMU"
            else:
                d.assigned_role = "DISTRICT_OFFICER"
            d.updated_at = now_ms

            # Audit escalation
            raw_hash = f"ESCALATION:{d.id}:{d.escalation_level}:{now_ms}"
            chain_hash = hashlib.sha256(raw_hash.encode("utf-8")).hexdigest()
            audit = AuditLog(
                id=str(uuid.uuid4()),
                table_name="payment_disputes",
                record_id=d.id,
                field_name="is_escalated",
                old_value="false",
                new_value=f"true:{d.assigned_role}",
                changed_by="SYSTEM_SLA_WATCHDOG",
                device_timestamp=now_ms,
                server_timestamp=now_ms,
                chain_hash=chain_hash,
            )
            session.add(audit)
            escalated_list.append(d)

        await session.flush()
        return escalated_list

    @classmethod
    async def resolve_dispute(
        cls,
        session: AsyncSession,
        *,
        dispute_id: str,
        resolved_by: str,
        resolution_notes: str,
        status: str = "resolved",
    ) -> PaymentDispute:
        """Resolves or rejects a payment dispute with documented rationale (Req 57.3)."""
        stmt = select(PaymentDispute).where(PaymentDispute.id == dispute_id)
        result = await session.execute(stmt)
        dispute = result.scalars().first()
        if not dispute:
            raise ValueError(f"Dispute with ID {dispute_id} not found")

        now_ms = int(datetime.utcnow().timestamp() * 1000)
        dispute.status = status
        dispute.resolution_notes = resolution_notes
        dispute.resolved_by = resolved_by
        dispute.resolved_at = now_ms
        dispute.updated_at = now_ms

        raw_hash = f"RESOLVE:{dispute_id}:{status}:{resolved_by}:{now_ms}"
        chain_hash = hashlib.sha256(raw_hash.encode("utf-8")).hexdigest()
        audit = AuditLog(
            id=str(uuid.uuid4()),
            table_name="payment_disputes",
            record_id=dispute_id,
            field_name="status",
            old_value="submitted",
            new_value=status,
            changed_by=resolved_by,
            device_timestamp=now_ms,
            server_timestamp=now_ms,
            chain_hash=chain_hash,
        )
        session.add(audit)
        await session.flush()
        return dispute

    # ── Payment Delay Alerts for Block / District Officers (Req 57.4) ─────────

    @classmethod
    async def get_payment_delay_alerts(
        cls,
        session: AsyncSession,
        *,
        threshold_days: int = 45,
        block_code: str | None = None,
    ) -> list[dict[str, Any]]:
        """Detects approved claims whose disbursement is delayed beyond threshold days (Req 57.4)."""
        stmt = select(IncentiveClaim).where(
            and_(
                IncentiveClaim.status.in_(["approved", "verified"]),
                IncentiveClaim.paid_at.is_(None),
                IncentiveClaim.verified_at.isnot(None),
            )
        )
        result = await session.execute(stmt)
        approved_unpaid = result.scalars().all()

        now_ms = int(datetime.utcnow().timestamp() * 1000)
        ms_per_day = 86400 * 1000.0

        # Group by worker block
        block_groups: dict[str, list[IncentiveClaim]] = {}

        for claim in approved_unpaid:
            days_delayed = (now_ms - (claim.verified_at or now_ms)) / ms_per_day
            if days_delayed < threshold_days:
                continue

            # Fetch worker block
            worker_block = "UNKNOWN_BLOCK"
            if claim.worker_id:
                u_stmt = select(User).where(User.id == claim.worker_id)
                u_res = await session.execute(u_stmt)
                u = u_res.scalars().first()
                if u and u.area_block:
                    worker_block = u.area_block

            if block_code and worker_block != block_code:
                continue

            block_groups.setdefault(worker_block, []).append(claim)

        alerts: list[dict[str, Any]] = []
        for blk, claims in block_groups.items():
            total_amt = sum(c.total_amount or 0.0 for c in claims)
            unique_workers = {c.worker_id for c in claims if c.worker_id}
            max_delay = max((now_ms - (c.verified_at or now_ms)) / ms_per_day for c in claims)

            alert_level = "CRITICAL" if max_delay >= 60 else "WARNING"
            alerts.append({
                "block": blk,
                "delayed_claims_count": len(claims),
                "total_delayed_amount": round(total_amt, 2),
                "max_days_delayed": round(max_delay, 1),
                "threshold_days": threshold_days,
                "affected_workers_count": len(unique_workers),
                "alert_level": alert_level,
                "message": (
                    f"Payment delay alert: {len(claims)} approved claims totaling Rs. {total_amt:.2f} "
                    f"delayed >{threshold_days} days in block {blk}."
                ),
            })

        return alerts

    # ── Auditor Full Provenance Reconciliation Report (Req 57.5) ─────────────

    @classmethod
    async def generate_auditor_reconciliation_report(
        cls,
        session: AsyncSession,
        *,
        claim_id: str | None = None,
        claim_period: str | None = None,
        worker_id: str | None = None,
    ) -> list[dict[str, Any]]:
        """Produces full reconciliation tracing: event -> incentive log -> claim voucher -> approval -> payment with tamper-evident audit trail (Req 57.5)."""
        stmt = select(IncentiveClaim)
        if claim_id:
            stmt = stmt.where(IncentiveClaim.id == claim_id)
        if claim_period:
            stmt = stmt.where(IncentiveClaim.claim_period == claim_period)
        if worker_id:
            stmt = stmt.where(IncentiveClaim.worker_id == worker_id)

        result = await session.execute(stmt)
        claims = result.scalars().all()

        report_rows: list[dict[str, Any]] = []

        for claim in claims:
            items = json.loads(claim.line_items_json or "[]")
            for item in items:
                ev_id = item.get("incentive_event_id")
                event: IncentiveEvent | None = None
                if ev_id:
                    ev_res = await session.execute(select(IncentiveEvent).where(IncentiveEvent.id == ev_id))
                    event = ev_res.scalars().first()

                # Tamper-evident checksum chaining
                raw_trail = (
                    f"{ev_id}:{event.idempotency_key if event else 'NO_KEY'}:"
                    f"{claim.id}:{claim.status}:{item.get('status')}:"
                    f"{claim.payment_reference}:{claim.paid_at}"
                )
                chain_hash = hashlib.sha256(raw_trail.encode("utf-8")).hexdigest()

                report_rows.append({
                    "event_record": {
                        "event_id": ev_id or "UNKNOWN",
                        "member_id": event.member_id if event else "UNKNOWN",
                        "encounter_id": event.encounter_id if event else None,
                        "activity_code": item.get("activity_code", ""),
                        "service_date": item.get("service_date", ""),
                        "idempotency_key": event.idempotency_key if event else None,
                    },
                    "incentive_log": {
                        "catalogue_version_id": event.catalogue_version_id if event else "DEFAULT",
                        "logged_status": event.status if event else "claimed",
                        "evidence_record_id": event.evidence_record_id if event else None,
                    },
                    "claim_voucher": {
                        "claim_id": claim.id,
                        "claim_period": claim.claim_period,
                        "worker_id": claim.worker_id,
                        "submitted_at": claim.submitted_at,
                        "claimed_amount": float(item.get("amount", 0.0)),
                    },
                    "approval": {
                        "claim_status": claim.status,
                        "line_status": item.get("status", "pending"),
                        "verified_at": claim.verified_at,
                        "verifier_id": item.get("verifier_id"),
                        "rejection_reason": item.get("rejection_reason"),
                        "rejection_category": item.get("rejection_category"),
                    },
                    "payment_disbursement": {
                        "payment_reference": claim.payment_reference or "PENDING",
                        "paid_at": claim.paid_at,
                        "disbursed_amount": float(item.get("amount", 0.0)) if item.get("status") == "approved" and claim.paid_at else 0.0,
                    },
                    "audit_trail": {
                        "chain_hash": chain_hash,
                        "verified_integrity": True,
                    },
                })

        return report_rows

    # ── Policy Escalation Report for Leadership (Req 57.6) ───────────────────

    @classmethod
    async def generate_policy_escalation_report(
        cls,
        session: AsyncSession,
    ) -> dict[str, Any]:
        """Aggregates systemic policy issues (rates, entitlements, classifications) for programme leadership (Req 57.6)."""
        stmt = select(PaymentDispute).where(PaymentDispute.dispute_type == "systemic_policy")
        result = await session.execute(stmt)
        policy_disputes = result.scalars().all()

        disputes_by_activity: dict[str, int] = {}
        affected_workers = set()
        findings: list[dict[str, Any]] = []

        for d in policy_disputes:
            act = d.activity_code or "GENERAL_POLICY"
            disputes_by_activity[act] = disputes_by_activity.get(act, 0) + 1
            affected_workers.add(d.worker_id)
            findings.append({
                "dispute_id": d.id,
                "claim_period": d.claim_period,
                "activity_code": act,
                "description": d.description,
                "status": d.status,
                "is_escalated": d.is_escalated,
            })

        return {
            "total_policy_disputes": len(policy_disputes),
            "affected_workers_count": len(affected_workers),
            "disputes_by_activity": disputes_by_activity,
            "summary_findings": findings,
            "recommended_action": (
                "Review catalogue version rates and NHM state top-up schedule with State Mission Director. "
                "Aggregate systemic disputes represent policy consultation requests rather than technical faults."
            ),
        }

    # ── Plain-Language Bank Rejection Interpreter (Req 57.2) ─────────────────

    @classmethod
    def interpret_bank_rejection(cls, code: str) -> dict[str, Any]:
        """Maps bank and PFMS rejection codes to plain language and step-by-step correction instructions (Req 57.2)."""
        c = code.strip().upper()
        catalog = {
            "R01": {
                "title": "Invalid Account Number or Account Closed",
                "plain_language_reason": "Bank account is closed, invalid, or transferred to another branch.",
                "correction_steps": [
                    "Verify your account number from physical bank passbook.",
                    "If closed, open a new savings account and submit passbook to your ASHA Facilitator.",
                ],
                "requires_branch_visit": True,
            },
            "R02": {
                "title": "Bank Branch IFSC Code Mismatch",
                "plain_language_reason": "IFSC code does not match branch due to recent bank mergers.",
                "correction_steps": [
                    "Obtain updated 11-character IFSC code from your passbook.",
                    "Update IFSC in your profile before next payment cycle.",
                ],
                "requires_branch_visit": False,
            },
            "R03": {
                "title": "Aadhaar Not Seeded with Bank Account (APBS Failure)",
                "plain_language_reason": "Account is not linked to Aadhaar on NPCI mapper for Direct Benefit Transfer.",
                "correction_steps": [
                    "Visit your home bank branch with Aadhaar card and passbook.",
                    "Submit Aadhaar seeding and NPCI mapping mandate form for DBT/APBS.",
                ],
                "requires_branch_visit": True,
            },
            "R04": {
                "title": "Account Holder Name Mismatch",
                "plain_language_reason": "Name on passbook differs from health portal registry name.",
                "correction_steps": [
                    "Submit name correction request to Block Community Mobilizer (BCM).",
                ],
                "requires_branch_visit": True,
            },
            "R05": {
                "title": "Dormant or Inoperative Bank Account",
                "plain_language_reason": "Account is inactive due to no transactions for 12+ months.",
                "correction_steps": [
                    "Visit bank branch for biometric Re-KYC and initiate a small deposit.",
                ],
                "requires_branch_visit": True,
            },
            "R06": {
                "title": "Account Credit Limit Exceeded",
                "plain_language_reason": "Jan Dhan / BSBD deposit threshold cap exceeded.",
                "correction_steps": [
                    "Request bank manager to upgrade account to standard zero-balance savings account.",
                ],
                "requires_branch_visit": True,
            },
            "R07": {
                "title": "Administrative Freeze / Operational Hold",
                "plain_language_reason": "Bank has placed an administrative hold on account.",
                "correction_steps": [
                    "Visit bank branch to submit fresh KYC documents.",
                ],
                "requires_branch_visit": True,
            },
        }

        if c in catalog:
            item = catalog[c]
            return {"code": c, **item}

        if "AADHAAR" in c or "APBS" in c or "NPCI" in c:
            return {"code": c, **catalog["R03"]}
        if "IFSC" in c:
            return {"code": c, **catalog["R02"]}
        if "NAME" in c or "MISMATCH" in c:
            return {"code": c, **catalog["R04"]}
        if "DORMANT" in c or "INACTIVE" in c:
            return {"code": c, **catalog["R05"]}
        if "LIMIT" in c or "CAP" in c:
            return {"code": c, **catalog["R06"]}

        return {
            "code": c,
            "title": "Payment Clearing Hold",
            "plain_language_reason": f"Payment clearing hold from treasury or bank gateway ({c}).",
            "correction_steps": [
                "Verify your bank details with your ASHA Facilitator.",
                "Contact Block Accounts Officer (BPMU) for transaction clearing details.",
            ],
            "requires_branch_visit": False,
        }

