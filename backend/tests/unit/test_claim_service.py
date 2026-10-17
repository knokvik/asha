"""Unit tests for backend claim voucher processing, verification, export, and bank validation.

Requirements: 56.1, 56.2, 56.3, 56.4, 56.5, 56.6, 56.7, 57.1
Task: 13.4
"""
from __future__ import annotations

import csv
import io
import json
import uuid
from datetime import datetime

import pytest

from models.db.models import IncentiveEvent, User
from services.incentive_service import IncentiveService


@pytest.mark.asyncio
async def test_submit_claim_and_event_status_update(db_session):
    """Req 56.1, 56.2: Submitting a claim creates record and updates event statuses to 'claimed'."""
    worker_id = f"worker_{uuid.uuid4().hex[:8]}"
    claim_id = f"claim_{uuid.uuid4().hex[:8]}"
    event_id = f"ev_{uuid.uuid4().hex[:8]}"

    # Seed an eligible event
    ev = IncentiveEvent(
        id=event_id,
        worker_id=worker_id,
        member_id="mem_01",
        activity_code="ANC_REG_EARLY",
        catalogue_version_id="DEFAULT_2024",
        event_date=int(datetime(2024, 4, 10).timestamp() * 1000),
        status="eligible",
        idempotency_key=f"key_{event_id}",
    )
    db_session.add(ev)
    await db_session.commit()

    line_items = [
        {
            "incentive_event_id": event_id,
            "activity_code": "ANC_REG_EARLY",
            "activity_name": "Early ANC Registration",
            "member_coded_id": "BEN-1A2B3C4D",
            "service_date": "2024-04-10T00:00:00",
            "amount": 150.0,
            "evidence_record_id": "enc_01",
            "status": "pending",
        }
    ]

    claim = await IncentiveService.submit_claim(
        db_session,
        claim_id=claim_id,
        worker_id=worker_id,
        claim_period="2024-04",
        line_items=line_items,
        total_amount=150.0,
    )
    await db_session.commit()

    assert claim.id == claim_id
    assert claim.status == "submitted"
    assert claim.submitted_at is not None
    assert claim.total_amount == 150.0

    # Ensure underlying event is marked claimed
    await db_session.refresh(ev)
    assert ev.status == "claimed"


@pytest.mark.asyncio
async def test_verify_claim_lines_approval_and_rejection(db_session):
    """Req 56.3: ANM line verification supports approve/reject with mandatory reason and category."""
    worker_id = f"worker_{uuid.uuid4().hex[:8]}"
    claim_id = f"claim_{uuid.uuid4().hex[:8]}"
    ev1_id = f"ev_{uuid.uuid4().hex[:8]}"
    ev2_id = f"ev_{uuid.uuid4().hex[:8]}"

    line_items = [
        {
            "incentive_event_id": ev1_id,
            "activity_code": "ANC_REG_EARLY",
            "activity_name": "Early ANC Registration",
            "member_coded_id": "BEN-11111111",
            "service_date": "2024-04-10T00:00:00",
            "amount": 150.0,
            "evidence_record_id": "enc_01",
            "status": "pending",
        },
        {
            "incentive_event_id": ev2_id,
            "activity_code": "INST_DELIVERY_ESCORT",
            "activity_name": "Institutional Delivery Escort",
            "member_coded_id": "BEN-22222222",
            "service_date": "2024-04-15T00:00:00",
            "amount": 600.0,
            "evidence_record_id": "enc_02",
            "status": "pending",
        },
    ]

    await IncentiveService.submit_claim(
        db_session,
        claim_id=claim_id,
        worker_id=worker_id,
        claim_period="2024-04",
        line_items=line_items,
        total_amount=750.0,
    )
    await db_session.commit()

    # 1. Attempt rejection WITHOUT reason -> must fail with ValueError
    with pytest.raises(ValueError, match="Mandatory rejection reason required"):
        await IncentiveService.verify_claim_lines(
            db_session,
            claim_id=claim_id,
            verifier_id="anm_verifier_01",
            line_decisions=[
                {"incentive_event_id": ev1_id, "status": "approved"},
                {
                    "incentive_event_id": ev2_id,
                    "status": "rejected",
                    "rejection_reason": "",  # Empty reason
                    "rejection_category": "DOCUMENTATION_DEFICIT",
                },
            ],
        )

    # 2. Valid verification: line 1 approved, line 2 rejected with reason & category
    updated_claim = await IncentiveService.verify_claim_lines(
        db_session,
        claim_id=claim_id,
        verifier_id="anm_verifier_01",
        line_decisions=[
            {"incentive_event_id": ev1_id, "status": "approved"},
            {
                "incentive_event_id": ev2_id,
                "status": "rejected",
                "rejection_reason": "Discharge slip missing official hospital seal",
                "rejection_category": "DOCUMENTATION_DEFICIT",
                "verifier_notes": "Please attach signed discharge summary",
            },
        ],
    )
    await db_session.commit()

    assert updated_claim.status == "verified"
    assert updated_claim.verified_at is not None

    parsed_lines = json.loads(updated_claim.line_items_json)
    line1 = next(item for item in parsed_lines if item["incentive_event_id"] == ev1_id)
    line2 = next(item for item in parsed_lines if item["incentive_event_id"] == ev2_id)

    assert line1["status"] == "approved"
    assert line2["status"] == "rejected"
    assert line2["rejection_reason"] == "Discharge slip missing official hospital seal"
    assert line2["rejection_category"] == "DOCUMENTATION_DEFICIT"


