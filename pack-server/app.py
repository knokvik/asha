"""Standalone Render service for ASHA mobile content packs."""
from __future__ import annotations

import hashlib
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse

ROOT = Path(__file__).resolve().parent
PACKS = ROOT / "content_packs"
LANGUAGES = {"hi", "mr", "bn", "te", "ta", "kn", "ml", "or", "gu", "pa", "as"}

app = FastAPI(title="ASHA Setu Content Packs", version="1.0.0")


def pack(pack_id: str) -> Path | None:
    if pack_id == "map-india":
        candidate = PACKS / "map-india.zip"
    elif pack_id.startswith("ui-") and pack_id.removeprefix("ui-") in LANGUAGES:
        candidate = PACKS / f"{pack_id}.zip"
    else:
        return None
    return candidate if candidate.is_file() else None


def metadata(pack_id: str, archive: Path) -> dict[str, object]:
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    return {
        "id": pack_id,
        "version": "1",
        "size_bytes": archive.stat().st_size,
        "sha256": digest,
        "download_url": f"/api/v1/packs/{pack_id}",
    }


@app.get("/healthz")
async def health() -> dict[str, str]:
    return {"status": "ok", "service": "content-packs"}


@app.get("/api/v1/packs")
async def list_packs() -> dict[str, object]:
    ids = ["map-india", *(f"ui-{code}" for code in sorted(LANGUAGES))]
    return {
        "packs": [
            metadata(pack_id, archive)
            for pack_id in ids
            if (archive := pack(pack_id)) is not None
        ]
    }


@app.get("/api/v1/packs/{pack_id}")
async def download_pack(pack_id: str) -> FileResponse:
    archive = pack(pack_id)
    if archive is None:
        raise HTTPException(status_code=404, detail="Pack not found")
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    return FileResponse(
        archive,
        media_type="application/zip",
        filename=f"{pack_id}-v1.zip",
        headers={
            "X-Content-SHA256": digest,
            "X-Content-Pack-Version": "1",
            "Cache-Control": "public, max-age=86400, immutable",
        },
    )
