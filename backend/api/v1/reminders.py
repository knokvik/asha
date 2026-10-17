"""API routes for Beneficiary SMS / IVR Reminders and Delivery Receipts.

Implements Requirement 26.2, 26.4:
- Dispatching opt-in reminders.
- Ingesting delivery receipts from telecommunications gateway.
- Querying reminder history per beneficiary.
"""
from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends, Header, HTTPException
from jose import JWTError
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from core.multi_tenant import TenantContext, set_tenant_context
from core.security import decode_token
from db.session import get_db
from services.sms_gateway import SmsGatewayService

router = APIRouter(prefix="/reminders", tags=["reminders"])


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


class SendReminderRequest(BaseModel):
    to_phone: str
    message_text: str
    language: str = "hi"
    member_id: str | None = None
    schedule_id: str | None = None


class DeliveryReceiptRequest(BaseModel):
    message_id: str
    status: str = Field(description="SENT, DELIVERED, FAILED, UNDELIVERED")
    failure_reason: str | None = None


@router.post("/send")
async def send_reminder(
    req: SendReminderRequest,
    current_user: TenantContext = Depends(_get_optional_tenant),
) -> dict[str, Any]:
    """Sends a privacy-checked SMS reminder to a beneficiary."""
    try:
        record = await SmsGatewayService.send_sms(
            to_phone=req.to_phone,
            message_text=req.message_text,
            language=req.language,
            member_id=req.member_id,
            schedule_id=req.schedule_id,
        )
        return {
            "status": "success",
            "message_id": record.id,
            "delivery_status": record.status,
            "to_phone": record.to_phone,
        }
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e)) from e


@router.post("/receipt")
async def record_delivery_receipt(
    req: DeliveryReceiptRequest,
) -> dict[str, Any]:
    """Ingests delivery receipts from telecom SMS/IVR gateway webhooks."""
    updated = SmsGatewayService.record_receipt(
        message_id=req.message_id,
        status=req.status,
        failure_reason=req.failure_reason,
    )
    if not updated:
        raise HTTPException(status_code=404, detail=f"Message ID {req.message_id} not found in dispatch registry.")

    return {
        "status": "receipt_recorded",
        "message_id": updated.id,
        "delivery_status": updated.status,
        "delivered_at": updated.delivered_at,
    }


@router.post("/dispatch")
async def dispatch_due_reminders(
    db: AsyncSession = Depends(get_db),
    current_user: TenantContext = Depends(_get_optional_tenant),
) -> dict[str, Any]:
    """Scans and dispatches due reminders for opted-in beneficiaries."""
    dispatched = await SmsGatewayService.dispatch_due_schedule_reminders(db)
    return {
        "status": "success",
        "dispatched_count": len(dispatched),
        "dispatched_ids": [d.id for d in dispatched],
    }


@router.get("/history/{member_id}")
async def get_reminder_history(
    member_id: str,
    current_user: TenantContext = Depends(_get_optional_tenant),
) -> dict[str, Any]:
    """Retrieves reminder dispatch history for a given member."""
    all_dispatched = SmsGatewayService.get_dispatched()
    member_history = [
        {
            "id": d.id,
            "to_phone": d.to_phone,
            "channel": d.channel,
            "status": d.status,
            "sent_at": d.sent_at,
            "delivered_at": d.delivered_at,
            "schedule_id": d.schedule_id,
            "message_text": d.message_text,
        }
        for d in all_dispatched
        if d.member_id == member_id
    ]

    return {
        "member_id": member_id,
        "count": len(member_history),
        "history": member_history,
    }