@pytest.mark.asyncio
async def test_export_asha_soft_csv_format_and_deidentification(db_session):
    """Req 56.5, 56.7: ASHA Soft CSV export contains only minimum de-identified beneficiary info and no clinical data."""
    worker_id = f"worker_{uuid.uuid4().hex[:8]}"
    claim_id = f"claim_{uuid.uuid4().hex[:8]}"

    line_items = [
        {
            "incentive_event_id": "ev_01",
            "activity_code": "ANC_REG_EARLY",
            "member_coded_id": "BEN-A1B2C3D4",
            "service_date": "2024-04-10T11:00:00",
            "amount": 150.0,
            "status": "approved",
        },
        {
            "incentive_event_id": "ev_02",
            "activity_code": "HBNC_COMPLETE",
            "member_coded_id": "BEN-E5F6G7H8",
            "service_date": "2024-04-20T14:30:00",
            "amount": 300.0,
            "status": "approved",
        },
        {
            "incentive_event_id": "ev_03",
            "activity_code": "TB_DOTS_SUPPORT",
            "member_coded_id": "BEN-99999999",
            "service_date": "2024-04-22T09:00:00",
            "amount": 1200.0,
            "status": "rejected",  # Rejected lines should be excluded by default from payment export
        },
    ]

    await IncentiveService.submit_claim(
        db_session,
        claim_id=claim_id,
        worker_id=worker_id,
        claim_period="2024-04",
        line_items=line_items,
        total_amount=1650.0,
    )
    await db_session.commit()

    csv_content = await IncentiveService.export_asha_soft_csv(
        db_session,
        claim_id=claim_id,
        only_approved=True,
    )

    reader = csv.DictReader(io.StringIO(csv_content))
    rows = list(reader)

    # Only the 2 approved rows should be in payment export
    assert len(rows) == 2

    # Check headers
    assert "Worker_ID" in reader.fieldnames
    assert "Claim_Period" in reader.fieldnames
    assert "Activity_Code" in reader.fieldnames
    assert "Beneficiary_Coded_ID" in reader.fieldnames
    assert "Amount" in reader.fieldnames
    assert "Status" in reader.fieldnames

    # Check minimum de-identified information and NO clinical terms
    for r in rows:
        assert r["Worker_ID"] == worker_id
        assert r["Claim_Period"] == "2024-04"
        assert r["Beneficiary_Coded_ID"].startswith("BEN-")
        # Invariant: No clinical notes, symptoms, or diagnoses
        assert "triage" not in str(r).lower()
        assert "clinical" not in str(r).lower()
        assert "diagnosis" not in str(r).lower()


@pytest.mark.asyncio
async def test_claim_aging_and_bottleneck_report(db_session):
    """Req 56.6: Backlog dashboard shows ageing days, bottleneck stages, and rejection analytics."""
    block_name = "Baramati"
    u = User(
        id=f"user_{uuid.uuid4().hex[:8]}",
        name="Radha Bai",
        role="ASHA",
        area_block=block_name,
    )
    db_session.add(u)
    await db_session.commit()

    c1 = f"claim_{uuid.uuid4().hex[:8]}"
    c2 = f"claim_{uuid.uuid4().hex[:8]}"

    # Claim 1: submitted 10 days ago with rejected line
    ten_days_ago_ms = int(datetime.utcnow().timestamp() * 1000) - (10 * 86400 * 1000)

    claim1 = await IncentiveService.submit_claim(
        db_session,
        claim_id=c1,
        worker_id=u.id,
        claim_period="2024-03",
        line_items=[
            {
                "incentive_event_id": "ev_rej_01",
                "activity_code": "ANC_REG_EARLY",
                "member_coded_id": "BEN-1111",
                "amount": 150.0,
                "status": "rejected",
                "rejection_category": "DATE_MISMATCH",
            }
        ],
        total_amount=150.0,
    )
    claim1.submitted_at = ten_days_ago_ms
    claim1.status = "submitted"

    # Claim 2: verified
    claim2 = await IncentiveService.submit_claim(
        db_session,
        claim_id=c2,
        worker_id=u.id,
        claim_period="2024-04",
        line_items=[
            {
                "incentive_event_id": "ev_app_01",
                "activity_code": "CBAC_SCREENING",
                "member_coded_id": "BEN-2222",
                "amount": 30.0,
                "status": "approved",
            }
        ],
        total_amount=30.0,
    )
    claim2.status = "verified"
    claim2.submitted_at = ten_days_ago_ms
    await db_session.commit()

    report = await IncentiveService.get_claim_aging_report(db_session, block_code=block_name)

    assert report["total_claims"] == 2
    assert report["active_claims"] == 2
    assert report["average_aging_days"] >= 9.9
    assert report["bottleneck_stages"]["submitted"] == 1
    assert report["bottleneck_stages"]["verified"] == 1
    assert report["rejection_reasons_summary"].get("DATE_MISMATCH") == 1


