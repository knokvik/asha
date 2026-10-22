"""Versioned downloadable content packs kept outside the mobile APK."""
from __future__ import annotations

import hashlib
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class ContentPack:
    """Public metadata for one checksum-addressed content archive."""

    id: str
    version: str
    archive: Path
    title: str

    @property
    def size_bytes(self) -> int:
        return self.archive.stat().st_size

    @property
    def sha256(self) -> str:
        digest = hashlib.sha256()
        with self.archive.open("rb") as archive:
            for chunk in iter(lambda: archive.read(1024 * 1024), b""):
                digest.update(chunk)
        return digest.hexdigest()

    def metadata(self, *, download_url: str) -> dict[str, object]:
        return {
            "id": self.id,
            "version": self.version,
            "title": self.title,
            "size_bytes": self.size_bytes,
            "sha256": self.sha256,
            "download_url": download_url,
        }


class ContentPackStore:
    """Looks up immutable archives prepared during the backend build.

    Archive creation is deliberately separate from serving: the app never
    receives arbitrary repository files, and an operator can replace a pack
    only by publishing a new, checksummed archive.
    """

    def __init__(self, root: Path | None = None) -> None:
        self.root = root or Path(__file__).resolve().parents[1] / "content_packs"

    _ui_language_codes = {
        "hi",
        "mr",
        "bn",
        "te",
        "ta",
        "kn",
        "ml",
        "or",
        "gu",
        "pa",
        "as",
    }

    def get(self, pack_id: str) -> ContentPack | None:
        # Keep the public surface intentionally allowlisted. Never turn this
        # endpoint into a generic file browser.
        if pack_id == "map-india":
            archive = self.root / "map-india.zip"
            title = "India facility and street map"
        elif pack_id.startswith("ui-") and pack_id.removeprefix("ui-") in self._ui_language_codes:
            archive = self.root / f"{pack_id}.zip"
            title = f"{pack_id.removeprefix('ui-').upper()} app language strings"
        else:
            return None
        if not archive.is_file():
            return None
        return ContentPack(
            id=pack_id,
            version="1",
            archive=archive,
            title=title,
        )

    def list(self) -> list[ContentPack]:
        ids = ["map-india", *(f"ui-{code}" for code in sorted(self._ui_language_codes))]
        return [pack for pack_id in ids if (pack := self.get(pack_id)) is not None]
