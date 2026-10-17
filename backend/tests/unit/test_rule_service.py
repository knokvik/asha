"""Unit tests for RuleService clinical governance, semver, test suite, and state overlays.

Requirements 9.1, 9.2, 9.5, 9.6, 9.7.
"""
from __future__ import annotations

import gzip
import json
import pytest

from services.rule_service import (
    RuleService,
    RuleValidationError,
    RuleTestSuiteFailure,
    SecondClinicianApprovalRequired,
)
from api.v1.rules import DEFAULT_NATIONAL_RULESET


def test_validate_rule_set_rejects_missing_citation():
    invalid_ruleset = {
        "rules": [
            {
                "rule_id": "TEST_RULE_1",
                "severity": "RED",
                "source_citation": "",  # Missing!
                "condition": {"op": "gte", "field": "respiratory_rate", "value": 60},
            }
        ]
    }
    with pytest.raises(RuleValidationError, match="source citation is mandatory"):
        RuleService.validate_rule_set(invalid_ruleset)


def test_validate_rule_set_rejects_invalid_severity():
    invalid_ruleset = {
        "rules": [
            {
                "rule_id": "TEST_RULE_1",
                "severity": "CRITICAL",  # Must be RED/YELLOW/GREEN
                "source_citation": "IMNCI 2014, p.12",
                "condition": {"op": "gte", "field": "respiratory_rate", "value": 60},
            }
        ]
    }
    with pytest.raises(RuleValidationError, match="invalid severity"):
        RuleService.validate_rule_set(invalid_ruleset)


def test_automated_test_suite_passes_on_valid_ruleset():
    # Built-in national rule set has an embedded test case TC_INFANT_FAST_BREATHING_RED
    RuleService.run_automated_test_suite(DEFAULT_NATIONAL_RULESET)


def test_automated_test_suite_blocks_release_on_failure():
    failing_ruleset = dict(DEFAULT_NATIONAL_RULESET)
    failing_ruleset["test_suite"] = [
        {
            "test_id": "TC_FAIL_CASE",
            "inputs": {
                "age_days": 10,
                "respiratory_rate": 30,  # Normal, rules evaluate to GREEN (or YELLOW if missing field)
                "temperature": 36.8,
            },
            "expected_flag": "RED",  # But test case expects RED!
            "description": "Failing test expecting RED for normal inputs",
        }
    ]

    with pytest.raises(RuleTestSuiteFailure, match="Test case 'TC_FAIL_CASE' failed"):
        RuleService.run_automated_test_suite(failing_ruleset)


def test_check_severity_lowering_requires_second_clinician():
    # Candidate rule set with a test case that was previously expected to be RED, now evaluates to YELLOW
    candidate_ruleset = {
        "rules": [
            {
                "rule_id": "MODIFIED_BREATHING",
                "age_band": "INFANT_0_2M",
                "severity": "YELLOW",  # Lowered from RED!
                "source_citation": "Modified guideline 2024",
                "condition": {"op": "gte", "field": "respiratory_rate", "value": 60},
            }
        ],
        "test_suite": [],
    }

    previous_ruleset = {
        "test_suite": [
            {
                "test_id": "TC_INFANT_BREATHING_HISTORIC",
                "inputs": {
                    "age_days": 20,
                    "respiratory_rate": 65,
                },
                "expected_flag": "RED",
                "description": "Historically evaluated to RED",
            }
        ]
    }

    # Should raise error without second clinician
    with pytest.raises(SecondClinicianApprovalRequired, match="Explicit additional clinical sign-off"):
        RuleService.check_severity_lowering(
            candidate_rule_set=candidate_ruleset,
            previous_rule_set=previous_ruleset,
            second_clinical_lead_id=None,
            second_approval_signature=None,
        )

    # Passes when second clinician signs off
    RuleService.check_severity_lowering(
        candidate_rule_set=candidate_ruleset,
        previous_rule_set=previous_ruleset,
        second_clinical_lead_id="clinician_reviewer_02",
        second_approval_signature="SIG_SECONDARY_CLINICIAN_VALIDATION",
    )


def test_state_overlay_additive_and_restrictive():
    overlay = {
        "state_code": "MH",
        "rules": [
            # Restrictive: Lower threshold for hypertensive crisis in adults
            {
                "rule_id": "ADULT_HYPERTENSIVE_CRISIS",
                "age_band": "ADULT",
                "severity": "RED",
                "source_citation": "Maharashtra State Health Directive 2023, p.5",
                "condition": {"op": "gte", "field": "systolic_bp", "value": 170},  # Lowered threshold from 180
                "finding_template": "MH State Protocol: BP >= 170 requires emergency transfer",
                "action": "REFER_IMMEDIATELY",
            },
            # Additive: State-specific sickle cell disease screening
            {
                "rule_id": "MH_SICKLE_CELL_DANGER",
                "age_band": "ADULT",
                "severity": "RED",
                "source_citation": "MH Tribal Health Mission Guidelines, p.15",
                "condition": {"op": "eq", "field": "joint_pain_crisis", "value": True},
                "finding_template": "Sickle cell crisis detected — initiate hydration and refer",
                "action": "REFER_IMMEDIATELY",
            },
        ],
    }

    composite = RuleService.apply_state_overlay(DEFAULT_NATIONAL_RULESET, overlay)
    assert "+MH" in composite["version_string"]
    rule_ids = {r["rule_id"] for r in composite["rules"]}
    assert "MH_SICKLE_CELL_DANGER" in rule_ids
    assert "ADULT_HYPERTENSIVE_CRISIS" in rule_ids


def test_state_overlay_rejects_destructive_lowering():
    destructive_overlay = {
        "state_code": "TEST",
        "rules": [
            # Destructive: Attempts to lower INFANT_FAST_BREATHING from RED to YELLOW
            {
                "rule_id": "INFANT_FAST_BREATHING",
                "age_band": "INFANT_0_2M",
                "severity": "YELLOW",  # Lowering severity is destructive!
                "source_citation": "Invalid state protocol",
                "condition": {"op": "gte", "field": "respiratory_rate", "value": 60},
            }
        ],
    }

    with pytest.raises(RuleValidationError, match="State overlay is destructive"):
        RuleService.apply_state_overlay(DEFAULT_NATIONAL_RULESET, destructive_overlay)


def test_package_bundle_gzip_round_trip():
    gzipped, bundle_hash, canonical_json = RuleService.package_bundle(DEFAULT_NATIONAL_RULESET)
    assert len(bundle_hash) == 64
    assert len(gzipped) > 0

    decompressed = gzip.decompress(gzipped).decode("utf-8")
    assert json.loads(decompressed) == json.loads(canonical_json)
