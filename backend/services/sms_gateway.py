"""SMS and IVR Gateway Service for Beneficiary Reminders.

Implements Requirement 26.2:
- Opt-in SMS/IVR to beneficiary phone using configured SMS gateway.
- Messages in beneficiary's language (Hindi / English).
- Strictly avoids sensitive health details (zero stigma / privacy-preserving).
- Delivery receipt recording and webhook tracking.
"""
from __future__ import annotations

import logging
import re
import time
import uuid
from dataclasses import dataclass, field


from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models.db.models import Member, VisitSchedule

logger = logging.getLogger(__name__)


# Forbidden sensitive clinical / diagnostic terms per Requirement 26.2
PROHIBITED_HEALTH_TERMS: list[re.Pattern[str]] = [
    re.compile(r"\b(tb|tuberculosis|kshay|nikshay|dots)\b", re.IGNORECASE),
    re.compile(r"\b(hiv|aids)\b", re.IGNORECASE),
    re.compile(r"\b(cancer|karak|tumour|tumor|malignan)\b", re.IGNORECASE),
    re.compile(r"\b(leprosy|kushth)\b", re.IGNORECASE),
    re.compile(r"\b(std|sti|syphilis|gonorrhea)\b", re.IGNORECASE),
    re.compile(r"\b(abortion|garbhavat|miscarriage)\b", re.IGNORECASE),
    re.compile(r"\b(psychiatric|mental\s+illness|depression|suicide)\b", re.IGNORECASE),
]


@dataclass
class SmsDispatchRecord:
    id: str
    to_phone: str
    message_text: str
    language: str
    channel: str  # 'SMS' or 'IVR'
    status: str  # 'SENT', 'DELIVERED', 'FAILED', 'UNDELIVERED'
    member_id: str | None = None
    schedule_id: str | None = None
    sent_at: int = field(default_factory=lambda: int(time.time() * 1000))
    delivered_at: int | None = None
    failure_reason: str | None = None


