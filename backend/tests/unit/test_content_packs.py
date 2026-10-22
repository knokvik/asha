from __future__ import annotations

import hashlib
from pathlib import Path

import pytest

from api.v1 import content_packs
from services.content_packs import ContentPackStore


def test_map_pack_metadata_is_checksum_addressed(tmp_path: Path) -> None:
    archive = tmp_path / "map-india.zip"
    archive.write_bytes(b"verified map content")

    pack = ContentPackStore(tmp_path).get("map-india")

    assert pack is not None
    assert pack.id == "map-india"
    assert pack.size_bytes == len(b"verified map content")
    assert pack.sha256 == hashlib.sha256(b"verified map content").hexdigest()
    assert pack.metadata(download_url="/api/v1/packs/map-india")["download_url"] == (
        "/api/v1/packs/map-india"
    )


def test_content_pack_store_never_exposes_unknown_files(tmp_path: Path) -> None:
    (tmp_path / "secrets.zip").write_bytes(b"not a public pack")

    store = ContentPackStore(tmp_path)

    assert store.get("unknown") is None
    assert store.list() == []


@pytest.mark.asyncio
async def test_map_pack_api_returns_checksum_header(async_client, tmp_path: Path, monkeypatch) -> None:
    payload = b"map archive bytes"
    (tmp_path / "map-india.zip").write_bytes(payload)
    monkeypatch.setattr(content_packs, "pack_store", ContentPackStore(tmp_path))

    response = await async_client.get("/api/v1/packs/map-india")

    assert response.status_code == 200
    assert response.headers["content-type"] == "application/zip"
    assert response.headers["x-content-sha256"] == hashlib.sha256(payload).hexdigest()
    assert response.content == payload
