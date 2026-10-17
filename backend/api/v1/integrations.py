"""API router for Government System Integrations & ABDM Interoperability.

Implements Requirements 35.1–35.7 and 36.1–36.3:
- U-WIN reconciliation (CSV import, stub creation, conflict flagging)
- Ni-kshay TB data reconciliation and presumptive case export
- HMIS 45+ monthly indicators computation, ANM review, and CSV export
- ABDM FHIR R4 Bundle generation (WellnessRecord, ImmunizationRecord, OPConsultation, DiagnosticReport)
- Consent verification & DPDP accountability logging
- Integration incident management
"""
from __future__ import annotations

import time
from typing import Any

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Response, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from core.multi_tenant import TenantContext, set_tenant_context
from core.security import decode_token
from db.session import get_db
from models.db.models import IntegrationIncident
from workers.abdm_sync import generate_abdm_bundle
from workers.hmis_export import (
    approve_hmis_monthly_indicators,
    compute_hmis_monthly_indicators,
    export_hmis_template_csv,
)
from workers.nikshay_sync import export_presumptive_tb_records, reconcile_nikshay_records
from workers.uwin_reconcile import reconcile_uwin_csv, reconcile_uwin_records

router = APIRouter(prefix="/integrations", tags=["government-integrations"])


def _now_ms() -> int:
    return int(time.time() * 1000)


async def _get_auth_context(authorization: str | None = Header(None)) -> TenantContext:
    if not authorization or not authorization.startswith("Bearer "):
        ctx = TenantContext(worker_id="system", role="SYSTEM", block_code="default")
        set_tenant_context(ctx)
        return ctx

    token = authorization.removeprefix("Bearer ")
    try:
        payload = decode_token(token)
        ctx = TenantContext(
            worker_id=payload.get("sub", "system"),
            role=payload.get("role", "SYSTEM"),
            block_code=payload.get("block_code", "default"),
            state_code=payload.get("state_code", "default"),
        )
        set_tenant_context(ctx)
        return ctx
    except Exception:
        ctx = TenantContext(worker_id="system", role="SYSTEM", block_code="default")
        set_tenant_context(ctx)
        return ctx


# ── Pydantic Request Models ───────────────────────────────────────────────────


class UWinCsvReconcileRequest(BaseModel):
    csv_content: str = Field(..., description="Raw CSV content from U-WIN portal")
    state_code: str = Field("default", description="State code for field mapping")


class UWinJsonReconcileRequest(BaseModel):
    records: list[dict[str, Any]]
    state_code: str = Field("default", description="State code for field mapping")


class NikshayImportRequest(BaseModel):
    records: list[dict[str, Any]]
    state_code: str = Field("default", description="State code for field mapping")


class HmisComputeRequest(BaseModel):
    period: str = Field(..., description="Reporting period in YYYY-MM format")
    block_code: str | None = Field(None, description="Optional block code filter")
    state_code: str = Field("default", description="State code for mapping")


class HmisApproveRequest(BaseModel):
    report_data: dict[str, Any]
    approval_notes: str | None = Field(None, description="ANM review notes")


class HmisExportCsvRequest(BaseModel):
    indicators_data: dict[str, Any]


class AbdmBundleRequest(BaseModel):
    member_id: str
    record_type: str = Field(
        ...,
        description="WellnessRecord, ImmunizationRecord, OPConsultation, or DiagnosticReport",
    )
    consent_artifact: dict[str, Any] = Field(
        ...,
        description="ABDM Consent Manager artifact dictionary",
    )


class IncidentResolveRequest(BaseModel):
    resolution_notes: str


# ── Endpoints ─────────────────────────────────────────────────────────────────


@router.post("/uwin/reconcile-csv", status_code=status.HTTP_200_OK)
async def reconcile_uwin_csv_endpoint(
    req: UWinCsvReconcileRequest,
    db: AsyncSession = Depends(get_db),
    ctx: TenantContext = Depends(_get_auth_context),
) -> dict[str, Any]:
    """Reconciles U-WIN digital vaccination CSV records with local database (Req 35.1–35.5)."""
    return await reconcile_uwin_csv(
        db=db,
        csv_content=req.csv_content,
        state_code=req.state_code,
        uploaded_by=ctx.worker_id,
    )


@router.post("/uwin/reconcile-json", status_code=status.HTTP_200_OK)
async def reconcile_uwin_json_endpoint(
    req: UWinJsonReconcileRequest,
    db: AsyncSession = Depends(get_db),
    ctx: TenantContext = Depends(_get_auth_context),
) -> dict[str, Any]:
    """Reconciles U-WIN records passed as JSON objects."""
    return await reconcile_uwin_records(
        db=db,
        uwin_records=req.records,
        state_code=req.state_code,
        uploaded_by=ctx.worker_id,
    )


@router.post("/nikshay/import-cases", status_code=status.HTTP_200_OK)
async def import_nikshay_cases_endpoint(
    req: NikshayImportRequest,
    db: AsyncSession = Depends(get_db),
    ctx: TenantContext = Depends(_get_auth_context),
) -> dict[str, Any]:
    """Imports and reconciles Ni-kshay TB diagnostic and treatment records (Req 35.1, 35.3)."""
    return await reconcile_nikshay_records(
        db=db,
        nikshay_records=req.records,
        state_code=req.state_code,
        uploaded_by=ctx.worker_id,
    )


