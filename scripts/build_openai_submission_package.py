#!/usr/bin/env python3
"""Validate and freeze the OpenAI Game Builders Track 1 upload bundle."""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
import urllib.parse
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "submission" / "openai_game_builders_track1"
DEFAULT_OUTPUT = ROOT / "submission" / "Property_Shot_OpenAI_Game_Builders_Track1.zip"
REQUIRED_FILES = (
    "track1_thumbnail_1920x1080.png",
    "submission_fields_ko.md",
    "challenge_period_manifest.json",
    "validation-summary.json",
)
FORBIDDEN_LOCAL_MARKERS = ("/Users/", "file://", ".codex/", "\\Users\\")


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as stream:
        header = stream.read(24)
    if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise ValueError(f"PNG header is invalid: {path.name}")
    return struct.unpack(">II", header[16:24])


def validate(source_dir: Path = SOURCE_DIR) -> dict[str, str]:
    missing = [name for name in REQUIRED_FILES if not (source_dir / name).is_file()]
    if missing:
        raise ValueError("Missing submission files: " + ", ".join(missing))

    thumbnail = source_dir / REQUIRED_FILES[0]
    if _png_dimensions(thumbnail) != (1920, 1080):
        raise ValueError("Thumbnail must be exactly 1920x1080 (16:9).")
    if thumbnail.stat().st_size > 10 * 1024 * 1024:
        raise ValueError("Thumbnail exceeds the official 10MB recommendation.")

    manifest = json.loads((source_dir / "challenge_period_manifest.json").read_text(encoding="utf-8"))
    fields = manifest.get("submission", {})
    required_fields = {
        "gameTitle",
        "teamName",
        "gameIntro",
        "playUrl",
    }
    absent = sorted(required_fields - fields.keys())
    if absent:
        raise ValueError("Missing form fields: " + ", ".join(absent))
    if not 1 <= len(fields["gameIntro"]) <= 200:
        raise ValueError(f"Game intro must be 1-200 characters: {len(fields['gameIntro'])}")
    parsed = urllib.parse.urlparse(fields["playUrl"])
    if parsed.scheme != "https" or not parsed.netloc:
        raise ValueError("Play URL must be a public HTTPS URL.")

    for name in REQUIRED_FILES[1:]:
        text = (source_dir / name).read_text(encoding="utf-8")
        marker = next((value for value in FORBIDDEN_LOCAL_MARKERS if value in text), None)
        if marker is not None:
            raise ValueError(f"Local path marker {marker!r} found in {name}.")
    return {name: _sha256(source_dir / name) for name in REQUIRED_FILES}


def build(output: Path = DEFAULT_OUTPUT, source_dir: Path = SOURCE_DIR) -> Path:
    checksums = validate(source_dir)
    manifest = "".join(f"{digest}  {name}\n" for name, digest in checksums.items())
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name in REQUIRED_FILES:
            info = zipfile.ZipInfo(name, date_time=(2026, 8, 25, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            archive.writestr(info, (source_dir / name).read_bytes(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
        info = zipfile.ZipInfo("SHA256SUMS.txt", date_time=(2026, 8, 25, 0, 0, 0))
        info.compress_type = zipfile.ZIP_DEFLATED
        info.external_attr = 0o644 << 16
        archive.writestr(info, manifest.encode("utf-8"), compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
    return output


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-dir", type=Path, default=SOURCE_DIR)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--verify-only", action="store_true")
    args = parser.parse_args()
    checksums = validate(args.source_dir)
    if args.verify_only:
        print(json.dumps({"passed": True, "checksums": checksums}, ensure_ascii=False, indent=2))
        return 0
    output = build(args.output, args.source_dir)
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
