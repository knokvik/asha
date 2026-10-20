#!/usr/bin/env python3
"""Bake an offline street map of the PCMC sample area into MBTiles.

Reads an Overpass JSON extract (default /tmp/pcmc-osm.json) and draws parks,
water, and roads into zooms 8–14. The app reads the file through sqlite.
No tile URL is written. Also writes assets/geo/roads.json for in-app walking
routes.

  python3 tool/generate_pcmc_mbtiles.py
  python3 tool/generate_pcmc_mbtiles.py --osm /tmp/pcmc-osm.json
"""
from __future__ import annotations

import argparse
import json
import math
import sqlite3
import struct
import zlib
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "geo" / "pcmc.mbtiles"
ROADS = ROOT / "assets" / "geo" / "roads.json"

SOUTH, WEST, NORTH, EAST = 18.60, 73.72, 18.72, 73.92
BG = (242, 239, 233)
PARK = (186, 214, 176)
WATER = (170, 211, 223)

# (fill, casing, min zoom, width at z14)
ROAD_STYLE = {
    "motorway": ((232, 146, 161), (190, 90, 108), 8, 5),
    "motorway_link": ((232, 146, 161), (190, 90, 108), 11, 3),
    "trunk": ((232, 146, 161), (190, 90, 108), 8, 5),
    "trunk_link": ((232, 146, 161), (190, 90, 108), 11, 3),
    "primary": ((247, 201, 72), (196, 154, 40), 8, 4),
    "primary_link": ((247, 201, 72), (196, 154, 40), 12, 3),
    "secondary": ((252, 214, 164), (196, 164, 120), 11, 4),
    "secondary_link": ((252, 214, 164), (196, 164, 120), 13, 3),
    "tertiary": ((255, 255, 255), (186, 186, 186), 12, 3),
    "tertiary_link": ((255, 255, 255), (186, 186, 186), 13, 2),
    "unclassified": ((255, 255, 255), (200, 200, 200), 13, 2),
    "residential": ((255, 255, 255), (204, 204, 204), 13, 2),
    "living_street": ((255, 255, 255), (204, 204, 204), 14, 2),
    "pedestrian": ((250, 248, 242), (204, 204, 204), 14, 2),
    "service": ((255, 255, 255), (214, 214, 214), 14, 1),
}
WALK = {
    "residential",
    "living_street",
    "unclassified",
    "tertiary",
    "tertiary_link",
    "secondary",
    "secondary_link",
    "primary",
    "primary_link",
    "pedestrian",
}
MAJOR = {"motorway", "motorway_link", "trunk", "trunk_link"}


def _png(width: int, height: int, pixels: bytes) -> bytes:
    raw = bytearray()
    stride = width * 3
    for y in range(height):
        raw.append(0)
        raw.extend(pixels[y * stride : (y + 1) * stride])

    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    header = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header) + chunk(b"IDAT", zlib.compress(bytes(raw), 6)) + chunk(b"IEND", b"")


def _project(lat: float, lon: float, scale: float) -> tuple[float, float]:
    x = (lon + 180.0) / 360.0 * scale
    lat = max(min(lat, 85.0), -85.0)
    rad = math.radians(lat)
    y = (1.0 - math.log(math.tan(rad) + 1.0 / math.cos(rad)) / math.pi) / 2.0 * scale
    return x, y