def test_validate_bank_details_rules():
    """Req 57.1: Pre-validates bank details with RBI IFSC, account format, and name matching."""
    # 1. Valid details
    valid_res = IncentiveService.validate_bank_details(
        account_holder_name="Sunita Devi",
        account_number="123456789012",
        ifsc_code="SBIN0001234",
        registered_worker_name="Sunita Devi",
        is_aadhaar_seeded=True,
    )
    assert valid_res["is_valid"] is True
    assert valid_res["ifsc_valid"] is True
    assert valid_res["account_valid"] is True
    assert valid_res["name_match_valid"] is True
    assert valid_res["name_match_score"] == 1.0
    assert len(valid_res["errors"]) == 0
    assert len(valid_res["warnings"]) == 0

    # 2. Invalid IFSC and invalid account (letters / wrong length)
    invalid_res = IncentiveService.validate_bank_details(
        account_holder_name="Pooja Sharma",
        account_number="1234",  # Too short
        ifsc_code="123456",     # Invalid format
        registered_worker_name="Sunita Devi",
        is_aadhaar_seeded=False,
    )
    assert invalid_res["is_valid"] is False
    assert invalid_res["ifsc_valid"] is False
    assert invalid_res["account_valid"] is False
    assert invalid_res["name_match_valid"] is False
    assert len(invalid_res["errors"]) == 2
    assert len(invalid_res["warnings"]) == 2  # Name mismatch warning + Aadhaar warning


@pytest.mark.asyncio
async def test_claims_api_endpoints(async_client, db_session):
    """Integration test for claims submission, verification, CSV export, and bank validation API."""
    claim_id = f"api_claim_{uuid.uuid4().hex[:8]}"

    # 1. POST /api/v1/incentives/claims
    submit_resp = await async_client.post(
        "/api/v1/incentives/claims",
        json={
            "claim_id": claim_id,
            "worker_id": "worker_test_api",
            "claim_period": "2024-05",
            "line_items": [
                {
                    "incentive_event_id": "ev_api_01",
                    "activity_code": "ANC_REG_EARLY",
                    "member_coded_id": "BEN-AABBCCDD",
                    "service_date": "2024-05-10T10:00:00",
                    "amount": 150.0,
                    "evidence_record_id": "enc_api_01",
                    "status": "pending",
                }
            ],
            "total_amount": 150.0,
        },
    )
    assert submit_resp.status_code == 200
    assert submit_resp.json()["id"] == claim_id
    assert submit_resp.json()["status"] == "submitted"

    # 2. POST /api/v1/incentives/claims/{claim_id}/verify
    verify_resp = await async_client.post(
        f"/api/v1/incentives/claims/{claim_id}/verify",
        json={
            "verifier_id": "anm_lead",
            "decisions": [
                {
                    "incentive_event_id": "ev_api_01",
                    "status": "approved",
                }
            ],
        },
    )
    assert verify_resp.status_code == 200
    assert verify_resp.json()["status"] == "approved"

    # 3. GET /api/v1/incentives/claims/{claim_id}/export (ASHA Soft CSV)
    export_resp = await async_client.get(f"/api/v1/incentives/claims/{claim_id}/export")
    assert export_resp.status_code == 200
    assert "text/csv" in export_resp.headers["content-type"]
    assert "Worker_ID,Claim_Period" in export_resp.text
    assert "BEN-AABBCCDD" in export_resp.text

    # 4. GET /api/v1/incentives/reports/claim-aging
    aging_resp = await async_client.get("/api/v1/incentives/reports/claim-aging")
    assert aging_resp.status_code == 200
    data = aging_resp.json()
    assert "total_claims" in data
    assert "bottleneck_stages" in data

    # 5. POST /api/v1/incentives/validate-bank
    bank_resp = await async_client.post(
        "/api/v1/incentives/validate-bank",
        json={
            "account_holder_name": "Meena Kumari",
            "account_number": "987654321012",
            "ifsc_code": "BARB0SHIRUR",
            "registered_worker_name": "Meena Kumari",
            "is_aadhaar_seeded": True,
        },
    )
    assert bank_resp.status_code == 200
    assert bank_resp.json()["is_valid"] is True
    assert bank_resp.json()["ifsc_valid"] is True
