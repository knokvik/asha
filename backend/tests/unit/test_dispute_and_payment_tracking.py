"""Unit tests for dispute resolution, SLA escalation, payment delay alerts, and auditor reconciliation.

Requirements: 57.2, 57.3, 57.4, 57.5, 57.6
Task: 13.5
"""
from __future__ import annotations

import json
import uuid
from datetime import datetime

import pytest
from sqlalchemy import select

from models.db.models import AuditLog, IncentiveClaim, IncentiveEvent, PaymentDispute, User
from services.incentive_service import IncentiveService


@pytest.mark.asyncio
async def test_submit_dispute_and_audit_trail(db_session):
    """Req 57.3: Dispute submission sets 15-day SLA, initial AF role, and tamper-evident audit record."""
    worker_id = f"worker_{uuid.uuid4().hex[:8]}"

    dispute = await IncentiveService.submit_dispute(
        db_session,
        worker_id=worker_id,
        claim_period="2024-04",
        activity_code="ANC_REG_EARLY",
        description="Missing payment for early registration of Priya Devi.",
        evidence_event_ids=["ev_01", "enc_01"],
        sla_days=15,
    )
    await db_session.commit()

    assert dispute.id is not None
    assert dispute.worker_id == worker_id
    assert dispute.claim_period == "2024-04"
    assert dispute.status == "submitted"
    assert dispute.assigned_role == "AF"
    assert dispute.is_escalated is False

    # Check SLA deadline: ~15 days in future
    now_ms = int(datetime.utcnow().timestamp() * 1000)
    assert dispute.sla_deadline > now_ms

    # Check AuditLog entry created with chain_hash (Req 33, 57.5)
    stmt = select(AuditLog).where(AuditLog.record_id == dispute.id)
    res = await db_session.execute(stmt)
    audit = res.scalars().first()
    assert audit is not None
    assert audit.table_name == "payment_disputes"
    assert audit.chain_hash is not None
    assert len(audit.chain_hash) == 64


@pytest.mark.asyncio
async def test_sla_breach_escalation(db_session):
    """Req 57.3: Overdue dispute is escalated from AF to BPMU/District Officer."""
    worker_id = f"worker_{uuid.uuid4().hex[:8]}"
    past_ms = int(datetime.utcnow().timestamp() * 1000) - (16 * 86400 * 1000)
    overdue_sla_ms = int(datetime.utcnow().timestamp() * 1000) - (1 * 86400 * 1000)

    # Seed overdue dispute
    dispute = PaymentDispute(
        id=str(uuid.uuid4()),
        worker_id=worker_id,
        claim_period="2024-03",
        description="Overdue dispute awaiting AF verification.",
        status="submitted",
        assigned_role="AF",
        sla_deadline=overdue_sla_ms,
        is_escalated=False,
        escalation_level=0,
        created_at=past_ms,
        updated_at=past_ms,
    )
    db_session.add(dispute)
    await db_session.commit()

    escalated = await IncentiveService.check_and_escalate_disputes(db_session)
    await db_session.commit()

    assert any(d.id == dispute.id for d in escalated)
    await db_session.refresh(dispute)

    assert dispute.is_escalated is True
    assert dispute.escalation_level == 1
    assert dispute.assigned_role == "BPMU"  # Reassigned from AF to BPMU


@pytest.mark.asyncio
async def test_resolve_dispute(db_session):
    """Req 57.3: Resolves dispute with rationale notes and audit entry."""
    worker_id = f"worker_{uuid.uuid4().hex[:8]}"
    dispute = await IncentiveService.submit_dispute(
        db_session,
        worker_id=worker_id,
        claim_period="2024-04",
        description="Disputed payment amount.",
    )
    await db_session.commit()

    resolved = await IncentiveService.resolve_dispute(
        db_session,
        dispute_id=dispute.id,
        resolved_by="bpm_officer_01",
        resolution_notes="Approved retroactive JSY payment after register cross-check.",
        status="resolved",
    )
    await db_session.commit()

    assert resolved.status == "resolved"
    assert resolved.resolved_by == "bpm_officer_01"
    assert resolved.resolution_notes is not None
    assert resolved.resolved_at is not None


