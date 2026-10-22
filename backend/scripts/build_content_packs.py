"""Build the immutable optional map archive used by the mobile Pack Manager.

Run during the backend image/build phase. It deliberately reads only the
allowlisted geo files; patient data, database files, and development artefacts
can never be packaged into a downloadable mobile content pack.
"""
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


def build_map_pack(source: Path, output: Path) -> None:
    missing = [name for name in MAP_FILES if not (source / name).is_file()]
    if missing:
        raise FileNotFoundError(
            f"Cannot build map pack; missing: {', '.join(missing)} in {source}"
        )
    output.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(output, "w", compression=ZIP_DEFLATED, compresslevel=9) as archive:
        for name in MAP_FILES:
            archive.write(source / name, arcname=name)


def build_language_packs(source: Path, output_directory: Path) -> None:
    output_directory.mkdir(parents=True, exist_ok=True)
    for code in LANGUAGE_CODES:
        source_file = source / f"app_{code}.arb"
        if not source_file.is_file():
            raise FileNotFoundError(f"Cannot build language pack; missing {source_file}")
        with ZipFile(output_directory / f"ui-{code}.zip", "w", compression=ZIP_DEFLATED) as archive:
            archive.write(source_file, arcname=source_file.name)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--language-source", type=Path, required=True)
    args = parser.parse_args()
    build_map_pack(args.source, args.output)
    build_language_packs(args.language_source, args.output.parent)


if __name__ == "__main__":
    main()
