"""Authoritative source registry for the national map pipeline.

The registry records where each layer comes from and how it is ingested. It
does not fabricate points: map points are returned only after an importer has
normalised verified source data into the server directory.
"""
import json
from pathlib import Path

from fastapi import APIRouter

router = APIRouter(prefix="/map", tags=["map"])

_CATALOG_PATH = Path(__file__).resolve().parents[2] / "config" / "india_map_source_catalog.json"


def _load_catalog_document() -> dict[str, object]:
    with _CATALOG_PATH.open(encoding="utf-8") as catalog_file:
        return json.load(catalog_file)



@router.get("/sources")
async def list_map_sources() -> dict:
    catalog = _load_catalog_document()
    sources = catalog["sources"]
    return {
        "catalog_version": catalog.get("catalog_version"),
        "sources": sources,
        "count": len(sources),
        "capability_tag_schema": catalog.get("capability_tag_schema", {}),
        "routing_profiles": catalog.get("routing_profiles", {}),
    }
