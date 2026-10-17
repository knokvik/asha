"""Property-based tests for audit chain tamper detection, event-log replay, and schema round-trip.

Specification & Traceability:
- Requirement 33.2: Tamper-evident hash chain over audit log entries.
- Requirement 33.3: Event-log replay consistency (reconstruct(eventLog) == currentRecord).
- Requirement 1.2, 5.2, 52.6: Record serialization round-trip.
- Property 1: Clinical Record Serialisation Round-Trip
- Property 14: Audit Hash-Chain Tamper Detection
- Property 15: Event-Log Replay Consistency
- Tasks: 15.9, Req 33
"""
from __future__ import annotations

import hashlib
import random
import uuid


from models.schemas.schemas import EventLogEntry, SyncPushRequest, SyncRecord


def compute_audit_chain_hash(
    previous_hash: str,
    table_name: str,
    record_id: str,
    field_name: str | None,
    old_value: str | None,
    new_value: str | None,
    changed_by: str,
    device_timestamp: int,
) -> str:
    """Canonical SHA-256 chain hash matching mobile AuditChainService."""
    payload = f"{previous_hash}|{table_name}|{record_id}|{field_name or ''}|{old_value or ''}|{new_value or ''}|{changed_by}|{device_timestamp}"
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def verify_audit_chain(entries: list[dict[str, any]], initial_hash: str = "0" * 64) -> bool:
    """Verifies that each link in the audit chain matches recomputed SHA-256."""
    if not entries:
        return True

    current_prev = initial_hash
    for entry in entries:
        expected = compute_audit_chain_hash(
            previous_hash=current_prev,
            table_name=entry["table_name"],
            record_id=entry["record_id"],
            field_name=entry.get("field_name"),
            old_value=entry.get("old_value"),
            new_value=entry.get("new_value"),
            changed_by=entry["changed_by"],
            device_timestamp=entry["device_timestamp"],
        )
        if entry["chain_hash"] != expected:
            return False
        current_prev = entry["chain_hash"]

    return True


def replay_event_log(initial_state: dict[str, any], event_log: list[dict[str, any]]) -> dict[str, any]:
    """Property 15: Reconstructs record state by replaying event log."""
    sorted_events = sorted(event_log, key=lambda e: (e["device_timestamp"], e.get("id", "")))
    state = dict(initial_state)
    for event in sorted_events:
        field = event.get("field_name")
        if field:
            state[field] = event.get("new_value")
    return state


def test_property_14_tamper_detection_500_permutations() -> None:
    """Property 14: Modifying any byte in any historical entry breaks chain verification."""
    rng = random.Random(9999)
    iterations = 500

    for t in range(iterations):
        chain_len = rng.randint(3, 10)
        rec_id = f"rec_{rng.randint(100, 99999)}"
        table = "members"
        chain: list[dict[str, any]] = []
        prev = "0" * 64
        ts = 1700000000000

        for i in range(chain_len):
            ts += rng.randint(100, 5000)
            field = f"field_{rng.randint(1, 6)}"
            old_val = f"v_old_{rng.randint(1, 50)}"
            new_val = f"v_new_{rng.randint(51, 100)}"
            by = f"worker_{rng.randint(1, 20)}"

            h = compute_audit_chain_hash(
                previous_hash=prev,
                table_name=table,
                record_id=rec_id,
                field_name=field,
                old_value=old_val,
                new_value=new_val,
                changed_by=by,
                device_timestamp=ts,
            )

            chain.append({
                "id": f"entry_{t}_{i}",
                "table_name": table,
                "record_id": rec_id,
                "field_name": field,
                "old_value": old_val,
                "new_value": new_val,
                "changed_by": by,
                "device_timestamp": ts,
                "chain_hash": h,
            })
            prev = h

        # 1. Untampered chain must pass verification
        assert verify_audit_chain(chain) is True

        # 2. Tamper a random entry
        tamper_idx = rng.randint(0, chain_len - 1)
        tampered_chain = [dict(x) for x in chain]
        tamper_target = tampered_chain[tamper_idx]

        mode = rng.randint(0, 5)
        if mode == 0:
            tamper_target["new_value"] = f"{tamper_target['new_value']}_TAMPERED"
        elif mode == 1:
            tamper_target["old_value"] = f"{tamper_target['old_value']}_CORRUPTED"
        elif mode == 2:
            tamper_target["changed_by"] = "hacker_99"
        elif mode == 3:
            tamper_target["device_timestamp"] += 1
        elif mode == 4:
            tamper_target["record_id"] = f"{tamper_target['record_id']}_hack"
        else:
            tamper_target["table_name"] = "other_table"

        # 3. Tampered chain must fail verification
        assert verify_audit_chain(tampered_chain) is False, (
            f"Failed to detect tampering at index {tamper_idx} (mode {mode})"
        )


def test_property_15_event_log_replay_500_permutations() -> None:
    """Property 15: Replaying ordered audit log from start reproduces exact record state."""
    rng = random.Random(8888)
    iterations = 500

    fields = ["name", "phone", "consent_status", "status", "risk_level"]

    for t in range(iterations):
        initial = {
            "name": "Base Beneficiary",
            "phone": "9811111111",
            "consent_status": "pending",
            "status": "active",
            "risk_level": "normal",
        }
        current = dict(initial)
        event_log: list[dict[str, any]] = []
        n_events = rng.randint(2, 10)
        ts = 1700000000000

        for i in range(n_events):
            f = rng.choice(fields)
            new_v = f"updated_{t}_{i}_{rng.randint(100, 999)}"
            current[f] = new_v
            ts += rng.randint(100, 1000)

            event_log.append({
                "id": f"ev_{t}_{i}",
                "field_name": f,
                "old_value": initial.get(f),
                "new_value": new_v,
                "changed_by": f"asha_{i}",
                "device_timestamp": ts,
            })

        # Shuffle event order to confirm replay sorts chronologically
        shuffled = list(event_log)
        rng.shuffle(shuffled)

        replayed = replay_event_log(initial, shuffled)
        assert replayed == current, f"Replay divergence at iteration {t}"


def test_property_1_sync_push_request_serialization_round_trip() -> None:
    """Property 1: Pydantic SyncPushRequest schema serializes and deserializes losslessly."""
    rng = random.Random(7777)
    for _ in range(100):
        req = SyncPushRequest(
            device_id=f"dev_{rng.randint(1, 50)}",
            worker_id=f"worker_{rng.randint(1, 100)}",
            app_version="1.0.0",
            batch_id=str(uuid.uuid4()),
            sent_at=1700000000000 + rng.randint(1000, 90000),
            records=[
                SyncRecord(
                    table="members",
                    record_id=f"mem_{rng.randint(1, 5000)}",
                    operation="update",
                    priority=2,
                    payload={"name": f"Name {rng.randint(1, 1000)}", "phone": "9999999999"},
                    event_log=[
                        EventLogEntry(
                            field="name",
                            old_value="Old Name",
                            new_value="New Name",
                            changed_by="worker_1",
                            device_id="dev_1",
                            device_timestamp=1700000000100,
                        )
                    ],
                    device_timestamp=1700000000100,
                    client_watermark=10,
                )
            ],
        )

        serialized_json = req.model_dump_json()
        deserialized = SyncPushRequest.model_validate_json(serialized_json)

        assert deserialized == req
        assert deserialized.batch_id == req.batch_id
        assert deserialized.records[0].record_id == req.records[0].record_id
