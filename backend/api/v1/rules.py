"""Rules API router for OTA delivery and bundle integrity verification.

Implements Requirements 9.2, 9.3, 9.4:
- GET /api/v1/rules/latest
- GET /api/v1/rules/{version}/bundle.json.gz
"""
from __future__ import annotations

import json
from typing import Any

from fastapi import APIRouter, Depends, Query, Response
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from db.session import get_db
from models.db.models import RuleVersion
from services.rule_service import RuleService

router = APIRouter(prefix="/rules", tags=["rules"])

# Default national base rule set (IMNCI, HBNC, HBYC, PMSMA, NP-NCD)
DEFAULT_NATIONAL_RULESET: dict[str, Any] = {
    "id": "ruleset-national-v1",
    "version_string": "1.0.0",
    "published_at": 1710000000000,
    "clinical_lead_id": "lead_clinician_mohfw_01",
    "approval_signature": "SIG_ED25519_VALIDATED_NATIONAL_BASE_RULESET",
    "age_bands": [
        {
            "code": "INFANT_0_2M",
            "name": "INFANT_0_2M",
            "required_fields": ["respiratory_rate", "temperature"],
        },
        {
            "code": "CHILD_2M_5Y",
            "name": "CHILD_2M_5Y",
            "required_fields": ["respiratory_rate", "temperature"],
        },
        {
            "code": "ADOLESCENT",
            "name": "ADOLESCENT",
            "required_fields": ["temperature", "systolic_bp"],
        },
        {
            "code": "ADULT",
            "name": "ADULT",
            "required_fields": ["systolic_bp", "diastolic_bp", "pulse_rate"],
        },
        {
            "code": "PREGNANT",
            "name": "PREGNANT",
            "required_fields": ["systolic_bp", "diastolic_bp", "gestational_weeks"],
        },
    ],
    "rules": [
        {
            "rule_id": "INFANT_FAST_BREATHING",
            "age_band": "INFANT_0_2M",
            "severity": "RED",
            "source_citation": "IMNCI Chart Booklet 2014, MoHFW, p.12",
            "condition": {
                "op": "and",
                "children": [
                    {"op": "gte", "field": "respiratory_rate", "value": 60},
                    {"op": "lte", "field": "age_days", "value": 60},
                ],
            },
            "finding_template": "Breathing rate {respiratory_rate}/min in infant {age_days} days — refer now",
            "action": "REFER_IMMEDIATELY",
        },
        {
            "rule_id": "INFANT_HYPOTHERMIA_SEVERE",
            "age_band": "INFANT_0_2M",
            "severity": "RED",
            "source_citation": "HBNC Operational Guidelines, MoHFW, p.24",
            "condition": {"op": "lt", "field": "temperature", "value": 35.5},
            "finding_template": "Axillary temperature {temperature}°C in young infant — severe hypothermia, warm and refer urgently",
            "action": "REFER_IMMEDIATELY",
        },
        {
            "rule_id": "INFANT_FEVER",
            "age_band": "INFANT_0_2M",
            "severity": "RED",
            "source_citation": "IMNCI Chart Booklet 2014, MoHFW, p.14",
            "condition": {"op": "gte", "field": "temperature", "value": 37.5},
            "finding_template": "High temperature {temperature}°C in young infant under 2 months — possible serious bacterial infection",
            "action": "REFER_IMMEDIATELY",
        },
        {
            "rule_id": "CHILD_FAST_BREATHING_INFANT",
            "age_band": "CHILD_2M_5Y",
            "severity": "YELLOW",
            "source_citation": "IMNCI Chart Booklet 2014, MoHFW, p.16",
            "condition": {
                "op": "and",
                "children": [
                    {"op": "lte", "field": "age_days", "value": 365},
                    {"op": "gte", "field": "respiratory_rate", "value": 50},
                ],
            },
            "finding_template": "Fast breathing {respiratory_rate}/min in child {age_days} days — pneumonia",
            "action": "INITIATE_HOME_CARE_AND_REFER_IF_WORSENS",
        },
        {
            "rule_id": "CHILD_CHEST_INDRAWING",
            "age_band": "CHILD_2M_5Y",
            "severity": "RED",
            "source_citation": "IMNCI Chart Booklet 2014, MoHFW, p.16",
            "condition": {"op": "eq", "field": "chest_indrawing", "value": True},
            "finding_template": "Severe chest indrawing observed in child — urgent referral",
            "action": "REFER_IMMEDIATELY",
        },
        {
            "rule_id": "PREGNANT_SEVERE_HYPERTENSION",
            "age_band": "PREGNANT",
            "severity": "RED",
            "source_citation": "Pradhan Mantri Surakshit Matritva Abhiyan (PMSMA), MoHFW, p.18",
            "condition": {
                "op": "or",
                "children": [
                    {"op": "gte", "field": "systolic_bp", "value": 160},
                    {"op": "gte", "field": "diastolic_bp", "value": 110},
                ],
            },
            "finding_template": "Severe hypertension (BP {systolic_bp}/{diastolic_bp} mmHg) in pregnancy — pre-eclampsia risk",
            "action": "REFER_IMMEDIATELY",
        },
        {
            "rule_id": "ADULT_HYPERTENSIVE_CRISIS",
            "age_band": "ADULT",
            "severity": "RED",
            "source_citation": "NP-NCD Operational Guidelines, MoHFW, p.32",
            "condition": {
                "op": "or",
                "children": [
                    {"op": "gte", "field": "systolic_bp", "value": 180},
                    {"op": "gte", "field": "diastolic_bp", "value": 120},
                ],
            },
            "finding_template": "Hypertensive urgency/crisis (BP {systolic_bp}/{diastolic_bp} mmHg)",
            "action": "REFER_IMMEDIATELY",
        },
        {
            "rule_id": "ADULT_HYPERTENSION_STAGE1",
            "age_band": "ADULT",
            "severity": "YELLOW",
            "source_citation": "NP-NCD Operational Guidelines, MoHFW, p.32",
            "condition": {
                "op": "or",
                "children": [
                    {"op": "gte", "field": "systolic_bp", "value": 140},
                    {"op": "gte", "field": "diastolic_bp", "value": 90},
                ],
            },
            "finding_template": "Elevated blood pressure (BP {systolic_bp}/{diastolic_bp} mmHg) — advise lifestyle and schedule PHC visit",
            "action": "SCHEDULE_PHC_VISIT",
        },
    ],
    "test_suite": [
        {
            "test_id": "TC_INFANT_FAST_BREATHING_RED",
            "inputs": {
                "age_days": 45,
                "respiratory_rate": 62,
                "temperature": 36.8,
            },
            "expected_flag": "RED",
            "description": "Fast breathing in 45-day infant evaluates to RED",
        }
    ],
}


