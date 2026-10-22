"""Authenticated, integrity-verifiable optional app content downloads."""
from __future__ import annotations

from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse

from services.content_packs import ContentPackStore

router = APIRouter(prefix="/packs", tags=["content-packs"])
pack_store = ContentPackStore()


@router.get("")
async def list_content_packs() -> dict[str, object]:
    """Expose pack metadata without embedding optional data in the APK."""
    return {
        "packs": [
            pack.metadata(download_url=f"/api/v1/packs/{pack.id}")
            for pack in pack_store.list()
        ]
    }


@router.get("/{pack_id}")
async def download_content_pack(pack_id: str) -> FileResponse:
    """Serve an immutable ZIP with a SHA-256 header for client verification."""
    pack = pack_store.get(pack_id)
    if pack is None:
        raise HTTPException(
            status_code=404,
            detail="This offline pack is not published on the server yet.",
        )
    return FileResponse(
        path=pack.archive,
        media_type="application/zip",
        filename=f"{pack.id}-v{pack.version}.zip",
        headers={
            "X-Content-SHA256": pack.sha256,
            "X-Content-Pack-Version": pack.version,
            "Cache-Control": "public, max-age=86400, immutable",
        },
    )
