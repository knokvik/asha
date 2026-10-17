"""Integration tests for rules API endpoints.

Tests:
- GET /api/v1/rules/latest
- GET /api/v1/rules/{version}/bundle.json.gz
- Verification of SHA-256 header and bundle decompression

Requirements: 9.2, 9.3, 9.4
"""
from __future__ import annotations

import gzip
import hashlib
import json
import pytest


@pytest.mark.asyncio
class TestRulesApi:
    async def test_get_latest_rules_metadata(self, async_client):
        response = await async_client.get("/api/v1/rules/latest")
        assert response.status_code == 200
        data = response.json()

        assert "id" in data
        assert "version_string" in data
        assert data["version_string"] == "1.0.0"
        assert "bundle_hash" in data
        assert len(data["bundle_hash"]) == 64
        assert "download_url" in data
        assert "/api/v1/rules/1.0.0/bundle.json.gz" in data["download_url"]
        assert data["is_active"] is True

    async def test_download_rule_bundle_gzip(self, async_client):
        # 1. Fetch metadata
        meta_response = await async_client.get("/api/v1/rules/latest")
        assert meta_response.status_code == 200
        meta = meta_response.json()
        expected_hash = meta["bundle_hash"]
        download_url = meta["download_url"]

        # 2. Download gzip bundle
        bundle_response = await async_client.get(download_url)
        assert bundle_response.status_code == 200
        assert bundle_response.headers["content-type"] == "application/gzip"
        assert bundle_response.headers.get("X-Bundle-SHA256") == expected_hash

        # 3. Decompress and verify integrity
        gzipped_bytes = bundle_response.content
        decompressed_bytes = gzip.decompress(gzipped_bytes)
        computed_hash = hashlib.sha256(decompressed_bytes).hexdigest()
        assert computed_hash == expected_hash

        # 4. Parse JSON
        rule_set = json.loads(decompressed_bytes.decode("utf-8"))
        assert rule_set["version_string"] == "1.0.0"
        assert len(rule_set["rules"]) >= 5
        assert len(rule_set["age_bands"]) == 5
