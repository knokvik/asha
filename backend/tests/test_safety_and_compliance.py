"""Tests for Backend AI Safety and DPDP Compliance Services (Requirements 44, 46)."""

from datetime import datetime

from services.ai_safety_service import (
    BackendAiSafetyService,
    TriageOverrideEvent,
)
from services.dpdp_service import BackendDpdpService


def test_ai_safety_override_metrics_and_alerts():
    safety_service = BackendAiSafetyService(override_threshold=0.20, under_triage_threshold=0.05)
    now = datetime.now()

    # Record 25 overrides for a rule with 100 total evaluations (25% override rate)
    for i in range(25):
        safety_service.record_override_event(
            TriageOverrideEvent(
                event_id=f"ovr_{i}",
                rule_id="RULE_NEONATAL_DANGER",
                language_code="hi",
                area_code="DIST_01",
                asha_cohort="COHORT_A",
                suggested_severity="YELLOW",
                confirmed_severity="RED",
                reason="Lethargy confirmed clinically",
                recorded_at=now,
            )
        )

    metrics = safety_service.compute_rule_metrics("RULE_NEONATAL_DANGER", total_evaluations=100)
    assert metrics["override_rate"] == 0.25
    assert metrics["escalation_rate"] == 0.25
    assert metrics["deescalation_rate"] == 0.0

    # Safety alert triggered due to >= 20% threshold breach
    alert = safety_service.check_safety_thresholds("RULE_NEONATAL_DANGER", total_evaluations=100)
    assert alert is not None
    assert alert.metric_name == "OVERRIDE_RATE"
    assert alert.severity == "WARNING"
    assert "exceeding the safety threshold" in alert.message


def test_ai_safety_under_triage_alert():
    safety_service = BackendAiSafetyService(override_threshold=0.20, under_triage_threshold=0.05)
    now = datetime.now()

    # 10 de-escalations in 100 evaluations = 10% under-triage discordance (> 5% threshold)
    for i in range(10):
        safety_service.record_override_event(
            TriageOverrideEvent(
                event_id=f"ovr_de_{i}",
                rule_id="RULE_MATERNAL_BP",
                language_code="mr",
                area_code="DIST_02",
                asha_cohort="COHORT_B",
                suggested_severity="RED",
                confirmed_severity="YELLOW",
                reason="Repeat BP normal after 15 min rest",
                recorded_at=now,
            )
        )

    alert = safety_service.check_safety_thresholds("RULE_MATERNAL_BP", total_evaluations=100)
    assert alert is not None
    assert alert.metric_name == "UNDER_TRIAGE_DISCORDANCE"
    assert alert.severity == "CRITICAL"


def test_ai_safety_component_killswitch():
    safety_service = BackendAiSafetyService()
    assert safety_service.is_component_enabled("vosk_marathi_v1") is True

    safety_service.disable_component("vosk_marathi_v1", reason="Poor ASR recall on local dialects")
    assert safety_service.is_component_enabled("vosk_marathi_v1") is False


def test_dpdp_sar_lifecycle():
    dpdp = BackendDpdpService()

    sar = dpdp.submit_sar_request(
        beneficiary_id="BEN_1001",
        request_type="ACCESS",
        details="Subject requested immunization card copy",
    )
    assert sar.status == "SUBMITTED"
    assert sar.fulfilled_at is None

    fulfilled = dpdp.fulfill_sar_request(
        sar.request_id,
        resolution_notes="FHIR summary bundle exported to ABDM Gateway",
    )
    assert fulfilled.status == "FULFILLED"
    assert fulfilled.fulfilled_at is not None
    assert "ABDM Gateway" in fulfilled.resolution_notes


def test_dpdp_anomalous_access_detection():
    dpdp = BackendDpdpService(anomaly_window_minutes=5, anomaly_threshold_queries=10)

    # Normal activity (5 queries)
    for i in range(5):
        dpdp.log_access("user_normal", "anm", f"pat_{i}", "routine_care")
    assert dpdp.detect_anomalous_access("user_normal") is None

    # Anomalous activity (12 queries within window)
    for i in range(12):
        dpdp.log_access("user_compromised", "clerk", f"pat_{i}", "bulk_export")

    anomaly = dpdp.detect_anomalous_access("user_compromised")
    assert anomaly is not None
    assert anomaly["alert"] == "ANOMALOUS_DATA_ACCESS"
    assert anomaly["severity"] == "CRITICAL"
    assert anomaly["query_count"] == 12


def test_dpdp_breach_logging_with_cert_in_notice():
    dpdp = BackendDpdpService()

    breach = dpdp.log_breach_incident(
        anomaly_type="CREDENTIAL_STUFFING",
        affected_count=45,
        mitigation_action="IP ranges blocked on Cloudflare WAF and forced password reset",
    )
    assert breach.status == "CONTAINED"
    assert breach.affected_records_count == 45
    assert breach.notified_cert_in_at is not None
