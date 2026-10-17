"""Incentive endpoints for ASHA workers, ANMs, and State Administrators.

Implements Requirements 53.1 - 53.4, 54.1 - 54.6:
- Versioned catalogue retrieval with historical effective dating
- Publishing new catalogue versions
- Idempotent incentive event recording
- Cross-worker duplicate claim detection and ANM review queue
"""
from __future__ import annotations

from datetime import datetime
from typing import Any

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Response, status
from jose import JWTError
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from core.multi_tenant import TenantContext, set_tenant_context
from core.security import decode_token
from db.session import get_db
from models.db.models import IncentiveEvent, PaymentDispute
from services.incentive_service import IncentiveService

router = APIRouter(prefix="/incentives", tags=["incentives"])


async def _get_optional_tenant(authorization: str | None = Header(None)) -> TenantContext:
    if not authorization or not authorization.startswith("Bearer "):
        ctx = TenantContext(worker_id="system", role="SYSTEM", block_code="default")
        set_tenant_context(ctx)
        return ctx

    token = authorization.removeprefix("Bearer ")
    try:
        payload = decode_token(token)
    except JWTError:
        ctx = TenantContext(worker_id="system", role="SYSTEM", block_code="default")
        set_tenant_context(ctx)
        return ctx

    ctx = TenantContext(
        worker_id=payload.get("sub", "system"),
        role=payload.get("role", "SYSTEM"),
        state_code=payload.get("state_code", ""),
        district_code=payload.get("district_code", ""),
        block_code=payload.get("block_code", ""),
        area_villages=payload.get("area_villages", []),
    )
    set_tenant_context(ctx)
    return ctx


class PublishCatalogueRequest(BaseModel):
    version_id: str
    state_code: str = "DEFAULT"
    effective_from: str  # ISO date string
    effective_to: str | None = None
    description: str | None = None
    catalogue_data: dict[str, Any]


class RecordEventRequest(BaseModel):
    event_id: str | None = None
    worker_id: str | None = None
    member_id: str
    activity_code: str
    event_date: str  # ISO date string
    encounter_id: str | None = None
    evidence_record_id: str | None = None
    status: str = "eligible"
    ineligibility_reason: str | None = None
    block_code: str | None = None
    state_code: str = "DEFAULT"


class SubmitClaimRequest(BaseModel):
    claim_id: str
    worker_id: str | None = None
    claim_period: str
    line_items: list[dict[str, Any]]
    total_amount: float
    pdf_path: str | None = None


class VerifyLineDecision(BaseModel):
    incentive_event_id: str
    status: str
    rejection_reason: str | None = None
    rejection_category: str | None = None
    verifier_notes: str | None = None


class VerifyClaimRequest(BaseModel):
    verifier_id: str | None = None
    decisions: list[VerifyLineDecision]


class ValidateBankRequest(BaseModel):
    account_holder_name: str
    account_number: str
    ifsc_code: str
    registered_worker_name: str
    is_aadhaar_seeded: bool = True


class SubmitDisputeRequest(BaseModel):
    worker_id: str | None = None
    claim_period: str
    description: str
    claim_id: str | None = None
    activity_code: str | None = None
    dispute_type: str = "technical_error"
    evidence_event_ids: list[str] | None = None
    sla_days: int = 15


class ResolveDisputeRequest(BaseModel):
    resolved_by: str | None = None
    resolution_notes: str
    status: str = "resolved"


@router.get("/catalogue")
async def get_catalogue(
    date: str | None = Query(None, description="ISO date to check active catalogue for"),
    state: str = Query("DEFAULT", description="State code e.g. MH, UP, DEFAULT"),
    db: AsyncSession = Depends(get_db),
    tenant: TenantContext = Depends(_get_optional_tenant),
) -> dict[str, Any]:
    """Retrieves the catalogue active on the requested date (Req 53.2, Property 11)."""
    check_date = datetime.fromisoformat(date) if date else datetime.utcnow()
    catalogue = await IncentiveService.get_catalogue_for_date(db, check_date, state_code=state)
    if not catalogue:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No active incentive catalogue found for state {state} on {check_date.isoformat()}",
        )
    return catalogue


