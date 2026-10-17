"""Notification service for dispatching FCM pushes and in-app alerts.

Implements Requirements 10.4, 10.5, 10.6:
- Push notifications to originating ASHA and supervising ANM / AF when referral outcome is recorded.
- Immediate alerts for RED triage referrals and overdue non-arrival follow-ups.
- Maintains in-memory dispatch history for testing and verification.
"""
from __future__ import annotations

import logging
import time
from dataclasses import dataclass, field
from typing import Any

logger = logging.getLogger(__name__)


@dataclass
class DispatchedNotification:
    recipient_id: str
    recipient_role: str | None
    title: str
    body: str
    data: dict[str, Any]
    sent_at: int = field(default_factory=lambda: int(time.time() * 1000))


class NotificationService:
    _dispatched: list[DispatchedNotification] = []

    @classmethod
    def get_dispatched(cls) -> list[DispatchedNotification]:
        return list(cls._dispatched)

    @classmethod
    def clear_dispatched(cls) -> None:
        cls._dispatched.clear()

    @classmethod
    async def send_notification(
        cls,
        recipient_id: str,
        title: str,
        body: str,
        data: dict[str, Any] | None = None,
        recipient_role: str | None = None,
    ) -> DispatchedNotification:
        """Send push notification to device/user (mocked FCM for testing/offline-first)."""
        notif = DispatchedNotification(
            recipient_id=recipient_id,
            recipient_role=recipient_role,
            title=title,
            body=body,
            data=data or {},
        )
        cls._dispatched.append(notif)
        logger.info(
            "FCM Push Dispatched -> %s (%s): %s | %s",
            recipient_id,
            recipient_role,
            title,
            body,
        )
        return notif

    @classmethod
    async def notify_referral_outcome(
        cls,
        referral_id: str,
        patient_name: str,
        outcome: str,
        asha_id: str | None = None,
        block_code: str | None = None,
    ) -> list[DispatchedNotification]:
        """Notify referring ASHA and supervising ANM/AF about hospital referral outcome."""
        notifications = []
        outcome_label = outcome.replace("_", " ").title()

        # 1. Notify originating ASHA
        if asha_id:
            n_asha = await cls.send_notification(
                recipient_id=asha_id,
                recipient_role="ASHA",
                title=f"Referral Outcome: {patient_name}",
                body=f"Patient {patient_name} outcome recorded: {outcome_label}.",
                data={
                    "type": "referral_outcome",
                    "referral_id": referral_id,
                    "outcome": outcome,
                },
            )
            notifications.append(n_asha)

        # 2. Notify supervising ANM / AF
        n_supervisor = await cls.send_notification(
            recipient_id=f"supervisor_{block_code or 'block'}",
            recipient_role="ASHA_FACILITATOR",
            title=f"Referral Outcome Update: {patient_name}",
            body=f"Referral {referral_id} for {patient_name} closed with outcome: {outcome_label}.",
            data={
                "type": "referral_outcome_supervisor",
                "referral_id": referral_id,
                "outcome": outcome,
            },
        )
        notifications.append(n_supervisor)

        return notifications

    @classmethod
    async def notify_non_arrival_overdue(
        cls,
        referral_id: str,
        patient_name: str,
        asha_id: str,
        hours_elapsed: int = 24,
    ) -> list[DispatchedNotification]:
        """Notify ASHA and AF of RED referral non-arrival past threshold window."""
        notifications = []

        # Urgent alert to referring ASHA
        n_asha = await cls.send_notification(
            recipient_id=asha_id,
            recipient_role="ASHA",
            title=f"URGENT: RED Referral Non-Arrival ({patient_name})",
            body=f"Patient {patient_name} has not arrived at designated facility after {hours_elapsed}h. Immediate home visit required.",
            data={
                "type": "red_referral_non_arrival",
                "priority": "URGENT",
                "referral_id": referral_id,
            },
        )
        notifications.append(n_asha)

        # Escalation to ASHA Facilitator
        n_af = await cls.send_notification(
            recipient_id=f"af_supervisor_{asha_id}",
            recipient_role="ASHA_FACILITATOR",
            title=f"ESCALATION: RED Referral Non-Arrival ({patient_name})",
            body=f"High-risk beneficiary {patient_name} referred by ASHA {asha_id} not arrived at facility >{hours_elapsed}h.",
            data={
                "type": "red_referral_non_arrival_escalation",
                "priority": "URGENT",
                "referral_id": referral_id,
                "asha_id": asha_id,
            },
        )
        notifications.append(n_af)

        return notifications
