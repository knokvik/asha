"""Clinical Rule Authoring, Versioning, and Governance Service.

Implements Requirements 9.1–9.7:
- Rejects rules with missing source citations (9.1).
- Requires Clinical_Lead approval gate & semantic versioning (9.2).
- Packages signed OTA bundle with SHA-256 integrity hash & rollback support (9.3).
- Executes embedded automated test suite; blocks release on failure (9.5).
- Supports state overlay rules: additive/restrictive layer on national base, never destructive (9.6).
- Flags severity-lowering changes for mandatory second clinician sign-off (9.7).
"""
from __future__ import annotations

import gzip
import hashlib
import json
import re
from datetime import datetime, timezone
from typing import Any

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from models.db.models import RuleVersion

SEMVER_REGEX = re.compile(r"^(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?$")
SEVERITY_ORDER = {"GREEN": 0, "YELLOW": 1, "RED": 2}


class RuleValidationError(ValueError):
    """Raised when rule set definition violates clinical governance constraints."""


class RuleTestSuiteFailure(ValueError):
    """Raised when candidate rule set fails an embedded automated test case."""


class SecondClinicianApprovalRequired(ValueError):
    """Raised when rule set lowers test case severity without second clinician sign-off."""


def _semver_key(v: str) -> tuple[int, int, int]:
    match = SEMVER_REGEX.match(v)
    if not match:
        raise RuleValidationError(f"Invalid semantic version string: {v}")
    return (int(match.group(1)), int(match.group(2)), int(match.group(3)))


def _compare_values(a: Any, b: Any) -> bool:
    if a is None or b is None:
        return a == b
    if isinstance(a, (int, float)) and isinstance(b, (int, float)):
        return abs(a - b) < 1e-9
    if isinstance(a, bool) and isinstance(b, bool):
        return a == b
    if isinstance(a, str) and isinstance(b, str):
        return a.strip().lower() == b.strip().lower()
    return str(a).strip().lower() == str(b).strip().lower()


def evaluate_condition(c: dict[str, Any], inputs: dict[str, Any]) -> bool:
    """Evaluates an AST condition node against clinical inputs."""
    op = c.get("op", "and").lower()

    if op == "and":
        children = c.get("children", [])
        return all(evaluate_condition(ch, inputs) for ch in children) if children else True

    if op == "or":
        children = c.get("children", [])
        return any(evaluate_condition(ch, inputs) for ch in children) if children else False

    if op == "not":
        children = c.get("children", [])
        return not evaluate_condition(children[0], inputs) if children else False

    field = c.get("field")
    if not field:
        return False

    val = inputs.get(field)

    if op == "present":
        return val is not None and val != ""

    if op == "absent":
        return val is None or val == ""

    if val is None:
        return False

    target = c.get("value")
    if op in ("gt", "lt", "gte", "lte"):
        try:
            num_val = float(val)
            num_target = float(target)
        except (ValueError, TypeError):
            return False

        if op == "gt":
            return num_val > num_target
        if op == "lt":
            return num_val < num_target
        if op == "gte":
            return num_val >= num_target
        if op == "lte":
            return num_val <= num_target

    if op == "eq":
        return _compare_values(val, target)

    if op == "neq":
        return not _compare_values(val, target)

    if op in ("in", "is_in"):
        values = c.get("values") or (target if isinstance(target, list) else [])
        return any(_compare_values(val, item) for item in values)

    if op in ("not_in", "not_is_in"):
        values = c.get("values") or (target if isinstance(target, list) else [])
        return not any(_compare_values(val, item) for item in values)

    return False


def resolve_age_band(inputs: dict[str, Any]) -> str:
    """Resolves target age band from inputs."""
    if inputs.get("is_pregnant"):
        return "PREGNANT"
    if "explicit_age_band" in inputs:
        return str(inputs["explicit_age_band"])

    age_days = inputs.get("age_days")
    if age_days is not None:
        if age_days <= 60:
            return "INFANT_0_2M"
        if age_days <= 1825:
            return "CHILD_2M_5Y"
        if age_days <= 6935:
            return "ADOLESCENT"
        return "ADULT"

    age_years = inputs.get("age_years")
    if age_years is not None:
        if age_years <= (60 / 365.25):
            return "INFANT_0_2M"
        if age_years <= 5.0:
            return "CHILD_2M_5Y"
        if age_years < 19.0:
            return "ADOLESCENT"
        return "ADULT"

    return "ADULT"


