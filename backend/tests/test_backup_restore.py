"""Automated Backup and Restore Test Procedure (Requirement 50.1)."""

import hashlib
import json
from datetime import datetime


class BackupRestoreManager:
    """Manages database snapshot creation, SHA-256 integrity verification, and restore simulation."""

    @staticmethod
    def create_snapshot(dataset: dict) -> dict:
        timestamp = datetime.now().isoformat()
        payload_bytes = json.dumps(dataset, sort_keys=True).encode("utf-8")
        checksum = hashlib.sha256(payload_bytes).hexdigest()

        return {
            "snapshot_id": f"snap_{int(datetime.now().timestamp())}",
            "created_at": timestamp,
            "record_count": sum(len(records) for records in dataset.values()),
            "sha256_checksum": checksum,
            "data": dataset,
        }

    @staticmethod
    def verify_and_restore(snapshot: dict) -> tuple[bool, dict]:
        dataset = snapshot.get("data", {})
        payload_bytes = json.dumps(dataset, sort_keys=True).encode("utf-8")
        calculated_checksum = hashlib.sha256(payload_bytes).hexdigest()

        if calculated_checksum != snapshot.get("sha256_checksum"):
            return False, {}

        # Successfully restored
        return True, dataset


def test_automated_backup_and_restore_cycle():
    # 1. Prepare simulated live database state
    live_database = {
        "households": [
            {"id": "hh_01", "village": "Rampur", "members": 4},
            {"id": "hh_02", "village": "Devpur", "members": 5},
        ],
        "clinical_encounters": [
            {"id": "enc_01", "member_id": "m1", "type": "ANC", "triage": "GREEN"},
            {"id": "enc_02", "member_id": "m2", "type": "IMNCI", "triage": "RED"},
        ],
        "incentive_events": [
            {"id": "inc_01", "activity": "ANC_REG_EARLY", "amount": 150.0},
            {"id": "inc_02", "activity": "HBNC_COMPLETE", "amount": 300.0},
        ],
    }

    # 2. Execute automated snapshot creation
    snapshot = BackupRestoreManager.create_snapshot(live_database)
    assert snapshot["record_count"] == 6
    assert len(snapshot["sha256_checksum"]) == 64

    # 3. Simulate clean database instance and execute restore
    success, restored_database = BackupRestoreManager.verify_and_restore(snapshot)
    assert success is True
    assert restored_database == live_database

    # 4. Assert tamper detection: altering any single record breaks restore
    tampered_snapshot = json.loads(json.dumps(snapshot))
    tampered_snapshot["data"]["incentive_events"][0]["amount"] = 999.0  # Unauthorized inflation
    tamper_success, _ = BackupRestoreManager.verify_and_restore(tampered_snapshot)
    assert tamper_success is False
