"""ABDM (Ayushman Bharat Digital Mission) FHIR R4 Bundling & Consent Validation Worker.

Implements Requirement 35 (35.1, 35.5, 35.7), Requirement 36 (36.1, 36.2, 36.3), and Task 13.6:
- Generates standard FHIR R4 bundles for ABDM health information types:
  1. WellnessRecord (CBAC, vitals, nutrition)
  2. ImmunizationRecord (U-WIN & local childhood/maternal vaccines)
  3. OPConsultation (ANC/PNC/NCD consultation and clinical notes)
  4. DiagnosticReport (Lab results: Sputum, Blood Glucose, Hemoglobin)
- Validates ABDM Consent Artifact (scope, expiry, permitted HI types, status).
- Enforces DPDP accountability by logging all outbound record exchanges to OutboundSharingLog.
- Logs consent violations and processing failures to IntegrationIncident without blocking primary sync.
"""
from __future__ import annotations

from datetime import datetime, timezone
import hashlib
import json
import logging
from pathlib import Path
import time
import uuid
from typing import Any

from fhir.resources.bundle import Bundle, BundleEntry
from fhir.resources.codeableconcept import CodeableConcept
from fhir.resources.coding import Coding
from fhir.resources.composition import Composition, CompositionSection
from fhir.resources.diagnosticreport import DiagnosticReport
from fhir.resources.encounter import Encounter
from fhir.resources.humanname import HumanName
from fhir.resources.identifier import Identifier
from fhir.resources.immunization import Immunization
from fhir.resources.meta import Meta
from fhir.resources.observation import Observation
from fhir.resources.patient import Patient
from fhir.resources.reference import Reference
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models.db.models import (
    ClinicalEncounter,
    ClinicalObservation,
    IntegrationIncident,
    Member,
    OutboundSharingLog,
)

logger = logging.getLogger(__name__)

MAPPINGS_DIR = Path(__file__).resolve().parent.parent / "config" / "mappings"


def _now_ms() -> int:
    return int(time.time() * 1000)


def _iso_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_abdm_mapping(state_code: str = "default") -> dict[str, Any]:
    """Loads ABDM profile mappings and system URIs."""
    mapping_file = MAPPINGS_DIR / "abdm_mapping.json"
    if mapping_file.exists():
        with open(mapping_file, encoding="utf-8") as f:
            return json.load(f)

    return {
        "profiles": {
            "WellnessRecord": {"bundle_profile": "https://nrces.in/ndhm/fhir/r4/StructureDefinition/WellnessRecord"},
            "ImmunizationRecord": {"bundle_profile": "https://nrces.in/ndhm/fhir/r4/StructureDefinition/ImmunizationRecord"},
            "OPConsultation": {"bundle_profile": "https://nrces.in/ndhm/fhir/r4/StructureDefinition/OPConsultationRecord"},
            "DiagnosticReport": {"bundle_profile": "https://nrces.in/ndhm/fhir/r4/StructureDefinition/DiagnosticReportRecord"},
        },
        "code_systems": {
            "snomed": "http://snomed.info/sct",
            "loinc": "http://loinc.org",
            "abha_id": "https://healthid.ndhm.gov.in",
        },
    }


