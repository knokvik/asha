"""Seed two PCMC context packs and one overdue red ticket.

Pack v1 keeps the dengue cluster in W3. Pack v2 moves it to W5.
Run from backend/: python -m scripts.seed_triage_loop
"""
from __future__ import annotations

import asyncio
from datetime import datetime, timedelta

from db.session import AsyncSessionLocal
from services.triage_desk import TriageDesk


async def main() -> None:
    async with AsyncSessionLocal() as session:
        desk = TriageDesk(session)
        await desk.seed_demo_packs()
        created = (datetime.utcnow() - timedelta(hours=5)).isoformat()
        await desk.accept_batch(
            [
                {
                    "type": "referral",
                    "idempotency_key": "seed-red-w3",
                    "payload": {
                        "referral_id": "CASE-W3-RED-OLD",
                        "priority": "RED",
                        "ward_id": "W3",
                        "district_id": "PCMC",
                        "asha_id": "ASHA-SUNITA",
                        "created_at": created,
                        "flag": "RED",
                        "fired_rules": ["DS-CONV"],
                    },
                }
            ]
        )
        print("seeded PCMC packs v1 (W3) and v2 (W5), plus CASE-W3-RED-OLD")


if __name__ == "__main__":
    asyncio.run(main())
