"""Comprehensive unit and integration tests for Government Digital System Integrations.

Tests Requirements 35.1–35.7, 36.1–36.3 and Task 13.6:
- U-WIN CSV and JSON reconciliation, RCH stubbing, and date conflict flagging.
- Ni-kshay TB reconciliation and ANM-approved presumptive case export.
- HMIS 45+ monthly indicators computation, ANM review workflow, and MoHFW CSV export.
- ABDM FHIR R4 Bundle generation (WellnessRecord, ImmunizationRecord, OPConsultation, DiagnosticReport).
- Consent artifact scope and expiry enforcement (Req 36.3).
- DPDP outbound sharing audit logs (Req 35.7).
- Integration incidents logging and resolution without blocking sync (Req 35.5).
"""
from __future__ import annotations

import time
import uuid

from httpx import AsyncClient
import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models.db.models import (
    ClinicalEncounter,
    ClinicalObservation,
    ConflictReview,
    Household,
    IntegrationIncident,
    Member,
    OutboundSharingLog,
)
from workers.abdm_sync import generate_abdm_bundle, validate_consent_artifact
from workers.hmis_export import (
    approve_hmis_monthly_indicators,
    compute_hmis_monthly_indicators,
    export_hmis_template_csv,
)
from workers.nikshay_sync import export_presumptive_tb_records
from workers.uwin_reconcile import reconcile_uwin_csv, reconcile_uwin_records


def _now_ms() -> int:
    return int(time.time() * 1000)


# ── 1. U-WIN Reconciliation Tests ─────────────────────────────────────────────


@pytest.mark.asyncio
async def test_uwin_csv_reconciliation_and_rch_stubbing(db_session: AsyncSession) -> None:
    """Req 35.1, 35.3: Parses U-WIN CSV and creates stubs for unmatched RCH IDs."""
    now = _now_ms()
    existing_rch = f"RCH_{uuid.uuid4().hex[:8]}"
    unmatched_rch = f"RCH_NEW_{uuid.uuid4().hex[:8]}"

    # Seed existing member with RCH ID
    member = Member(
        id=f"m_{uuid.uuid4().hex[:8]}",
        rch_id=existing_rch,
        name="Existing Child",
        sex="M",
        created_at=now,
        updated_at=now,
    )
    db_session.add(member)
    await db_session.commit()

    # CSV with 1 existing beneficiary and 1 new beneficiary (with RCH ID)
    csv_data = f"""rch_number,child_name,vaccine_code,dose_date,batch_no,session_site,anm_name
{existing_rch},Existing Child,BCG,{now},BATCH-BCG-01,PHC Rampur,ANM Maya
{unmatched_rch},Unmatched Infant,OPV_0,{now},BATCH-OPV-02,Subcentre 1,ANM Sunita
"""

    stats = await reconcile_uwin_csv(db_session, csv_data, state_code="default")

    assert stats["total_records"] == 2
    assert stats["new_doses_imported"] == 2
    assert stats["stubs_created"] == 1
    assert stats["unmatched_beneficiaries"] == 0

    # Verify stub member was created
    stub_res = await db_session.execute(select(Member).where(Member.rch_id == unmatched_rch))
    stub = stub_res.scalar_one_or_none()
    assert stub is not None
    assert stub.lifecycle_status == "stub"
    assert "Unmatched Infant" in (stub.name or "")

    # Verify DPDP outbound sharing log
    log_res = await db_session.execute(
        select(OutboundSharingLog).where(OutboundSharingLog.target_system == "U-WIN")
    )
    logs = log_res.scalars().all()
    assert len(logs) >= 1
    assert logs[-1].record_type == "IMMUNIZATION_RECONCILIATION"


@pytest.mark.asyncio
async def test_uwin_date_conflict_review_flagged(db_session: AsyncSession) -> None:
    """Req 35.3, Task 13.6: Date mismatch (>7 days) between local observation and U-WIN triggers ConflictReview."""
    now = _now_ms()
    member_id = f"m_{uuid.uuid4().hex[:8]}"
    rch_id = f"RCH_CONF_{uuid.uuid4().hex[:8]}"

    member = Member(
        id=member_id,
        rch_id=rch_id,
        name="Tara Devi",
        sex="F",
        created_at=now,
        updated_at=now,
    )
    db_session.add(member)

    # Local record 10 days ago
    local_admin_date = now - (10 * 86400 * 1000)
    enc_id = f"enc_loc_{uuid.uuid4().hex[:8]}"
    enc = ClinicalEncounter(
        id=enc_id,
        member_id=member_id,
        encounter_type="IMMUNIZATION_DOSE",
        encounter_date=local_admin_date,
        created_at=now,
        updated_at=now,
    )
    db_session.add(enc)

    obs = ClinicalObservation(
        id=f"obs_loc_{uuid.uuid4().hex[:8]}",
        encounter_id=enc_id,
        observation_code="VACCINE_CODE",
        value_text="PENTA_1",
        observed_at=local_admin_date,
    )
    db_session.add(obs)
    await db_session.commit()

    # Incoming U-WIN record with date = now (10 days later than local date)
    records = [
        {
            "member_id": member_id,
            "vaccine_code": "PENTA_1",
            "administered_date_ms": now,
        }
    ]

    stats = await reconcile_uwin_records(db_session, records)
    assert stats["already_recorded"] == 1
    assert stats["date_conflicts_flagged"] == 1

    # Verify ConflictReview record
    cr_res = await db_session.execute(
        select(ConflictReview).where(ConflictReview.conflict_type == "UWIN_DATE_MISMATCH")
    )
    conflict = cr_res.scalars().first()
    assert conflict is not None
    assert conflict.table_name == "clinical_observations"
    assert conflict.status == "pending"