def validate_consent_artifact(
    consent: dict[str, Any] | None,
    requested_record_type: str,
    member_id: str | None = None,
) -> tuple[bool, str]:
    """Validates an ABDM Consent Manager artifact against the requested health record (Req 36.3).

    Checks:
    - Consent existence and non-empty status.
    - Consent status is 'ACTIVE' or 'GRANTED'.
    - Expiry timestamp has not elapsed.
    - Requested HI type is in the consent artifact's permitted HI types.
    - Patient / Member identifier matches if specified.

    Returns:
        (is_valid, message_or_rejection_reason)
    """
    if not consent:
        return False, "Missing consent artifact. Explicit beneficiary consent required under ABDM & DPDP."

    status = str(consent.get("status", "")).upper()
    if status not in ("ACTIVE", "GRANTED"):
        return False, f"Consent status is '{status}'. Only ACTIVE or GRANTED consent can be honored."

    now = _now_ms()
    expires_at = consent.get("expires_at_ms") or consent.get("data_erase_at_ms")
    if expires_at is not None:
        try:
            if int(expires_at) < now:
                return False, f"Consent artifact expired at timestamp {expires_at} (current: {now})."
        except (ValueError, TypeError):
            pass

    # Validate HI types scope
    permitted_hi_types = consent.get("hi_types") or consent.get("permitted_hi_types") or []
    if not isinstance(permitted_hi_types, list):
        permitted_hi_types = [str(permitted_hi_types)]

    permitted_upper = [t.upper() for t in permitted_hi_types]
    if requested_record_type.upper() not in permitted_upper and "ALL" not in permitted_upper:
        return (
            False,
            f"Requested record type '{requested_record_type}' not in consent scope {permitted_hi_types}.",
        )

    # Validate patient binding if specified
    patient_id = consent.get("patient_id") or consent.get("member_id") or consent.get("abha_id")
    if patient_id and member_id and patient_id != member_id:
        return (
            False,
            f"Consent patient binding mismatch (consent: {patient_id}, requested: {member_id}).",
        )

    return True, "Consent verified successfully."


def _clean_fhir_id(raw_id: str) -> str:
    r"""Sanitizes an internal database ID to be a compliant FHIR ID matching regex ^[A-Za-z0-9\-.]+$."""
    import re

    cleaned = re.sub(r"[^A-Za-z0-9\-.]", "-", str(raw_id))
    return cleaned[:60]


def _build_patient_resource(member: Member, mapping: dict[str, Any]) -> Patient:
    """Builds an ABDM-compliant FHIR Patient resource from a Member."""
    identifiers: list[Identifier] = []

    if member.abha_id:
        identifiers.append(
            Identifier(
                system=mapping.get("code_systems", {}).get("abha_id", "https://healthid.ndhm.gov.in"),
                value=member.abha_id,
            )
        )
    if member.rch_id:
        identifiers.append(
            Identifier(
                system=mapping.get("code_systems", {}).get("rch_id", "https://rch.nhm.gov.in"),
                value=member.rch_id,
            )
        )
    identifiers.append(
        Identifier(
            system="https://platform.ashasetu.in/members",
            value=member.id,
        )
    )

    gender_map = {"M": "male", "F": "female", "O": "other"}
    gender = gender_map.get(str(member.sex).upper() if member.sex else "", "unknown")

    birth_date_str = None
    if member.dob_approx:
        dt = datetime.fromtimestamp(member.dob_approx / 1000, tz=timezone.utc)
        birth_date_str = dt.strftime("%Y-%m-%d")

    return Patient(
        id=f"Patient-{_clean_fhir_id(member.id)}",
        identifier=identifiers,
        name=[HumanName(text=member.name or "Beneficiary")],
        gender=gender,
        birthDate=birth_date_str,
        active=True,
    )


