"""Build the optional mobile content archives for the standalone Render service."""
from __future__ import annotations

import argparse
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

MAP_FILES = (
    "facilities.geojson",
    "india_facilities.json",
    "india_states.geojson",
    "households.json",
    "referrals.json",
    "roads.json",
    "labels.json",
    "pcmc.mbtiles",
)
LANGUAGE_CODES = ("hi", "mr", "bn", "te", "ta", "kn", "ml", "or", "gu", "pa", "as")


def build(source: Path, language_source: Path, output: Path) -> None:
    missing = [name for name in MAP_FILES if not (source / name).is_file()]
    if missing:
        raise FileNotFoundError(f"Missing map files: {', '.join(missing)}")
    output.mkdir(parents=True, exist_ok=True)
    with ZipFile(output / "map-india.zip", "w", ZIP_DEFLATED, compresslevel=9) as archive:
        for name in MAP_FILES:
            archive.write(source / name, arcname=name)
    for code in LANGUAGE_CODES:
        arb = language_source / f"app_{code}.arb"
        if not arb.is_file():
            raise FileNotFoundError(f"Missing language file: {arb}")
        with ZipFile(output / f"ui-{code}.zip", "w", ZIP_DEFLATED) as archive:
            archive.write(arb, arcname=arb.name)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--language-source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    build(args.source, args.language_source, args.output)