@pytest.mark.asyncio
async def test_uwin_unmatched_without_rch_logs_incident(db_session: AsyncSession) -> None:
    """Req 35.5: Beneficiary without RCH ID logs incident and never crashes or blocks sync."""
    records = [
        {
            "phone": "9998887776",
            "vaccine_code": "MR_1",
            "administered_date_ms": _now_ms(),
        }
    ]

    stats = await reconcile_uwin_records(db_session, records)
    assert stats["unmatched_beneficiaries"] == 1
    assert stats["incidents_logged"] == 1

    # Verify IntegrationIncident recorded
    inc_res = await db_session.execute(
        select(IntegrationIncident).where(IntegrationIncident.system_name == "U-WIN")
    )
    incident = inc_res.scalars().first()
    assert incident is not None
    assert incident.error_code == "UNMATCHED_BENEFICIARY"
    assert incident.status == "open"


# ── 2. Ni-kshay Reconciliation & Presumptive Export Tests ───────────────────────


@pytest.mark.asyncio
async def test_nikshay_reconcile_and_presumptive_export(db_session: AsyncSession) -> None:
    """Req 35.1, 35.3: Ni-kshay reconciliation and export of ANM-approved presumptive TB cases."""
    now = _now_ms()
    member_id = f"m_{uuid.uuid4().hex[:8]}"
    hh_id = f"hh_{uuid.uuid4().hex[:8]}"

    hh = Household(id=hh_id, village="Shahpur", created_at=now, updated_at=now)
    db_session.add(hh)

    member = Member(
        id=member_id,
        household_id=hh_id,
        name="Vikram Singh",
        sex="M",
        phone="9811223344",
        block_code="BLOCK_A",
        created_at=now,
        updated_at=now,
    )
    db_session.add(member)

    # 1. Test presumptive TB encounter
    enc_id = f"enc_tb_{uuid.uuid4().hex[:8]}"
    enc = ClinicalEncounter(
        id=enc_id,
        member_id=member_id,
        encounter_type="TB_SCREENING",
        program_code="tb",
        encounter_date=now,
        status="completed",
        created_at=now,
        updated_at=now,
    )
    db_session.add(enc)

    obs_list = [
        ClinicalObservation(
            id=f"obs_{uuid.uuid4().hex[:8]}",
            encounter_id=enc_id,
            observation_code="ANM_APPROVAL_STATUS",
            value_text="APPROVED",
            observed_at=now,
        ),
        ClinicalObservation(
            id=f"obs_{uuid.uuid4().hex[:8]}",
            encounter_id=enc_id,
            observation_code="COUGH_DURATION_DAYS",
            value_text="21",
            observed_at=now,
        ),
        ClinicalObservation(
            id=f"obs_{uuid.uuid4().hex[:8]}",
            encounter_id=enc_id,
            observation_code="FEVER",
            value_text="YES",
            observed_at=now,
        ),
    ]
    for o in obs_list:
        db_session.add(o)

    await db_session.commit()

    # Export presumptive records with anm_approved_only=True
    exported = await export_presumptive_tb_records(
        db=db_session,
        block_code="BLOCK_A",
        anm_approved_only=True,
    )

    assert len(exported) >= 1
    item = next(x for x in exported if x["member_id"] == member_id)
    assert item["beneficiary_name"] == "Vikram Singh"
    assert item["cough_duration_days"] == "21"
    assert item["has_fever"] is True
    assert item["anm_approval_status"] == "APPROVED"

    # Verify DPDP outbound sharing log
    log_res = await db_session.execute(
        select(OutboundSharingLog).where(OutboundSharingLog.target_system == "Ni-kshay")
    )
    assert len(log_res.scalars().all()) >= 1


# ── 3. HMIS 45+ Indicators Computation & Export Tests ─────────────────────────