@router.post("/catalogue")
async def publish_catalogue(
    req: PublishCatalogueRequest,
    db: AsyncSession = Depends(get_db),
    tenant: TenantContext = Depends(_get_optional_tenant),
) -> dict[str, Any]:
    """Allows State_Admin to publish a new catalogue version (Req 53.2)."""
    eff_from = datetime.fromisoformat(req.effective_from)
    eff_to = datetime.fromisoformat(req.effective_to) if req.effective_to else None

    cat = await IncentiveService.publish_catalogue(
        db,
        version_id=req.version_id,
        state_code=req.state_code,
        effective_from=eff_from,
        catalogue_data=req.catalogue_data,
        effective_to=eff_to,
        description=req.description,
    )
    await db.commit()
    return {
        "id": cat.id,
        "version_id": cat.version_id,
        "state_code": cat.state_code,
        "effective_from": cat.effective_from.isoformat(),
        "effective_to": cat.effective_to.isoformat() if cat.effective_to else None,
        "status": "published",
    }


@router.get("/rate-lookup")
async def rate_lookup(
    activity_code: str = Query(..., description="Activity code e.g. ANC_REG_EARLY"),
    event_date: str = Query(..., description="Date event was completed"),
    state: str = Query("DEFAULT", description="State code"),
    db: AsyncSession = Depends(get_db),
    tenant: TenantContext = Depends(_get_optional_tenant),
) -> dict[str, Any]:
    """Looks up multi-component rates using the catalogue active at event_date (Property 11)."""
    date_val = datetime.fromisoformat(event_date)
    rates = await IncentiveService.get_rate_for_event(db, activity_code, date_val, state_code=state)
    return {
        "activity_code": activity_code,
        "event_date": event_date,
        "rates": rates,
    }


@router.post("/events")
async def record_event(
    req: RecordEventRequest,
    db: AsyncSession = Depends(get_db),
    tenant: TenantContext = Depends(_get_optional_tenant),
) -> dict[str, Any]:
    """Records an incentive event with idempotency and duplicate claim detection (Req 54.1, 54.6)."""
    worker_id = req.worker_id or (tenant.worker_id if tenant.worker_id != "system" else None)
    event_dt = datetime.fromisoformat(req.event_date)

    event, created = await IncentiveService.record_incentive_event(
        db,
        event_id=req.event_id,
        worker_id=worker_id,
        member_id=req.member_id,
        activity_code=req.activity_code,
        event_date=event_dt,
        encounter_id=req.encounter_id,
        evidence_record_id=req.evidence_record_id,
        status=req.status,
        ineligibility_reason=req.ineligibility_reason,
        block_code=req.block_code or tenant.block_code,
        state_code=req.state_code,
    )
    await db.commit()

    return {
        "id": event.id,
        "activity_code": event.activity_code,
        "member_id": event.member_id,
        "worker_id": event.worker_id,
        "status": event.status,
        "idempotency_key": event.idempotency_key,
        "created": created,
        "flagged_reason": event.flagged_reason,
    }


@router.get("/events/{worker_id}")
async def list_worker_events(
    worker_id: str,
    db: AsyncSession = Depends(get_db),
    tenant: TenantContext = Depends(_get_optional_tenant),
) -> list[dict[str, Any]]:
    """Lists incentive events logged for a specific worker."""
    stmt = select(IncentiveEvent).where(IncentiveEvent.worker_id == worker_id)
    result = await db.execute(stmt.order_by(IncentiveEvent.created_at.desc()))
    events = result.scalars().all()
    return [
        {
            "id": e.id,
            "activity_code": e.activity_code,
            "member_id": e.member_id,
            "status": e.status,
            "event_date": e.event_date,
            "catalogue_version_id": e.catalogue_version_id,
            "flagged_reason": e.flagged_reason,
            "evidence_record_id": e.evidence_record_id,
        }
        for e in events
    ]


@router.get("/duplicates")
async def list_duplicate_flags(
    block_code: str | None = None,
    db: AsyncSession = Depends(get_db),
    tenant: TenantContext = Depends(_get_optional_tenant),
) -> list[dict[str, Any]]:
    """Returns duplicate claims flagged for ANM review (Req 54.6)."""
    flags = await IncentiveService.get_flagged_duplicate_events(db, block_code=block_code)
    return [
        {
            "id": f.id,
            "worker_id": f.worker_id,
            "member_id": f.member_id,
            "activity_code": f.activity_code,
            "event_date": f.event_date,
            "status": f.status,
            "flagged_reason": f.flagged_reason,
            "evidence_record_id": f.evidence_record_id,
        }
        for f in flags
    ]


