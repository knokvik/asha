"""Unit tests for Backend SMS Gateway & Beneficiary Reminders (Requirement 26.2, Task 12.1)."""
from __future__ import annotations

import time
import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from models.db.models import Household, Member, VisitSchedule
from services.sms_gateway import SmsGatewayService


@pytest.fixture(autouse=True)
def clean_sms_dispatches():
    SmsGatewayService.clear_dispatched()
    yield
    SmsGatewayService.clear_dispatched()


@pytest.mark.asyncio
async def test_format_reminder_and_send_sms_success():
    msg = SmsGatewayService.format_reminder_text(
        program_code="immunization",
        beneficiary_name="Aarav",
        facility_name="Rampur PHC",
        language="hi",
    )
    assert "टीकाकरण" in msg
    assert "Aarav" in msg

    record = await SmsGatewayService.send_sms(
        to_phone="9876543210",
        message_text=msg,
        language="hi",
        member_id="mem_test_01",
        schedule_id="sched_test_01",
    )

    assert record.to_phone == "9876543210"
    assert record.status == "SENT"
    assert record.channel == "SMS"
    assert len(SmsGatewayService.get_dispatched()) == 1


@pytest.mark.asyncio
async def test_privacy_protection_blocks_sensitive_diagnostics():
    prohibited_messages = [
        "Your tuberculosis sputum test is due today.",
        "Please visit clinic for TB DOTS medicine refill.",
        "Reminder for your HIV treatment consultation.",
        "Your cancer biopsy report is ready.",
    ]

    for prohibited in prohibited_messages:
        with pytest.raises(ValueError, match="Privacy violation"):
            await SmsGatewayService.send_sms(
                to_phone="9876543210",
                message_text=prohibited,
            )

    # Assert none of the prohibited messages were dispatched
    assert len(SmsGatewayService.get_dispatched()) == 0


@pytest.mark.asyncio
async def test_delivery_receipt_recording_and_failure_tracking():
    record = await SmsGatewayService.send_sms(
        to_phone="9812345678",
        message_text="Hello Sunita, your routine maternal health checkup is scheduled tomorrow at PHC.",
        language="en",
    )

    # Ingest delivery receipt
    updated = SmsGatewayService.record_receipt(
        message_id=record.id,
        status="DELIVERED",
    )
    assert updated is not None
    assert updated.status == "DELIVERED"
    assert updated.delivered_at is not None

    # Test failed receipt
    record2 = await SmsGatewayService.send_sms(
        to_phone="9800000000",
        message_text="Hello, your routine checkup is scheduled.",
        language="en",
    )
    failed = SmsGatewayService.record_receipt(
        message_id=record2.id,
        status="FAILED",
        failure_reason="Network unreachable / Subscriber handset switched off",
    )
    assert failed is not None
    assert failed.status == "FAILED"
    assert failed.failure_reason is not None


@pytest.mark.asyncio
async def test_dispatch_due_schedule_reminders_enforces_opt_in_consent(db_session: AsyncSession):
    now = int(time.time() * 1000)

    # 1. Seed Household
    hh = Household(
        id="hh_sms_01",
        village="Rampur",
        head_name="Ram Lal",
        created_at=now,
    )
    db_session.add(hh)

    # 2. Member A: Consented (consent_status == 'granted')
    member_consented = Member(
        id="mem_consented_01",
        household_id="hh_sms_01",
        name="Meena Devi",
        phone="9876543211",
        consent_status="granted",
        lifecycle_status="active",
        created_at=now,
    )
    # 3. Member B: Declined consent (consent_status == 'declined')
    member_declined = Member(
        id="mem_declined_01",
        household_id="hh_sms_01",
        name="Sunita Devi",
        phone="9876543212",
        consent_status="declined",
        lifecycle_status="active",
        created_at=now,
    )
    db_session.add_all([member_consented, member_declined])

    # 4. Visit Schedules for both members due tomorrow
    due_tomorrow_ms = now + (24 * 60 * 60 * 1000)
    sched_a = VisitSchedule(
        id="sched_a_01",
        member_id="mem_consented_01",
        program_code="anc",
        visit_type="ANC Contact 2",
        due_date=due_tomorrow_ms,
        status="pending",
        created_at=now,
    )
    sched_b = VisitSchedule(
        id="sched_b_01",
        member_id="mem_declined_01",
        program_code="anc",
        visit_type="ANC Contact 2",
        due_date=due_tomorrow_ms,
        status="pending",
        created_at=now,
    )
    db_session.add_all([sched_a, sched_b])
    await db_session.commit()

    # 5. Dispatch reminders
    dispatched = await SmsGatewayService.dispatch_due_schedule_reminders(
        db_session=db_session,
        facility_name="Rampur Primary Health Centre",
    )

    # Only member A (consented) should receive reminder
    assert len(dispatched) == 1
    assert dispatched[0].member_id == "mem_consented_01"
    assert dispatched[0].to_phone == "9876543211"
    assert "Meena Devi" in dispatched[0].message_text