async def generate_abdm_bundle(
    db: AsyncSession,
    member_id: str,
    record_type: str,
    consent_artifact: dict[str, Any] | None = None,
    requested_by: str = "SYSTEM_ABDM_SYNC",
) -> dict[str, Any]:
    """Generates an ABDM-compliant FHIR R4 Bundle for the requested record type (Req 36.2).

    Honors consent scope and expiry (Req 36.3) and logs outbound sharing (Req 35.7).
    Supported record_types: 'WellnessRecord', 'ImmunizationRecord', 'OPConsultation', 'DiagnosticReport'.
    """
    now = _now_ms()
    mapping = load_abdm_mapping()

    # 1. Validate Consent Artifact (Req 36.3)
    is_valid, reason = validate_consent_artifact(consent_artifact, record_type, member_id)
    if not is_valid:
        # Log integration incident (Req 35.5)
        incident = IntegrationIncident(
            id=f"inc_{uuid.uuid4().hex[:12]}",
            system_name="ABDM",
            record_type=record_type,
            external_id=member_id,
            error_code="CONSENT_REJECTED",
            error_message=f"ABDM sharing rejected: {reason}",
            raw_payload=json.dumps(consent_artifact or {}),
            status="open",
            created_at=now,
        )
        db.add(incident)
        await db.commit()
        raise ValueError(f"Consent validation failed: {reason}")

    # 2. Fetch Beneficiary Member
    stmt = select(Member).where(Member.id == member_id)
    res = await db.execute(stmt)
    member = res.scalar_one_or_none()
    if not member:
        raise ValueError(f"Member with ID '{member_id}' not found.")

    patient_res = _build_patient_resource(member, mapping)
    patient_ref = Reference(reference=f"Patient/{patient_res.id}", display=member.name or "Beneficiary")

    # 3. Fetch Encounters & Observations
    enc_stmt = (
        select(ClinicalEncounter)
        .where(ClinicalEncounter.member_id == member.id)
        .order_by(ClinicalEncounter.encounter_date.desc())
    )
    enc_res = await db.execute(enc_stmt)
    encounters = enc_res.scalars().all()

    profile_info = mapping.get("profiles", {}).get(record_type, {})
    bundle_profile_url = profile_info.get(
        "bundle_profile", f"https://nrces.in/ndhm/fhir/r4/StructureDefinition/{record_type}"
    )
    comp_code = profile_info.get("composition_type_code", "86470-3")
    comp_display = profile_info.get("composition_type_display", record_type)

    bundle_id = f"bundle-{record_type.lower()}-{uuid.uuid4().hex[:12]}"
    comp_id = f"comp-{record_type.lower()}-{uuid.uuid4().hex[:12]}"

    composition = Composition(
        id=comp_id,
        status="final",
        type=CodeableConcept(
            coding=[
                Coding(
                    system=mapping.get("code_systems", {}).get("loinc", "http://loinc.org"),
                    code=comp_code,
                    display=comp_display,
                )
            ],
            text=comp_display,
        ),
        subject=[patient_ref],
        date=_iso_now(),
        author=[Reference(reference=f"Practitioner/{_clean_fhir_id(member.created_by or 'ASHA-WORKER')}", display="Health Worker")],
        title=f"{record_type} for {member.name or 'Beneficiary'}",
        section=[],
    )

    entries: list[BundleEntry] = [
        BundleEntry(fullUrl=f"Composition/{comp_id}", resource=composition),
        BundleEntry(fullUrl=f"Patient/{patient_res.id}", resource=patient_res),
    ]

    section_entries: list[Reference] = []

    # 4. Build HI-Type Specific FHIR Resources
    if record_type == "ImmunizationRecord":
        for enc in encounters:
            if enc.encounter_type == "IMMUNIZATION_DOSE" or enc.program_code == "immunization":
                obs_stmt = select(ClinicalObservation).where(ClinicalObservation.encounter_id == enc.id)
                obs_res = await db.execute(obs_stmt)
                obs_dict = {o.observation_code: o.value_text for o in obs_res.scalars().all()}

                v_code = obs_dict.get("VACCINE_CODE", "VACCINE")
                imm_id = f"imm-{_clean_fhir_id(enc.id)}"
                imm = Immunization(
                    id=imm_id,
                    status="completed",
                    vaccineCode=CodeableConcept(text=v_code),
                    patient=patient_ref,
                    occurrenceDateTime=datetime.fromtimestamp(enc.encounter_date / 1000, tz=timezone.utc).isoformat(),
                    lotNumber=obs_dict.get("BATCH_NUMBER"),
                )
                entries.append(BundleEntry(fullUrl=f"Immunization/{imm_id}", resource=imm))
                section_entries.append(Reference(reference=f"Immunization/{imm_id}"))

    elif record_type == "DiagnosticReport":
        diag_id = f"diag-{uuid.uuid4().hex[:12]}"
        result_refs: list[Reference] = []

        for enc in encounters:
            obs_stmt = select(ClinicalObservation).where(ClinicalObservation.encounter_id == enc.id)
            obs_res = await db.execute(obs_stmt)
            for obs in obs_res.scalars().all():
                if obs.observation_code in ("HAEMOGLOBIN", "SPUTUM_TEST", "BLOOD_GLUCOSE", "NIKSHAY_ID"):
                    o_id = f"obs-diag-{_clean_fhir_id(obs.id)}"
                    f_obs = Observation(
                        id=o_id,
                        status="final",
                        code=CodeableConcept(text=obs.observation_code),
                        subject=patient_ref,
                        valueString=obs.value_text if obs.value_text else str(obs.value_numeric),
                    )
                    entries.append(BundleEntry(fullUrl=f"Observation/{o_id}", resource=f_obs))
                    result_refs.append(Reference(reference=f"Observation/{o_id}"))

        diag_report = DiagnosticReport(
            id=diag_id,
            status="final",
            code=CodeableConcept(text="Laboratory & Diagnostic Study Report"),
            subject=patient_ref,
            result=result_refs,
        )
        entries.append(BundleEntry(fullUrl=f"DiagnosticReport/{diag_id}", resource=diag_report))
        section_entries.append(Reference(reference=f"DiagnosticReport/{diag_id}"))

    elif record_type == "OPConsultation":
        for enc in encounters[:5]:  # include latest consultations
            enc_fhir_id = f"enc-{_clean_fhir_id(enc.id)}"
            fhir_enc = Encounter(
                id=enc_fhir_id,
                status="completed",
                class_fhir=[
                    CodeableConcept(
                        coding=[
                            Coding(system="http://terminology.hl7.org/CodeSystem/v3-ActCode", code="AMB", display="ambulatory")
                        ]
                    )
                ],
                subject=patient_ref,
                actualPeriod={
                    "start": datetime.fromtimestamp(enc.encounter_date / 1000, tz=timezone.utc).isoformat(),
                },
            )
            entries.append(BundleEntry(fullUrl=f"Encounter/{enc_fhir_id}", resource=fhir_enc))
            section_entries.append(Reference(reference=f"Encounter/{enc_fhir_id}"))

    else:  # WellnessRecord
        for enc in encounters[:5]:
            obs_stmt = select(ClinicalObservation).where(ClinicalObservation.encounter_id == enc.id)
            obs_res = await db.execute(obs_stmt)
            for obs in obs_res.scalars().all():
                o_id = f"obs-well-{_clean_fhir_id(obs.id)}"
                f_obs = Observation(
                    id=o_id,
                    status="final",
                    code=CodeableConcept(text=obs.observation_code),
                    subject=patient_ref,
                    valueString=obs.value_text if obs.value_text else str(obs.value_numeric),
                )
                entries.append(BundleEntry(fullUrl=f"Observation/{o_id}", resource=f_obs))
                section_entries.append(Reference(reference=f"Observation/{o_id}"))

    # Link section entries into Composition
    composition.section = [
        CompositionSection(
            title=f"{record_type} Entries",
            entry=section_entries,
        )
    ]

    # 5. Assemble Bundle
    bundle = Bundle(
        id=bundle_id,
        meta=Meta(profile=[bundle_profile_url]),
        type="document",
        timestamp=_iso_now(),
        entry=entries,
    )

    bundle_json_str = bundle.json()
    bundle_dict = json.loads(bundle_json_str)
    payload_hash = hashlib.sha256(bundle_json_str.encode("utf-8")).hexdigest()

    # 6. Log outbound sharing event to OutboundSharingLog for DPDP accountability (Req 35.7)
    sharing_log = OutboundSharingLog(
        id=f"share_abdm_{uuid.uuid4().hex[:12]}",
        target_system="ABDM",
        record_type=record_type,
        record_id=member.id,
        recipient="ABDM Consent Manager / HIU",
        consent_artifact_id=consent_artifact.get("id") if consent_artifact else None,
        payload_hash=payload_hash,
        shared_by=requested_by,
        status="success",
        created_at=now,
    )
    db.add(sharing_log)
    await db.commit()

    logger.info("Generated ABDM FHIR bundle %s for member %s (hash: %s)", bundle_id, member_id, payload_hash)
    return bundle_dict
