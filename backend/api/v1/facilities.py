"""Healthcare facilities directory API connecting to verified database records."""
from __future__ import annotations

import json

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from db.session import get_db
from models.db.models import FacilityDirectory

router = APIRouter(tags=["facilities"])


def _services(raw: str | None) -> list[str]:
    if not raw:
        return []
    try:
        decoded = json.loads(raw)
    except (TypeError, json.JSONDecodeError):
        return [item.strip() for item in raw.split(",") if item.strip()]
    if isinstance(decoded, list):
        return [str(item) for item in decoded]
    if isinstance(decoded, dict):
        return [f"{key}:yes" for key, value in decoded.items() if value in (True, 1, "yes", "true")]
    return []


def _capability_names(services: list[str]) -> set[str]:
    aliases = {
        "blood": "blood_bank",
        "blood_centre": "blood_bank",
        "blood_center": "blood_bank",
        "delivery": "delivery_room",
        "labour_room": "delivery_room",
        "nutrition_rehabilitation_centre": "nrc",
        "nutrition_rehabilitation_center": "nrc",
        "anti_venom": "antivenom",
        "antivenin": "antivenom",
        "ayushman_arogya_mandir": "ab_hwc",
        "health_and_wellness_centre": "ab_hwc",
        "community_health_officer": "cho",
        "cbac": "ncd_clinic",
        "pm_jay": "pmjay",
        "jan_aushadhi": "janaushadhi",
    }
    result: set[str] = set()
    for service in services:
        value = service.lower().strip().replace(" ", "_").replace("-", "_")
        parts = value.replace("=", ":").split(":", 1)
        if len(parts) == 2 and parts[1] in {"no", "false", "0", "unavailable", "closed"}:
            continue
        key = parts[0]
        if key:
            result.add(aliases.get(key, key))
    return result


@router.get("/facilities")
async def list_facilities(
    district: str | None = Query(None),
    facility_level: str | None = Query(None),
    capability: str | None = Query(None, description="Canonical capability tag, e.g. nrc or blood_bank"),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Return verified healthcare facilities from the database."""
    stmt = select(FacilityDirectory).where(FacilityDirectory.is_active == True)  # noqa: E712
    if district:
        stmt = stmt.where(FacilityDirectory.district == district)
    if facility_level:
        stmt = stmt.where(FacilityDirectory.facility_level == facility_level)

    result = await db.execute(stmt)
    records = result.scalars().all()

    facilities = []
    for f in records:
        services = _services(f.services_json)
        capabilities = sorted(_capability_names(services))
        if capability and capability not in capabilities:
            continue
        facilities.append(
            {
                "id": f.id,
                "name": f.name,
                "kind": f.facility_level,
                "district": f.district,
                "block": f.block,
                "village": f.village,
                "lat": f.latitude,
                "lon": f.longitude,
                "phone": f.contact_phone,
                "services": services,
                "capabilities": capabilities,
                "last_updated_at": f.last_updated_at,
            }
        )

    return {
        "source": "database",
        "count": len(facilities),
        "facilities": facilities,
    }
