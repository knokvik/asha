#!/usr/bin/env python3
"""Smoke check for the offline map pack. It does not open a network socket.

Run from anywhere:
  python3 mobile/tool/airplane_map_check.py
"""
from __future__ import annotations

import json
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MBTILES = ROOT / "assets" / "geo" / "pcmc.mbtiles"
FACILITIES = ROOT / "assets" / "geo" / "facilities.geojson"
COUNTS = ROOT / "packages" / "triage" / "lib" / "data" / "pack" / "disease_counts.csv"
LIMIT = 40 * 1024 * 1024


def main() -> None:
    size = MBTILES.stat().st_size
    if size <= 0 or size >= LIMIT:
        raise SystemExit(f"mbtiles size {size} is outside 1..{LIMIT - 1}")
    db = sqlite3.connect(f"file:{MBTILES}?mode=ro", uri=True)
    meta = dict(db.execute("SELECT name, value FROM metadata"))
    count = db.execute("SELECT COUNT(*) FROM tiles").fetchone()[0]
    zooms = [row[0] for row in db.execute("SELECT DISTINCT zoom_level FROM tiles ORDER BY 1")]
    db.close()
    if count < 1:
        raise SystemExit("mbtiles has no tiles")
    if meta.get("format") != "png" or meta.get("minzoom") != "8" or meta.get("maxzoom") != "14":
        raise SystemExit(f"unexpected metadata {meta}")
    if zooms[0] != 8 or zooms[-1] != 14:
        raise SystemExit(f"unexpected zooms {zooms}")

    facilities = json.loads(FACILITIES.read_text())["features"]
    if len(facilities) != 40:
        raise SystemExit(f"expected 40 facilities, got {len(facilities)}")

    week12 = None
    for line in COUNTS.read_text().splitlines():
        if line.startswith("12,W3,dengue_like,"):
            week12 = int(line.rsplit(",", 1)[1])
    if week12 != 5:
        raise SystemExit(f"W3 dengue week 12 is {week12}, expected 5")

    sources = [
        ROOT / "lib" / "features" / "map" / "presentation" / "geo_map_screen.dart",
        ROOT / "lib" / "features" / "map" / "data" / "mbtiles_tile_provider.dart",
        ROOT / "lib" / "features" / "home" / "presentation" / "dashboard_screen.dart",
    ]
    for path in sources:
        text = path.read_text()
        if "tile.openstreetmap.org" in text or "https://" in text:
            raise SystemExit(f"{path.name} still names a tile server")

    print(f"ok tiles={count} bytes={size} facilities=40 W3-dengue-week12=5 zooms={zooms[0]}-{zooms[-1]}")


if __name__ == "__main__":
    main()