@pytest.mark.asyncio
async def test_payment_delay_alerts_grouping_and_severity(db_session):
    """Req 57.4: Detects approved claims delayed > 45 days and aggregates by block for officer dashboard."""
    block_name = "Haveli"
    user_id = f"user_{uuid.uuid4().hex[:8]}"

    u = User(
        id=user_id,
        name="Lata Mhatre",
        role="ASHA",
        area_block=block_name,
    )
    db_session.add(u)
    await db_session.commit()

    # 50 days delayed approved claim
    now_ms = int(datetime.utcnow().timestamp() * 1000)
    fifty_days_ago_ms = now_ms - (50 * 86400 * 1000)

    claim = IncentiveClaim(
        id=str(uuid.uuid4()),
        worker_id=user_id,
        claim_period="2024-02",
        status="approved",
        total_amount=3500.0,
        line_items_json="[]",
        submitted_at=fifty_days_ago_ms,
        verified_at=fifty_days_ago_ms,
        paid_at=None,  # Unpaid!
    )
    db_session.add(claim)
    await db_session.commit()

    alerts = await IncentiveService.get_payment_delay_alerts(
        db_session,
        threshold_days=45,
        block_code=block_name,
    )

    assert len(alerts) == 1
    alert = alerts[0]
    assert alert["block"] == block_name
    assert alert["delayed_claims_count"] == 1
    assert alert["total_delayed_amount"] == 3500.0
    assert alert["max_days_delayed"] >= 49.9
    assert alert["alert_level"] in ("WARNING", "CRITICAL")
    assert "Payment delay alert" in alert["message"]


@pytest.mark.asyncio
async def test_auditor_full_provenance_reconciliation_report(db_session):
    """Req 57.5: Full provenance reconciliation tracing event -> incentive log -> claim voucher -> approval -> disbursement with SHA-256 chain."""
    event_id = f"ev_{uuid.uuid4().hex[:8]}"
    claim_id = f"claim_{uuid.uuid4().hex[:8]}"
    worker_id = f"worker_{uuid.uuid4().hex[:8]}"
    now_ms = int(datetime.utcnow().timestamp() * 1000)

    ev = IncentiveEvent(
        id=event_id,
        worker_id=worker_id,
        member_id="mem_test_01",
        activity_code="INST_DELIVERY_ESCORT",
        catalogue_version_id="DEFAULT_2024",
        event_date=now_ms - 86400000,
        status="approved",
        idempotency_key=f"key_{event_id}",
    )
    db_session.add(ev)

    claim = IncentiveClaim(
        id=claim_id,
        worker_id=worker_id,
        claim_period="2024-04",
        status="paid",
        total_amount=600.0,
        line_items_json=json.dumps([
            {
                "incentive_event_id": event_id,
                "activity_code": "INST_DELIVERY_ESCORT",
                "member_coded_id": "BEN-12345678",
                "service_date": "2024-04-10T10:00:00",
                "amount": 600.0,
                "status": "approved",
                "verifier_id": "anm_lead",
            }
        ]),
        payment_reference="UTR_SBIN202404010099",
        submitted_at=now_ms - 70000000,
        verified_at=now_ms - 50000000,
        paid_at=now_ms - 10000000,
    )
    db_session.add(claim)
    await db_session.commit()

    report = await IncentiveService.generate_auditor_reconciliation_report(
        db_session,
        claim_id=claim_id,
    )

    assert len(report) == 1
    row = report[0]

    # 1. Event record
    assert row["event_record"]["event_id"] == event_id
    assert row["event_record"]["activity_code"] == "INST_DELIVERY_ESCORT"

    # 2. Incentive log
    assert row["incentive_log"]["catalogue_version_id"] == "DEFAULT_2024"

    # 3. Claim voucher
    assert row["claim_voucher"]["claim_id"] == claim_id
    assert row["claim_voucher"]["claimed_amount"] == 600.0

    # 4. Approval
    assert row["approval"]["line_status"] == "approved"
    assert row["approval"]["verifier_id"] == "anm_lead"

    # 5. Disbursement
    assert row["payment_disbursement"]["payment_reference"] == "UTR_SBIN202404010099"
    assert row["payment_disbursement"]["disbursed_amount"] == 600.0

    # 6. Tamper-evident checksum
    assert row["audit_trail"]["verified_integrity"] is True
    assert len(row["audit_trail"]["chain_hash"]) == 64


