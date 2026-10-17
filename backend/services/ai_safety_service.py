"""AI Clinical Safety, Human Oversight, and Monitoring Service (Requirement 46)."""

from __future__ import annotations
from dataclasses import dataclass
from datetime import datetime
from typing import Dict, List, Optional


@dataclass
class ClinicalSafetyAlert:
    alert_id: str
    rule_id: str
    metric_name: str
    observed_value: float
    threshold_value: float
    cohort_or_area: str
    severity: str  # 'WARNING', 'CRITICAL'
    triggered_at: datetime
    message: str


@dataclass
class TriageOverrideEvent:
    event_id: str
    rule_id: str
    language_code: str
    area_code: str
    asha_cohort: str
    suggested_severity: str  # 'GREEN', 'YELLOW', 'RED'
    confirmed_severity: str  # 'GREEN', 'YELLOW', 'RED'
    reason: str
    recorded_at: datetime


class BackendAiSafetyService:
    """Computes AI clinical safety metrics, override rates, and safety alerts."""

    def __init__(self, override_threshold: float = 0.20, under_triage_threshold: float = 0.05):
        self.override_threshold = override_threshold
        self.under_triage_threshold = under_triage_threshold
        self._override_events: List[TriageOverrideEvent] = []
        self._disabled_components: Dict[str, str] = {}
        self._incident_reports: List[Dict] = []

    def record_override_event(self, event: TriageOverrideEvent) -> None:
        self._override_events.append(event)

    def compute_rule_metrics(
        self,
        rule_id: str,
        total_evaluations: int,
    ) -> Dict[str, float]:
        """Calculates override rate, escalation rate, and de-escalation rate for a clinical rule (Req 46.3)."""
        rule_events = [e for e in self._override_events if e.rule_id == rule_id]
        if total_evaluations <= 0:
            return {
                "override_rate": 0.0,
                "escalation_rate": 0.0,
                "deescalation_rate": 0.0,
                "total_overrides": len(rule_events),
            }

        severity_ranks = {"GREEN": 1, "YELLOW": 2, "RED": 3}
        escalations = sum(
            1
            for e in rule_events
            if severity_ranks.get(e.confirmed_severity, 1) > severity_ranks.get(e.suggested_severity, 1)
        )
        deescalations = sum(
            1
            for e in rule_events
            if severity_ranks.get(e.confirmed_severity, 1) < severity_ranks.get(e.suggested_severity, 1)
        )

        override_rate = len(rule_events) / total_evaluations
        escalation_rate = escalations / total_evaluations
        deescalation_rate = deescalations / total_evaluations

        return {
            "override_rate": round(override_rate, 4),
            "escalation_rate": round(escalation_rate, 4),
            "deescalation_rate": round(deescalation_rate, 4),
            "total_overrides": len(rule_events),
        }

    def check_safety_thresholds(
        self,
        rule_id: str,
        total_evaluations: int,
        area_code: str = "ALL",
    ) -> Optional[ClinicalSafetyAlert]:
        """Evaluates whether override rates breach safety thresholds requiring clinical team alert (Req 46.3)."""
        metrics = self.compute_rule_metrics(rule_id, total_evaluations)

        if metrics["override_rate"] >= self.override_threshold:
            return ClinicalSafetyAlert(
                alert_id=f"alert_ovr_{rule_id}_{int(datetime.now().timestamp())}",
                rule_id=rule_id,
                metric_name="OVERRIDE_RATE",
                observed_value=metrics["override_rate"],
                threshold_value=self.override_threshold,
                cohort_or_area=area_code,
                severity="WARNING",
                triggered_at=datetime.now(),
                message=(
                    f"Clinical rule '{rule_id}' has an override rate of {metrics['override_rate']*100:.1f}%, "
                    f"exceeding the safety threshold of {self.override_threshold*100:.1f}%. Clinical review recommended."
                ),
            )

        if metrics["deescalation_rate"] >= self.under_triage_threshold:
            return ClinicalSafetyAlert(
                alert_id=f"alert_undertriage_{rule_id}_{int(datetime.now().timestamp())}",
                rule_id=rule_id,
                metric_name="UNDER_TRIAGE_DISCORDANCE",
                observed_value=metrics["deescalation_rate"],
                threshold_value=self.under_triage_threshold,
                cohort_or_area=area_code,
                severity="CRITICAL",
                triggered_at=datetime.now(),
                message=(
                    f"Critical under-triage discordance on rule '{rule_id}' ({metrics['deescalation_rate']*100:.1f}%). "
                    "Immediate clinical audit initiated."
                ),
            )

        return None

    def disable_component(self, component_key: str, reason: str) -> None:
        """Disables poor-performing ML or triage components (Req 46.5)."""
        self._disabled_components[component_key] = reason

    def is_component_enabled(self, component_key: str) -> bool:
        return component_key not in self._disabled_components

    def record_safety_incident(self, incident: Dict) -> str:
        """Logs a clinical safety incident with structured investigation fields (Req 46.4)."""
        incident_id = f"inc_{int(datetime.now().timestamp())}_{len(self._incident_reports)+1}"
        record = {
            "incident_id": incident_id,
            "recorded_at": datetime.now().isoformat(),
            **incident,
        }
        self._incident_reports.append(record)
        return incident_id