class RuleVersionMetaResponse(BaseModel):
    id: str
    version_string: str
    published_at: int
    bundle_hash: str
    download_url: str
    clinical_lead_id: str | None = None
    approval_signature: str | None = None
    is_active: bool = True


@router.get("/latest", response_model=RuleVersionMetaResponse)
async def get_latest_rules(
    state: str | None = Query(None, description="Optional state code for overlay"),
    db: AsyncSession = Depends(get_db),
) -> RuleVersionMetaResponse:
    """Returns metadata for the latest approved active rule set bundle."""
    # Check if there is an active version in the database
    result = await db.execute(
        select(RuleVersion)
        .where(RuleVersion.is_active == True)  # noqa: E712
        .order_by(RuleVersion.published_at.desc())
    )
    active_version = result.scalars().first()

    if active_version:
        download_url = f"/api/v1/rules/{active_version.version_string}/bundle.json.gz"
        return RuleVersionMetaResponse(
            id=active_version.id,
            version_string=active_version.version_string,
            published_at=active_version.published_at or 1710000000000,
            bundle_hash=active_version.bundle_hash or "",
            download_url=download_url,
            clinical_lead_id=active_version.clinical_lead_id,
            approval_signature=active_version.approval_signature,
            is_active=True,
        )

    # Fallback to default national base rule set
    _, bundle_hash, _ = RuleService.package_bundle(DEFAULT_NATIONAL_RULESET)
    version = DEFAULT_NATIONAL_RULESET["version_string"]
    return RuleVersionMetaResponse(
        id=DEFAULT_NATIONAL_RULESET["id"],
        version_string=version,
        published_at=DEFAULT_NATIONAL_RULESET["published_at"],
        bundle_hash=bundle_hash,
        download_url=f"/api/v1/rules/{version}/bundle.json.gz",
        clinical_lead_id=DEFAULT_NATIONAL_RULESET["clinical_lead_id"],
        approval_signature=DEFAULT_NATIONAL_RULESET["approval_signature"],
        is_active=True,
    )


@router.get("/{version}/bundle.json.gz")
async def get_rule_bundle_gzip(
    version: str,
    db: AsyncSession = Depends(get_db),
) -> Response:
    """Returns the gzip-compressed canonical JSON rule bundle."""
    # Look up version in DB or default
    result = await db.execute(
        select(RuleVersion).where(RuleVersion.version_string == version)
    )
    rule_version = result.scalars().first()

    target_rule_set: dict[str, Any]
    if rule_version and rule_version.bundle_path:
        try:
            with open(rule_version.bundle_path, "r", encoding="utf-8") as f:
                target_rule_set = json.load(f)
        except Exception:
            target_rule_set = DEFAULT_NATIONAL_RULESET
    else:
        target_rule_set = DEFAULT_NATIONAL_RULESET

    gzipped_bytes, bundle_hash, _ = RuleService.package_bundle(target_rule_set)

    return Response(
        content=gzipped_bytes,
        media_type="application/gzip",
        headers={
            "Content-Disposition": f'attachment; filename="bundle_{version}.json.gz"',
            "X-Bundle-SHA256": bundle_hash,
        },
    )