@router.get("/nikshay/export-presumptive", status_code=status.HTTP_200_OK)
async def export_nikshay_presumptive_endpoint(
    block_code: str | None = Query(None),
    anm_approved_only: bool = Query(True),
    state_code: str = Query("default"),
    db: AsyncSession = Depends(get_db),
    ctx: TenantContext = Depends(_get_auth_context),
) -> list[dict[str, Any]]:
    """Exports presumptive TB cases for Ni-kshay bulk upload upon ANM approval (Req 35.1)."""
    return await export_presumptive_tb_records(
        db=db,
        block_code=block_code or ctx.block_code,
        anm_approved_only=anm_approved_only,
        state_code=state_code,
        exported_by=ctx.worker_id,
    )


@router.post("/hmis/compute-indicators", status_code=status.HTTP_200_OK)
async def compute_hmis_indicators_endpoint(
    req: HmisComputeRequest,
    db: AsyncSession = Depends(get_db),
    ctx: TenantContext = Depends(_get_auth_context),
) -> dict[str, Any]:
    """Computes 45+ HMIS monthly indicators from clinical events for ANM review (Req 35.6)."""
    block = req.block_code if req.block_code else (ctx.block_code if ctx.block_code != "default" else None)
    return await compute_hmis_monthly_indicators(
        db=db,
        period=req.period,
        block_code=block,
        state_code=req.state_code,
    )


@router.post("/hmis/approve", status_code=status.HTTP_200_OK)
async def approve_hmis_indicators_endpoint(
    req: HmisApproveRequest,
    ctx: TenantContext = Depends(_get_auth_context),
) -> dict[str, Any]:
    """Allows ANM to review and approve computed HMIS monthly indicators (Req 35.6)."""
    return approve_hmis_monthly_indicators(
        report_data=req.report_data,
        anm_id=ctx.worker_id,
        notes=req.approval_notes,
    )


@router.post("/hmis/export-csv", status_code=status.HTTP_200_OK)
async def export_hmis_csv_endpoint(
    req: HmisExportCsvRequest,
    db: AsyncSession = Depends(get_db),
    ctx: TenantContext = Depends(_get_auth_context),
) -> Response:
    """Exports HMIS indicators into MoHFW standard bulk-upload CSV format (Req 35.2, 35.7)."""
    csv_text = await export_hmis_template_csv(
        db=db,
        indicators_data=req.indicators_data,
        exported_by=ctx.worker_id,
    )
    period = req.indicators_data.get("period", "monthly")
    filename = f"HMIS_Monthly_Report_{period}.csv"
    return Response(
        content=csv_text,
        media_type="text/csv",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@router.post("/abdm/generate-bundle", status_code=status.HTTP_200_OK)
async def generate_abdm_bundle_endpoint(
    req: AbdmBundleRequest,
    db: AsyncSession = Depends(get_db),
    ctx: TenantContext = Depends(_get_auth_context),
) -> dict[str, Any]:
    """Generates FHIR R4 Bundle under ABDM profiles with consent verification (Req 36.2, 36.3, 35.7)."""
    try:
        return await generate_abdm_bundle(
            db=db,
            member_id=req.member_id,
            record_type=req.record_type,
            consent_artifact=req.consent_artifact,
            requested_by=ctx.worker_id,
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc))


@router.get("/incidents", status_code=status.HTTP_200_OK)
async def list_integration_incidents_endpoint(
    system_name: str | None = Query(None),
    status_filter: str | None = Query(None, alias="status"),
    db: AsyncSession = Depends(get_db),
) -> list[dict[str, Any]]:
    """Surfaces integration errors and external rejection reasons to ANM/ASHA (Req 35.5)."""
    stmt = select(IntegrationIncident).order_by(IntegrationIncident.created_at.desc())
    if system_name:
        stmt = stmt.where(IntegrationIncident.system_name == system_name)
    if status_filter:
        stmt = stmt.where(IntegrationIncident.status == status_filter)

    res = await db.execute(stmt)
    incidents = res.scalars().all()

    return [
        {
            "id": inc.id,
            "system_name": inc.system_name,
            "record_type": inc.record_type,
            "external_id": inc.external_id,
            "error_code": inc.error_code,
            "error_message": inc.error_message,
            "raw_payload": inc.raw_payload,
            "status": inc.status,
            "resolution_notes": inc.resolution_notes,
            "resolved_at": inc.resolved_at,
            "created_at": inc.created_at,
        }
        for inc in incidents
    ]


@router.post("/incidents/{incident_id}/resolve", status_code=status.HTTP_200_OK)
async def resolve_integration_incident_endpoint(
    incident_id: str,
    req: IncidentResolveRequest,
    db: AsyncSession = Depends(get_db),
) -> dict[str, Any]:
    """Marks an integration incident as resolved with explanation notes."""
    stmt = select(IntegrationIncident).where(IntegrationIncident.id == incident_id)
    res = await db.execute(stmt)
    incident = res.scalar_one_or_none()
    if not incident:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Incident not found")

    incident.status = "resolved"
    incident.resolved_at = _now_ms()
    incident.resolution_notes = req.resolution_notes
    await db.commit()

    return {"status": "success", "incident_id": incident.id, "resolved_at": incident.resolved_at}