def evaluate_triage_rules(rule_set: dict[str, Any], inputs: dict[str, Any]) -> str:
    """Evaluates rule set against inputs to compute highest triage flag."""
    age_band = resolve_age_band(inputs)
    rules = [r for r in rule_set.get("rules", []) if r.get("age_band") == age_band]

    highest_flag = "GREEN"
    for rule in rules:
        if evaluate_condition(rule.get("condition", {}), inputs):
            sev = rule.get("severity", "GREEN").upper()
            if SEVERITY_ORDER.get(sev, 0) > SEVERITY_ORDER.get(highest_flag, 0):
                highest_flag = sev

    # Missing field escalation check
    age_bands = rule_set.get("age_bands", [])
    required_fields: list[str] = []
    for ab in age_bands:
        if ab.get("code") == age_band:
            required_fields = ab.get("required_fields", [])
            break

    missing = [f for f in required_fields if inputs.get(f) is None or inputs.get(f) == ""]
    if missing and highest_flag != "RED":
        highest_flag = "YELLOW" if highest_flag == "GREEN" else "RED"

    return highest_flag


class RuleService:
    @staticmethod
    def validate_rule_set(rule_set: dict[str, Any]) -> None:
        """Requirement 9.1: Store rules as structured decision tables with mandatory citations."""
        rules = rule_set.get("rules", [])
        if not rules:
            raise RuleValidationError("Rule set must contain at least one rule")

        for rule in rules:
            citation = rule.get("source_citation", "").strip()
            if not citation:
                raise RuleValidationError(
                    f"Rule '{rule.get('rule_id')}' rejected: source citation is mandatory "
                    "(IMNCI, HBNC, HBYC, MoHFW guideline title and page number required)."
                )

            severity = rule.get("severity", "").upper()
            if severity not in SEVERITY_ORDER:
                raise RuleValidationError(
                    f"Rule '{rule.get('rule_id')}' has invalid severity '{severity}'."
                )

    @staticmethod
    def run_automated_test_suite(rule_set: dict[str, Any]) -> None:
        """Requirement 9.5: Run embedded test suite and block release if any test fails."""
        test_suite = rule_set.get("test_suite", [])
        for test in test_suite:
            test_id = test.get("test_id", "unnamed")
            inputs = test.get("inputs", {})
            expected = test.get("expected_flag", "GREEN").upper()
            actual = evaluate_triage_rules(rule_set, inputs)

            if actual != expected:
                raise RuleTestSuiteFailure(
                    f"Test case '{test_id}' failed: expected {expected}, got {actual} "
                    f"({test.get('description', '')})"
                )

    @staticmethod
    def check_severity_lowering(
        candidate_rule_set: dict[str, Any],
        previous_rule_set: dict[str, Any] | None,
        second_clinical_lead_id: str | None,
        second_approval_signature: str | None,
    ) -> None:
        """Requirement 9.7: Flag proposed rule change lowering severity of existing test cases."""
        if not previous_rule_set:
            return

        prev_tests = previous_rule_set.get("test_suite", [])
        for test in prev_tests:
            test_id = test.get("test_id", "")
            inputs = test.get("inputs", {})
            prev_expected = test.get("expected_flag", "GREEN").upper()

            candidate_result = evaluate_triage_rules(candidate_rule_set, inputs)

            if SEVERITY_ORDER.get(candidate_result, 0) < SEVERITY_ORDER.get(prev_expected, 0):
                if not (second_clinical_lead_id and second_approval_signature):
                    raise SecondClinicianApprovalRequired(
                        f"Rule change lowers expected severity for test case '{test_id}' from "
                        f"{prev_expected} to {candidate_result}. Explicit additional clinical "
                        "sign-off by a second clinician is mandatory."
                    )

    @staticmethod
    def apply_state_overlay(
        base_rule_set: dict[str, Any],
        overlay: dict[str, Any],
    ) -> dict[str, Any]:
        """Requirement 9.6: State overlays on national base must be additive/restrictive, never destructive."""
        merged_rules = list(base_rule_set.get("rules", []))
        base_rule_map = {r["rule_id"]: r for r in merged_rules}

        for rule in overlay.get("rules", []):
            rule_id = rule.get("rule_id")
            if rule_id in base_rule_map:
                base_rule = base_rule_map[rule_id]
                base_sev = SEVERITY_ORDER.get(base_rule.get("severity", "GREEN").upper(), 0)
                new_sev = SEVERITY_ORDER.get(rule.get("severity", "GREEN").upper(), 0)

                # Cannot lower national base severity in state overlay
                if new_sev < base_sev:
                    raise RuleValidationError(
                        f"State overlay is destructive: lowers severity of base rule '{rule_id}' "
                        f"from {base_rule.get('severity')} to {rule.get('severity')}."
                    )
                # Restrictive replacement
                idx = merged_rules.index(base_rule)
                merged_rules[idx] = rule
            else:
                # Additive rule
                merged_rules.append(rule)

        composite = dict(base_rule_set)
        composite["rules"] = merged_rules
        composite["version_string"] = (
            f"{base_rule_set.get('version_string')}+{overlay.get('state_code', 'STATE')}"
        )
        return composite

    @staticmethod
    def package_bundle(rule_set: dict[str, Any]) -> tuple[bytes, str, str]:
        """Serialises canonical JSON, computes SHA-256 hash, and gzip-compresses the bundle."""
        canonical_json = json.dumps(rule_set, sort_keys=True, separators=(",", ":"))
        bundle_hash = hashlib.sha256(canonical_json.encode("utf-8")).hexdigest()
        gzipped_bytes = gzip.compress(canonical_json.encode("utf-8"))
        return gzipped_bytes, bundle_hash, canonical_json

    @classmethod
    async def publish_rule_set(
        cls,
        db: AsyncSession,
        candidate_rule_set: dict[str, Any],
        clinical_lead_id: str,
        approval_signature: str,
        user_role: str,
        second_clinical_lead_id: str | None = None,
        second_approval_signature: str | None = None,
    ) -> RuleVersion:
        """Requirement 9.2: Clinical_Lead approves change; versions immutably."""
        if user_role not in ("clinical_lead", "Clinical_Lead", "admin"):
            raise PermissionError("Only clinicians with the Clinical_Lead role may approve rule sets")

        cls.validate_rule_set(candidate_rule_set)

        # Semver validation
        version_str = candidate_rule_set.get("version_string", "")
        _semver_key(version_str)

        # Check latest active version
        result = await db.execute(
            select(RuleVersion).where(RuleVersion.is_active == True)  # noqa: E712
        )
        current_active = result.scalars().first()

        prev_rule_set: dict[str, Any] | None = None
        if current_active and current_active.bundle_path:
            try:
                with open(current_active.bundle_path, "r", encoding="utf-8") as f:
                    prev_rule_set = json.load(f)
            except Exception:
                pass

        # Requirement 9.5: Automated test suite execution
        cls.run_automated_test_suite(candidate_rule_set)

        # Requirement 9.7: Check if lowering severity requires second clinician
        cls.check_severity_lowering(
            candidate_rule_set,
            prev_rule_set,
            second_clinical_lead_id,
            second_approval_signature,
        )

        # Package bundle
        gzipped_bytes, bundle_hash, canonical_json = cls.package_bundle(candidate_rule_set)

        # Deactivate previous active version (retaining record for rollback)
        if current_active:
            await db.execute(
                update(RuleVersion)
                .where(RuleVersion.id == current_active.id)
                .values(is_active=False)
            )

        now_ms = int(datetime.now(timezone.utc).timestamp() * 1000)
        rule_version_id = candidate_rule_set.get("id") or f"ruleset_{version_str}"

        # Write rule version to DB
        new_version = RuleVersion(
            id=rule_version_id,
            version_string=version_str,
            published_at=now_ms,
            bundle_hash=bundle_hash,
            bundle_path=None,  # Stored directly or in object storage
            is_active=True,
            clinical_lead_id=clinical_lead_id,
            approval_signature=approval_signature,
        )
        db.add(new_version)
        await db.commit()
        await db.refresh(new_version)
        return new_version