@router.post("/claims")
async def submit_claim(
    req: SubmitClaimRequest,
    db: AsyncSession = Depends(get_db),
    tenant: TenantContext = Depends(_get_optional_tenant),
) -> dict[str, Any]:
    """Submits or updates a monthly claim voucher for ANM verification (Req 56.1, 56.2)."""
    worker_id = req.worker_id or tenant.worker_id
    claim = await IncentiveService.submit_claim(
        db,
        claim_id=req.claim_id,
        worker_id=worker_id,
        claim_period=req.claim_period,
        line_items=req.line_items,
        total_amount=req.total_amount,
        pdf_path=req.pdf_path,
    )
    await db.commit()
    return {
        "id": claim.id,
        "worker_id": claim.worker_id,
        "claim_period": claim.claim_period,
        "status": claim.status,
        "total_amount": claim.total_amount,
        "submitted_at": claim.submitted_at,
    }


@router.post("/claims/{claim_id}/verify")
async def verify_claim(
    claim_id: str,
    req: VerifyClaimRequest,
    db: AsyncSession = Depends(get_db),
    tenant: TenantContext = Depends(_get_optional_tenant),
) -> dict[str, Any]:
    """Allows ANM/AF to verify line items with mandatory rejection reasons (Req 56.3)."""
    verifier_id = req.verifier_id or tenant.worker_id
    decisions = [d.model_dump() for d in req.decisions]
    try:
        claim = await IncentiveService.verify_claim_lines(
            db,
            claim_id=claim_id,
            verifier_id=verifier_id,
            line_decisions=decisions,
        )
        await db.commit()
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

    return {
        "id": claim.id,
        "status": claim.status,
        "verified_at": claim.verified_at,
    }


@router.get("/claims/{claim_id}/export")
async def export_claim_csv(
    claim_id: str,
    only_approved: bool = True,
    db: AsyncSession = Depends(get_db),
    tenant: TenantContext = Depends(_get_optional_tenant),
) -> Response:
    """Exports approved claim records to ASHA Soft / PFMS standard CSV (Req 56.5, 56.7)."""
    try:
        csv_data = await IncentiveService.export_asha_soft_csv(
            db,
            claim_id=claim_id,
            only_approved=only_approved,
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))

    return Response(
        content=csv_data,
        media_type="text/csv",
        headers={"Content-Disposition": f'attachment; filename="asha_soft_claim_{claim_id}.csv"'},
    )


@router.get("/reports/claim-aging")
async def claim_aging_report(
    block_code: str | None = None,
    db: AsyncSession = Depends(get_db),
    tenant: TenantContext = Depends(_get_optional_tenant),
) -> dict[str, Any]:
    """Generates claim ageing, bottleneck stages, and rejection breakdown report (Req 56.6)."""
    block = block_code or (tenant.block_code if tenant.block_code != "default" else None)
    return await IncentiveService.get_claim_aging_report(db, block_code=block)


@router.post("/validate-bank")
async def validate_bank(
    req: ValidateBankRequest,
    tenant: TenantContext = Depends(_get_optional_tenant),
) -> dict[str, Any]:
    """Pre-validates bank details for ASHA worker prior to payment cycle (Req 57.1)."""
    return IncentiveService.validate_bank_details(
        account_holder_name=req.account_holder_name,
        account_number=req.account_number,
        ifsc_code=req.ifsc_code,
        registered_worker_name=req.registered_worker_name,
        is_aadhaar_seeded=req.is_aadhaar_seeded,
    )


@router.post("/disputes")
async def submit_dispute(
    req: SubmitDisputeRequest,
    db: AsyncSession = Depends(get_db),
    tenant: TenantContext = Depends(_get_optional_tenant),
) -> dict[str, Any]:
    """Submits a payment dispute with automated SLA deadline and owner assignment (Req 57.3, 57.6)."""
    worker_id = req.worker_id or tenant.worker_id
    dispute = await IncentiveService.submit_dispute(
        db,
        worker_id=worker_id,
        claim_period=req.claim_period,
        description=req.description,
        claim_id=req.claim_id,
        activity_code=req.activity_code,
        dispute_type=req.dispute_type,
        evidence_event_ids=req.evidence_event_ids,
        sla_days=req.sla_days,
    )
    await db.commit()
    return {
        "id": dispute.id,
        "worker_id": dispute.worker_id,
        "claim_period": dispute.claim_period,
        "dispute_type": dispute.dispute_type,
        "status": dispute.status,
        "assigned_role": dispute.assigned_role,
        "sla_deadline": dispute.sla_deadline,
        "is_escalated": dispute.is_escalated,
    }