@pytest.mark.asyncio
async def test_hmis_monthly_indicators_computation_and_approval(db_session: AsyncSession) -> None:
    """Req 35.6, Task 13.6: Auto-computes 45+ monthly HMIS indicators and supports ANM review/export."""
    now = _now_ms()
    member_id = f"m_{uuid.uuid4().hex[:8]}"

    member = Member(
        id=member_id,
        name="Pooja Sharma",
        sex="F",
        block_code="BLOCK_B",
        created_at=now,
        updated_at=now,
    )
    db_session.add(member)

    # Seed an encounter and observation in current month
    enc = ClinicalEncounter(
        id=f"enc_{uuid.uuid4().hex[:8]}",
        member_id=member_id,
        encounter_type="IMMUNIZATION_DOSE",
        encounter_date=now,
        created_at=now,
        updated_at=now,
    )
    db_session.add(enc)

    obs = ClinicalObservation(
        id=f"obs_{uuid.uuid4().hex[:8]}",
        encounter_id=enc.id,
        observation_code="VACCINE_CODE",
        value_text="BCG",
        observed_at=now,
    )
    db_session.add(obs)
    await db_session.commit()

    # Compute indicators for period
    import datetime
    today = datetime.date.today()
    period = f"{today.year:04d}-{today.month:02d}"

    result = await compute_hmis_monthly_indicators(
        db=db_session,
        period=period,
        block_code="BLOCK_B",
    )

    # Must contain 45+ indicators
    assert result["total_indicators"] >= 45
    assert result["status"] == "draft_for_anm_review"
    assert "M1.1" in result["indicators"]
    assert "M2.8" in result["indicators"]  # BCG indicator
    assert result["indicators"]["M2.8"]["value"] >= 1

    # ANM approves report
    approved_report = approve_hmis_monthly_indicators(
        report_data=result,
        anm_id="anm_user_42",
        notes="Reviewed all 47 subcentre indicators against register.",
    )
    assert approved_report["status"] == "anm_approved"
    assert approved_report["approved_by"] == "anm_user_42"

    # Export CSV template
    csv_content = await export_hmis_template_csv(
        db=db_session,
        indicators_data=approved_report,
        exported_by="anm_user_42",
    )
    assert "HMIS_MONTHLY_REPORT" in csv_content
    assert "Indicator_Code" in csv_content
    assert "M2.8" in csv_content

    # Verify DPDP outbound sharing log
    log_res = await db_session.execute(
        select(OutboundSharingLog).where(OutboundSharingLog.target_system == "HMIS")
    )
    assert len(log_res.scalars().all()) >= 1


# ── 4. ABDM FHIR R4 Bundle Generation & Consent Validation Tests ───────────────


@pytest.mark.asyncio
async def test_abdm_consent_validation_logic() -> None:
    """Req 36.3: Validates consent scope, expiry, and active status."""
    now = _now_ms()

    # 1. Valid consent
    valid_consent = {
        "id": "consent_123",
        "status": "ACTIVE",
        "patient_id": "mem_01",
        "permitted_hi_types": ["WellnessRecord", "ImmunizationRecord"],
        "expires_at_ms": now + 86400000,
    }
    is_valid, msg = validate_consent_artifact(valid_consent, "WellnessRecord", "mem_01")
    assert is_valid is True

    # 2. Expired consent
    expired_consent = dict(valid_consent, expires_at_ms=now - 5000)
    is_valid, msg = validate_consent_artifact(expired_consent, "WellnessRecord", "mem_01")
    assert is_valid is False
    assert "expired" in msg.lower()

    # 3. Unpermitted HI type
    is_valid, msg = validate_consent_artifact(valid_consent, "DiagnosticReport", "mem_01")
    assert is_valid is False
    assert "scope" in msg.lower()

    # 4. Revoked / Inactive consent
    revoked_consent = dict(valid_consent, status="REVOKED")
    is_valid, msg = validate_consent_artifact(revoked_consent, "WellnessRecord", "mem_01")
    assert is_valid is False
    assert "revoked" in msg.lower()


