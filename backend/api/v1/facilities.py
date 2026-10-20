"""Healthcare facilities directory API connecting to verified database records."""
from __future__ import annotations

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from db.session import get_db
from models.db.models import FacilityDirectory

router = APIRouter(tags=["facilities"])


@router.get("/facilities")
async def list_facilities(
    district: str | None = Query(None),
    facility_level: str | None = Query(None),
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

    facilities = [
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
        }
        for f in records
    ]

    return {
        "source": "database",
        "count": len(facilities),
        "facilities": facilities,
    }


@router.get("/facilities/dummy")
async def dummy_facilities(db: AsyncSession = Depends(get_db)) -> dict:
    """Backward-compatible route returning real facilities directly from the database."""
    return await list_facilities(district=None, facility_level=None, db=db)