def _tile_span(zoom: int) -> tuple[range, range]:
    scale = 256 * (2**zoom)

    def xyz(lat: float, lon: float) -> tuple[int, int]:
        x, y = _project(lat, lon, scale)
        return int(x // 256), int(y // 256)

    x0, y0 = xyz(NORTH, WEST)
    x1, y1 = xyz(SOUTH, EAST)
    return range(min(x0, x1), max(x0, x1) + 1), range(min(y0, y1), max(y0, y1) + 1)


def _stamp(buf: bytearray, x: int, y: int, rgb: tuple[int, int, int], radius: int, size: int = 256) -> None:
    for dy in range(-radius, radius + 1):
        yy = y + dy
        if yy < 0 or yy >= size:
            continue
        row = yy * size
        for dx in range(-radius, radius + 1):
            xx = x + dx
            if 0 <= xx < size:
                offset = (row + xx) * 3
                buf[offset] = rgb[0]
                buf[offset + 1] = rgb[1]
                buf[offset + 2] = rgb[2]


def _line(buf: bytearray, x0: float, y0: float, x1: float, y1: float, rgb: tuple[int, int, int], width: int) -> None:
    steps = int(max(abs(x1 - x0), abs(y1 - y0)))
    if steps <= 0:
        _stamp(buf, int(x0), int(y0), rgb, max(0, width // 2))
        return
    if steps > 800:
        steps = 800
    radius = max(0, width // 2)
    for i in range(steps + 1):
        t = i / steps
        _stamp(buf, int(x0 + (x1 - x0) * t), int(y0 + (y1 - y0) * t), rgb, radius)


def _fill(buf: bytearray, pts: list[tuple[float, float]], rgb: tuple[int, int, int], size: int = 256) -> None:
    if len(pts) < 3:
        return
    edges: list[tuple[float, float, float, float]] = []
    for i in range(len(pts)):
        x0, y0 = pts[i]
        x1, y1 = pts[(i + 1) % len(pts)]
        if y0 == y1:
            continue
        if y0 > y1:
            x0, y0, x1, y1 = x1, y1, x0, y0
        edges.append((y0, y1, x0, (x1 - x0) / (y1 - y0)))
    for y in range(size):
        yy = y + 0.5
        xs = [x0 + dx * (yy - y0) for y0, y1, x0, dx in edges if y0 <= yy < y1]
        if len(xs) < 2:
            continue
        xs.sort()
        row = y * size * 3
        for i in range(0, len(xs) - 1, 2):
            start = max(0, int(xs[i]))
            end = min(size, int(xs[i + 1]) + 1)
            for x in range(start, end):
                offset = row + x * 3
                buf[offset] = rgb[0]
                buf[offset + 1] = rgb[1]
                buf[offset + 2] = rgb[2]


def _metres(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    mid = math.radians((lat1 + lat2) / 2)
    dy = (lat2 - lat1) * 111_320
    dx = (lon2 - lon1) * 111_320 * math.cos(mid)
    return math.hypot(dx, dy)


def _simplify(points: list[tuple[float, float]], keep: float = 18.0) -> list[tuple[float, float]]:
    if len(points) < 3:
        return points
    kept = [points[0]]
    for point in points[1:-1]:
        if _metres(kept[-1][0], kept[-1][1], point[0], point[1]) >= keep:
            kept.append(point)
    kept.append(points[-1])
    return kept


def _load(path: Path) -> tuple[list, list, list]:
    data = json.loads(path.read_text())
    parks = []
    water = []
    roads = []
    walk = []
    for element in data["elements"]:
        geom = element.get("geometry") or []
        if len(geom) < 2:
            continue
        pts = [(g["lat"], g["lon"]) for g in geom]
        tags = element.get("tags") or {}
        highway = tags.get("highway")
        if highway in ROAD_STYLE:
            roads.append((highway, pts))
            if highway in WALK or highway in MAJOR:
                simple = _simplify(pts)
                kind = 2 if highway in MAJOR else 0
                walk.append({"k": kind, "p": [[int(round(lat * 1e5)), int(round(lon * 1e5))] for lat, lon in simple]})
            continue
        closed = pts[0] == pts[-1] or _metres(pts[0][0], pts[0][1], pts[-1][0], pts[-1][1]) < 8
        if tags.get("natural") == "water" or tags.get("waterway") in {"river", "canal"} and closed and len(pts) >= 4:
            water.append(("poly", pts))
        elif tags.get("waterway"):
            water.append(("line", pts))
        elif tags.get("leisure") or tags.get("landuse"):
            if len(pts) >= 4:
                parks.append(pts)
    return parks, water, roads, walk


def _draw_zoom(zoom: int, parks, water, roads) -> dict[tuple[int, int], bytes]:
    scale = 256 * (2**zoom)
    xs, ys = _tile_span(zoom)
    tiles = {(tx, ty): bytearray(BG * (256 * 256)) for tx in xs for ty in ys}

    def tile_pts(pts: list[tuple[float, float]]) -> dict[tuple[int, int], list[tuple[float, float]]]:
        grouped: dict[tuple[int, int], list[tuple[float, float]]] = defaultdict(list)
        projected = [_project(lat, lon, scale) for lat, lon in pts]
        min_x = min(p[0] for p in projected)
        max_x = max(p[0] for p in projected)
        min_y = min(p[1] for p in projected)
        max_y = max(p[1] for p in projected)
        for tx in range(max(xs.start, int(min_x // 256)), min(xs.stop, int(max_x // 256) + 1)):
            for ty in range(max(ys.start, int(min_y // 256)), min(ys.stop, int(max_y // 256) + 1)):
                grouped[(tx, ty)] = [(px - tx * 256, py - ty * 256) for px, py in projected]
        return grouped

    for ring in parks:
        for key, pts in tile_pts(ring).items():
            buf = tiles.get(key)
            if buf is not None:
                _fill(buf, pts, PARK)
    for kind, ring in water:
        for key, pts in tile_pts(ring).items():
            buf = tiles.get(key)
            if buf is None:
                continue
            if kind == "poly":
                _fill(buf, pts, WATER)
            else:
                for a, b in zip(pts, pts[1:]):
                    _line(buf, a[0], a[1], b[0], b[1], WATER, 3 if zoom >= 13 else 2)

    # Casing, then fill, minor roads first.
    ordered = sorted(roads, key=lambda item: ROAD_STYLE[item[0]][2])
    for pass_fill in (False, True):
        for highway, pts in ordered:
            fill, casing, min_zoom, width = ROAD_STYLE[highway]
            if zoom < min_zoom:
                continue
            draw_width = 1 if zoom < 13 else width
            if zoom < width + min_zoom - 2:
                draw_width = max(1, draw_width - 1)
            color = fill if pass_fill else casing
            use_width = max(1, draw_width - 1) if pass_fill else draw_width + 1
            for key, local in tile_pts(pts).items():
                buf = tiles.get(key)
                if buf is None:
                    continue
                for a, b in zip(local, local[1:]):
                    if max(abs(a[0]), abs(a[1]), abs(b[0]), abs(b[1])) > 400 and (
                        (a[0] < -20 and b[0] < -20)
                        or (a[1] < -20 and b[1] < -20)
                        or (a[0] > 276 and b[0] > 276)
                        or (a[1] > 276 and b[1] > 276)
                    ):
                        continue
                    _line(buf, a[0], a[1], b[0], b[1], color, use_width)
    return {key: _png(256, 256, bytes(buf)) for key, buf in tiles.items()}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--osm", default="/tmp/pcmc-osm.json")
    args = parser.parse_args()
    source = Path(args.osm)
    if not source.exists():
        raise SystemExit(f"missing OSM extract {source}")
    parks, water, roads, walk = _load(source)
    ROADS.write_text(json.dumps({"roads": walk}, separators=(",", ":")), encoding="utf-8")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    if OUT.exists():
        OUT.unlink()
    db = sqlite3.connect(OUT)
    db.execute("CREATE TABLE metadata (name TEXT, value TEXT)")
    db.execute("CREATE TABLE tiles (zoom_level INTEGER, tile_column INTEGER, tile_row INTEGER, tile_data BLOB)")
    db.execute("CREATE UNIQUE INDEX tile_index ON tiles (zoom_level, tile_column, tile_row)")
    meta = {
        "name": "PCMC offline streets",
        "type": "baselayer",
        "version": "2",
        "description": "Offline street raster for the Pimpri-Chinchwad sample. Drawn from a local OSM extract. No tile URL.",
        "format": "png",
        "minzoom": "8",
        "maxzoom": "14",
        "bounds": f"{WEST},{SOUTH},{EAST},{NORTH}",
        "center": "73.82,18.66,13",
    }
    db.executemany("INSERT INTO metadata (name, value) VALUES (?, ?)", meta.items())
    count = 0
    for zoom in range(8, 15):
        drawn = _draw_zoom(zoom, parks, water, roads)
        for (tx, ty), png in drawn.items():
            tms_y = (2**zoom - 1) - ty
            db.execute(
                "INSERT INTO tiles (zoom_level, tile_column, tile_row, tile_data) VALUES (?, ?, ?, ?)",
                (zoom, tx, tms_y, png),
            )
            count += 1
        print(f"zoom {zoom}: {len(drawn)} tiles", flush=True)
    db.commit()
    db.close()
    print(f"wrote {count} tiles, {OUT.stat().st_size} bytes, roads {ROADS.stat().st_size} bytes")


if __name__ == "__main__":
    main()