@router.get("/disputes")
async def list_disputes(
    worker_id: str | None = None,
    status: str | None = None,
    is_escalated: bool | None = None,
    db: AsyncSession = Depends(get_db),
    tenant: TenantContext = Depends(_get_optional_tenant),
) -> list[dict[str, Any]]:
    """Lists disputes with optional filtering by worker, status, and escalation flag (Req 57.3)."""
    stmt = select(PaymentDispute)
    if worker_id:
        stmt = stmt.where(PaymentDispute.worker_id == worker_id)
    if status:
        stmt = stmt.where(PaymentDispute.status == status)
    if is_escalated is not None:
        stmt = stmt.where(PaymentDispute.is_escalated.is_(is_escalated))

    result = await db.execute(stmt.order_by(PaymentDispute.created_at.desc()))
    disputes = result.scalars().all()
    return [
        {
            "id": d.id,
            "worker_id": d.worker_id,
            "claim_period": d.claim_period,
            "claim_id": d.claim_id,
            "activity_code": d.activity_code,
            "dispute_type": d.dispute_type,
            "description": d.description,
            "status": d.status,
            "assigned_role": d.assigned_role,
            "sla_deadline": d.sla_deadline,
            "is_escalated": d.is_escalated,
            "escalation_level": d.escalation_level,
            "resolution_notes": d.resolution_notes,
            "resolved_at": d.resolved_at,
            "created_at": d.created_at,
        }
        for d in disputes
    ]


@router.post("/disputes/{dispute_id}/resolve")
async def resolve_dispute(
    dispute_id: str,
    req: ResolveDisputeRequest,
    db: AsyncSession = Depends(get_db),
    tenant: TenantContext = Depends(_get_optional_tenant),
) -> dict[str, Any]:
    """Resolves or rejects a payment dispute with documented rationale (Req 57.3)."""
    resolved_by = req.resolved_by or tenant.worker_id
    try:
        dispute = await IncentiveService.resolve_dispute(
            db,
            dispute_id=dispute_id,
            resolved_by=resolved_by,
            resolution_notes=req.resolution_notes,
            status=req.status,
        )
        await db.commit()
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

    return {
        "id": dispute.id,
        "status": dispute.status,
        "resolved_by": dispute.resolved_by,
        "resolved_at": dispute.resolved_at,
        "resolution_notes": dispute.resolution_notes,
    }


@router.post("/disputes/check-sla")
async def check_sla_breaches(
    db: AsyncSession = Depends(get_db),
    tenant: TenantContext = Depends(_get_optional_tenant),
) -> dict[str, Any]:
    """Checks SLA deadlines and escalates overdue disputes (Req 57.3)."""
    escalated = await IncentiveService.check_and_escalate_disputes(db)
    await db.commit()
    return {
        "escalated_count": len(escalated),
        "escalated_ids": [d.id for d in escalated],
    }


@router.get("/alerts/payment-delays")
async def payment_delay_alerts(
    threshold_days: int = Query(45, description="Days after claim approval before alerting"),
    block_code: str | None = None,
    db: AsyncSession = Depends(get_db),
    tenant: TenantContext = Depends(_get_optional_tenant),
) -> list[dict[str, Any]]:
    """Payment delay alerts for Block/District Officers when approved disbursements stall (Req 57.4)."""
    block = block_code or (tenant.block_code if tenant.block_code != "default" else None)
    return await IncentiveService.get_payment_delay_alerts(
        db,
        threshold_days=threshold_days,
        block_code=block,
    )


@router.get("/reports/auditor-reconciliation")
async def auditor_reconciliation_report(
    claim_id: str | None = None,
    claim_period: str | None = None,
    worker_id: str | None = None,
    db: AsyncSession = Depends(get_db),
    tenant: TenantContext = Depends(_get_optional_tenant),
) -> list[dict[str, Any]]:
    """Full provenance reconciliation report tracing event -> incentive log -> voucher -> approval -> payment with tamper-evident chain (Req 57.5)."""
    return await IncentiveService.generate_auditor_reconciliation_report(
        db,
        claim_id=claim_id,
        claim_period=claim_period,
        worker_id=worker_id,
    )


@router.get("/reports/policy-escalation")
async def policy_escalation_report(
    db: AsyncSession = Depends(get_db),
    tenant: TenantContext = Depends(_get_optional_tenant),
) -> dict[str, Any]:
    """Surfaces systemic policy problems (rates, entitlements) directly to leadership (Req 57.6)."""
    return await IncentiveService.generate_policy_escalation_report(db)


@router.get("/bank-rejection/{code}")
async def explain_bank_rejection(
    code: str,
    tenant: TenantContext = Depends(_get_optional_tenant),
) -> dict[str, Any]:
    """Explains bank/PFMS rejection code in plain language with step-by-step instructions (Req 57.2)."""
    return IncentiveService.interpret_bank_rejection(code)