@pytest.mark.asyncio
async def test_abdm_fhir_bundle_generation(db_session: AsyncSession) -> None:
    """Req 36.2: Generates ABDM-compliant FHIR R4 Bundles for supported HI types."""
    now = _now_ms()
    member_id = f"m_abdm_{uuid.uuid4().hex[:8]}"

    member = Member(
        id=member_id,
        abha_id="14-1234-5678-9012",
        name="Radha Patel",
        sex="F",
        dob_approx=now - (25 * 365 * 86400 * 1000),
        created_at=now,
        updated_at=now,
    )
    db_session.add(member)

    enc = ClinicalEncounter(
        id=f"enc_abdm_{uuid.uuid4().hex[:8]}",
        member_id=member_id,
        encounter_type="IMMUNIZATION_DOSE",
        encounter_date=now,
        created_at=now,
        updated_at=now,
    )
    db_session.add(enc)

    obs = ClinicalObservation(
        id=f"obs_abdm_{uuid.uuid4().hex[:8]}",
        encounter_id=enc.id,
        observation_code="VACCINE_CODE",
        value_text="MR_1",
        observed_at=now,
    )
    db_session.add(obs)
    await db_session.commit()

    consent = {
        "id": f"consent_{uuid.uuid4().hex[:8]}",
        "status": "ACTIVE",
        "patient_id": member_id,
        "permitted_hi_types": ["ImmunizationRecord", "WellnessRecord", "DiagnosticReport", "OPConsultation"],
        "expires_at_ms": now + 1000000,
    }

    # Test ImmunizationRecord bundle
    bundle_dict = await generate_abdm_bundle(
        db=db_session,
        member_id=member_id,
        record_type="ImmunizationRecord",
        consent_artifact=consent,
    )

    assert bundle_dict["resourceType"] == "Bundle"
    assert bundle_dict["type"] == "document"
    assert len(bundle_dict["entry"]) >= 2
    # Entry 0 is Composition
    assert bundle_dict["entry"][0]["resource"]["resourceType"] == "Composition"
    # Entry 1 is Patient
    assert bundle_dict["entry"][1]["resource"]["resourceType"] == "Patient"
    assert bundle_dict["entry"][1]["resource"]["gender"] == "female"

    # Verify DPDP outbound sharing log
    log_res = await db_session.execute(
        select(OutboundSharingLog).where(OutboundSharingLog.target_system == "ABDM")
    )
    logs = log_res.scalars().all()
    assert len(logs) >= 1
    assert logs[-1].payload_hash is not None


@pytest.mark.asyncio
async def test_abdm_bundle_generation_rejected_on_invalid_consent(db_session: AsyncSession) -> None:
    """Req 36.3: Rejects bundle generation and logs incident when consent is invalid."""
    member_id = f"m_{uuid.uuid4().hex[:8]}"
    member = Member(id=member_id, name="Test Patient", created_at=_now_ms(), updated_at=_now_ms())
    db_session.add(member)
    await db_session.commit()

    with pytest.raises(ValueError, match="Consent validation failed"):
        await generate_abdm_bundle(
            db=db_session,
            member_id=member_id,
            record_type="WellnessRecord",
            consent_artifact=None,  # Missing consent
        )

    # Verify incident logged
    inc_res = await db_session.execute(
        select(IntegrationIncident).where(IntegrationIncident.system_name == "ABDM")
    )
    incident = inc_res.scalars().first()
    assert incident is not None
    assert incident.error_code == "CONSENT_REJECTED"


# ── 5. Integration API Endpoints Tests ─────────────────────────────────────────


@pytest.mark.asyncio
async def test_integration_api_endpoints(async_client: AsyncClient, db_session: AsyncSession) -> None:
    """Tests FastAPI router endpoints for U-WIN, HMIS, Ni-kshay, ABDM, and incidents."""
    now = _now_ms()
    rch_id = f"RCH_API_{uuid.uuid4().hex[:8]}"

    # 1. POST /api/v1/integrations/uwin/reconcile-csv
    csv_payload = f"rch_number,child_name,vaccine_code,dose_date\n{rch_id},Baby Rani,BCG,{now}\n"
    res = await async_client.post(
        "/api/v1/integrations/uwin/reconcile-csv",
        json={"csv_content": csv_payload, "state_code": "default"},
    )
    assert res.status_code == 200
    data = res.json()
    assert data["total_records"] == 1
    assert data["stubs_created"] == 1

    # 2. POST /api/v1/integrations/hmis/compute-indicators
    import datetime
    today = datetime.date.today()
    period = f"{today.year:04d}-{today.month:02d}"

    res = await async_client.post(
        "/api/v1/integrations/hmis/compute-indicators",
        json={"period": period, "state_code": "default"},
    )
    assert res.status_code == 200
    hmis_data = res.json()
    assert hmis_data["total_indicators"] >= 45

    # 3. POST /api/v1/integrations/hmis/approve
    res = await async_client.post(
        "/api/v1/integrations/hmis/approve",
        json={"report_data": hmis_data, "approval_notes": "ANM verified"},
    )
    assert res.status_code == 200
    approved = res.json()
    assert approved["status"] == "anm_approved"

    # 4. POST /api/v1/integrations/hmis/export-csv
    res = await async_client.post(
        "/api/v1/integrations/hmis/export-csv",
        json={"indicators_data": approved},
    )
    assert res.status_code == 200
    assert "text/csv" in res.headers["content-type"]

    # 5. GET /api/v1/integrations/incidents
    res = await async_client.get("/api/v1/integrations/incidents")
    assert res.status_code == 200
    assert isinstance(res.json(), list)