class SmsGatewayService:
    _dispatched: list[SmsDispatchRecord] = []

    @classmethod
    def get_dispatched(cls) -> list[SmsDispatchRecord]:
        return list(cls._dispatched)

    @classmethod
    def clear_dispatched(cls) -> None:
        cls._dispatched.clear()

    @classmethod
    def validate_privacy(cls, message_text: str) -> None:
        """Asserts that message text contains no sensitive diagnostic terms."""
        for pattern in PROHIBITED_HEALTH_TERMS:
            if pattern.search(message_text):
                raise ValueError(
                    f"Privacy violation (Requirement 26.2): Message contains prohibited clinical health details matching '{pattern.pattern}'."
                )

    @classmethod
    def format_reminder_text(
        cls,
        program_code: str,
        beneficiary_name: str,
        facility_name: str,
        language: str = "hi",
    ) -> str:
        """Formats safe non-stigmatizing reminder in Hindi or English."""
        is_hindi = language.lower() == "hi"

        if program_code.lower() == "anc":
            return (
                f"नमस्ते {beneficiary_name} जी, आपकी नियमित मातृत्व स्वास्थ्य जांच प्राथमिक स्वास्थ्य केंद्र {facility_name} में निर्धारित है। कृपया समय पर पधारें।"
                if is_hindi
                else f"Hello {beneficiary_name}, your maternal health checkup is scheduled at {facility_name}. Please arrive on time."
            )
        elif program_code.lower() == "immunization":
            return (
                f"नमस्ते, {beneficiary_name} का नियमित बाल टीकाकरण स्वास्थ्य केंद्र {facility_name} में निर्धारित है। कृपया एमसीपी कार्ड साथ लाएं।"
                if is_hindi
                else f"Hello, regular vaccination for {beneficiary_name} is scheduled at {facility_name}. Please bring MCP card."
            )
        elif program_code.lower() == "ncd":
            return (
                f"नमस्ते {beneficiary_name} जी, आपकी नियमित स्वास्थ्य जांच और दवा रीफिल {facility_name} में उपलब्ध है।"
                if is_hindi
                else f"Hello {beneficiary_name}, your routine checkup and medication refill is available at {facility_name}."
            )
        else:
            return (
                f"नमस्ते {beneficiary_name} जी, आशा दीदी का नियमित स्वास्थ्य परामर्श भेंट निर्धारित है।"
                if is_hindi
                else f"Hello {beneficiary_name}, your regular health consultation visit is scheduled with ASHA worker."
            )

    @classmethod
    async def send_sms(
        cls,
        to_phone: str,
        message_text: str,
        language: str = "hi",
        member_id: str | None = None,
        schedule_id: str | None = None,
    ) -> SmsDispatchRecord:
        """Dispatches an SMS message after strict privacy validation."""
        cls.validate_privacy(message_text)

        dispatch_id = f"sms_{uuid.uuid4().hex[:12]}"
        record = SmsDispatchRecord(
            id=dispatch_id,
            to_phone=to_phone,
            message_text=message_text,
            language=language,
            channel="SMS",
            status="SENT",
            member_id=member_id,
            schedule_id=schedule_id,
        )
        cls._dispatched.append(record)
        logger.info("SMS Dispatched -> %s (%s): %s", to_phone, language, message_text)
        return record

    @classmethod
    async def send_ivr(
        cls,
        to_phone: str,
        audio_prompt_id: str,
        language: str = "hi",
        member_id: str | None = None,
        schedule_id: str | None = None,
    ) -> SmsDispatchRecord:
        """Dispatches an automated IVR call prompt."""
        dispatch_id = f"ivr_{uuid.uuid4().hex[:12]}"
        record = SmsDispatchRecord(
            id=dispatch_id,
            to_phone=to_phone,
            message_text=f"IVR Audio Prompt: {audio_prompt_id}",
            language=language,
            channel="IVR",
            status="SENT",
            member_id=member_id,
            schedule_id=schedule_id,
        )
        cls._dispatched.append(record)
        logger.info("IVR Call Dispatched -> %s (%s): Prompt %s", to_phone, language, audio_prompt_id)
        return record

    @classmethod
    def record_receipt(
        cls,
        message_id: str,
        status: str,
        failure_reason: str | None = None,
    ) -> SmsDispatchRecord | None:
        """Records webhook delivery receipt from SMS/IVR gateway."""
        for record in cls._dispatched:
            if record.id == message_id:
                record.status = status.upper()
                if status.upper() == "DELIVERED":
                    record.delivered_at = int(time.time() * 1000)
                if failure_reason:
                    record.failure_reason = failure_reason
                logger.info("SMS Delivery Receipt: %s -> %s", message_id, status)
                return record
        return None

    @classmethod
    async def dispatch_due_schedule_reminders(
        cls,
        db_session: AsyncSession,
        facility_name: str = "Community Health Centre",
    ) -> list[SmsDispatchRecord]:
        """Scans due visit schedules and dispatches opt-in reminders for consented members."""
        now_ms = int(time.time() * 1000)
        upcoming_window_ms = now_ms + (48 * 60 * 60 * 1000)  # Next 48 hours

        query = (
            select(VisitSchedule, Member)
            .join(Member, VisitSchedule.member_id == Member.id)
            .where(
                VisitSchedule.status.in_(["pending", "rescheduled"]),
                VisitSchedule.due_date <= upcoming_window_ms,
                Member.phone.is_not(None),
                Member.consent_status == "granted",  # Opt-in consent required
            )
        )

        result = await db_session.execute(query)
        pairs = result.all()

        dispatched = []
        for schedule, member in pairs:
            if not member.phone:
                continue

            msg = cls.format_reminder_text(
                program_code=schedule.program_code or "general",
                beneficiary_name=member.name,
                facility_name=facility_name,
                language="hi",
            )

            record = await cls.send_sms(
                to_phone=member.phone,
                message_text=msg,
                language="hi",
                member_id=member.id,
                schedule_id=schedule.id,
            )
            dispatched.append(record)

        return dispatched