@pytest.mark.asyncio
async def test_policy_escalation_report(db_session):
    """Req 57.6: Automatically aggregates systemic policy disputes for state leadership review."""
    worker_id = f"worker_{uuid.uuid4().hex[:8]}"

    # Dispute mentions "minimum wage" and "honorarium rate"
    await IncentiveService.submit_dispute(
        db_session,
        worker_id=worker_id,
        claim_period="2024-04",
        activity_code="ROUTINE_RECURRENT",
        description="Monthly honorarium rate is below statutory minimum wage for community health work.",
    )
    await db_session.commit()

    report = await IncentiveService.generate_policy_escalation_report(db_session)

    assert report["total_policy_disputes"] >= 1
    assert "ROUTINE_RECURRENT" in report["disputes_by_activity"]
    assert "Review catalogue version rates" in report["recommended_action"]


def test_interpret_bank_rejection():
    """Req 57.2: Interprets bank/PFMS rejection codes into human language and clear correction steps."""
    # R03: Aadhaar Seeding APBS Failure
    r03 = IncentiveService.interpret_bank_rejection("R03")
    assert r03["code"] == "R03"
    assert r03["requires_branch_visit"] is True
    assert "Aadhaar" in r03["title"]
    assert any("NPCI" in step for step in r03["correction_steps"])

    # R02: IFSC Mismatch
    r02 = IncentiveService.interpret_bank_rejection("R02")
    assert "IFSC" in r02["title"]
    assert r02["requires_branch_visit"] is False


@pytest.mark.asyncio
async def test_dispute_and_tracking_api_endpoints(async_client, db_session):
    """API integration tests for disputes, delay alerts, auditor reports, and bank rejections."""
    # 1. POST /api/v1/incentives/disputes
    post_resp = await async_client.post(
        "/api/v1/incentives/disputes",
        json={
            "worker_id": "worker_api_dispute",
            "claim_period": "2024-05",
            "activity_code": "HBNC_COMPLETE",
            "description": "HBNC 7th visit was logged but omitted from summary.",
            "evidence_event_ids": ["ev_hbnc_01"],
            "sla_days": 10,
        },
    )
    assert post_resp.status_code == 200
    dispute_data = post_resp.json()
    assert dispute_data["status"] == "submitted"
    dispute_id = dispute_data["id"]

    # 2. GET /api/v1/incentives/disputes
    list_resp = await async_client.get("/api/v1/incentives/disputes?worker_id=worker_api_dispute")
    assert list_resp.status_code == 200
    assert len(list_resp.json()) >= 1

    # 3. POST /api/v1/incentives/disputes/{id}/resolve
    resolve_resp = await async_client.post(
        f"/api/v1/incentives/disputes/{dispute_id}/resolve",
        json={
            "resolved_by": "supervisor_01",
            "resolution_notes": "Added missing event to upcoming voucher.",
            "status": "resolved",
        },
    )
    assert resolve_resp.status_code == 200
    assert resolve_resp.json()["status"] == "resolved"

    # 4. POST /api/v1/incentives/disputes/check-sla
    sla_resp = await async_client.post("/api/v1/incentives/disputes/check-sla")
    assert sla_resp.status_code == 200
    assert "escalated_count" in sla_resp.json()

    # 5. GET /api/v1/incentives/alerts/payment-delays
    alerts_resp = await async_client.get("/api/v1/incentives/alerts/payment-delays?threshold_days=45")
    assert alerts_resp.status_code == 200
    assert isinstance(alerts_resp.json(), list)

    # 6. GET /api/v1/incentives/reports/auditor-reconciliation
    recon_resp = await async_client.get("/api/v1/incentives/reports/auditor-reconciliation")
    assert recon_resp.status_code == 200
    assert isinstance(recon_resp.json(), list)

    # 7. GET /api/v1/incentives/reports/policy-escalation
    policy_resp = await async_client.get("/api/v1/incentives/reports/policy-escalation")
    assert policy_resp.status_code == 200
    assert "total_policy_disputes" in policy_resp.json()

    # 8. GET /api/v1/incentives/bank-rejection/R01
    bank_rej_resp = await async_client.get("/api/v1/incentives/bank-rejection/R01")
    assert bank_rej_resp.status_code == 200
    assert "Account Closed" in bank_rej_resp.json()["title"]
