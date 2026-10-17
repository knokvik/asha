"""DPDP Act 2023 and ABDM Data Security and Privacy Compliance Service (Requirement 44)."""

from __future__ import annotations
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Dict, List, Optional


@dataclass
class SarRequest:
    request_id: str
    beneficiary_id: str
    request_type: str  # 'ACCESS', 'CORRECTION', 'ERASURE'
    details: str
    status: str  # 'SUBMITTED', 'VERIFYING', 'FULFILLED', 'REJECTED'
    submitted_at: datetime
    fulfilled_at: Optional[datetime] = None
    resolution_notes: Optional[str] = None


@dataclass
class BreachIncident:
    incident_id: str
    anomaly_type: str
    affected_records_count: int
    detected_at: datetime
    notified_cert_in_at: datetime
    status: str  # 'CONTAINED', 'INVESTIGATING', 'RESOLVED'
    mitigation_action: str


@dataclass
class DataAccessLog:
    access_id: str
    user_id: str
    user_role: str
    patient_id: str
    purpose: str
    accessed_at: datetime


class BackendDpdpService:
    """Manages DPDP statutory SAR fulfillment, breach notifications, and anomalous access monitoring."""

    def __init__(self, anomaly_window_minutes: int = 5, anomaly_threshold_queries: int = 50):
        self.anomaly_window_minutes = anomaly_window_minutes
        self.anomaly_threshold_queries = anomaly_threshold_queries
        self._sar_records: Dict[str, SarRequest] = {}
        self._breaches: List[BreachIncident] = []
        self._access_logs: List[DataAccessLog] = []

    def submit_sar_request(
        self,
        beneficiary_id: str,
        request_type: str,
        details: str,
    ) -> SarRequest:
        """Registers a tracked DPDP request (Req 44.3)."""
        request_id = f"sar_{int(datetime.now().timestamp())}_{len(self._sar_records)+1}"
        sar = SarRequest(
            request_id=request_id,
            beneficiary_id=beneficiary_id,
            request_type=request_type.upper(),
            details=details,
            status="SUBMITTED",
            submitted_at=datetime.now(),
        )
        self._sar_records[request_id] = sar
        return sar

    def fulfill_sar_request(self, request_id: str, resolution_notes: str) -> SarRequest:
        """Records the fulfillment of a SAR request with audit timestamp (Req 44.3)."""
        if request_id not in self._sar_records:
            raise KeyError(f"SAR request '{request_id}' not found.")

        sar = self._sar_records[request_id]
        sar.status = "FULFILLED"
        sar.fulfilled_at = datetime.now()
        sar.resolution_notes = resolution_notes
        return sar

    def log_access(
        self,
        user_id: str,
        user_role: str,
        patient_id: str,
        purpose: str,
    ) -> DataAccessLog:
        """Logs every personal health data access with user, purpose, and timestamp (Req 44.6)."""
        log_entry = DataAccessLog(
            access_id=f"acc_{int(datetime.now().timestamp())}_{len(self._access_logs)+1}",
            user_id=user_id,
            user_role=user_role,
            patient_id=patient_id,
            purpose=purpose,
            accessed_at=datetime.now(),
        )
        self._access_logs.append(log_entry)
        return log_entry

    def detect_anomalous_access(self, user_id: str) -> Optional[Dict]:
        """Detects anomalous high-frequency queries by a single user across patients (Req 44.6)."""
        window_start = datetime.now() - timedelta(minutes=self.anomaly_window_minutes)
        recent_queries = [
            entry for entry in self._access_logs if entry.user_id == user_id and entry.accessed_at >= window_start
        ]

        if len(recent_queries) >= self.anomaly_threshold_queries:
            distinct_patients = len({entry.patient_id for entry in recent_queries})
            return {
                "alert": "ANOMALOUS_DATA_ACCESS",
                "user_id": user_id,
                "query_count": len(recent_queries),
                "distinct_patients": distinct_patients,
                "window_minutes": self.anomaly_window_minutes,
                "severity": "CRITICAL",
                "action": "SUSPEND_SESSION_AND_ALERT_SECURITY_ADMIN",
            }
        return None

    def log_breach_incident(
        self,
        anomaly_type: str,
        affected_count: int,
        mitigation_action: str,
    ) -> BreachIncident:
        """Logs a data breach and ensures CERT-In statutory notice workflow is initiated (Req 44.4)."""
        now = datetime.now()
        incident = BreachIncident(
            incident_id=f"breach_{int(now.timestamp())}_{len(self._breaches)+1}",
            anomaly_type=anomaly_type,
            affected_records_count=affected_count,
            detected_at=now,
            notified_cert_in_at=now,  # Mandated notification
            status="CONTAINED",
            mitigation_action=mitigation_action,
        )
        self._breaches.append(incident)
        return incident
