#!/usr/bin/env python3
"""Run the required Golden suites and attest the exact montage source hashes."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

from verify_demo_pipeline import DEFAULT_MANIFEST, ROOT, ValidationError, validate_manifest


def _source_hash(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument(
        "--evidence",
        type=Path,
        default=Path("recordings/.recording-frames/demo-scene-evidence.json"),
    )
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    manifest_path = args.manifest.resolve()
    try:
        validate_manifest(manifest_path)
    except ValidationError as error:
        print(f"DEMO SCENE SOURCES INVALID: {error}")
        return 1
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    suites = manifest["sourceVerification"]["requiredSuites"]
    source_hashes = {
        scene["source"]: _source_hash(ROOT / scene["source"])
        for scene in manifest["featureScenes"]
    }
    if args.dry_run:
        print(f"scene-source plan: {len(source_hashes)} images · {len(suites)} Golden suites")
        return 0
    subprocess.run(
        ["flutter", "test", "--concurrency=1", "--reporter", "compact", *suites],
        cwd=ROOT,
        check=True,
    )
    evidence = {
        "schemaVersion": 1,
        "generatedAtUtc": datetime.now(timezone.utc).isoformat(),
        "manifest": str(manifest_path),
        "suites": suites,
        "sourceSha256": source_hashes,
    }
    args.evidence.parent.mkdir(parents=True, exist_ok=True)
    args.evidence.write_text(
        json.dumps(evidence, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"scene-source evidence written: {args.evidence} · {len(source_hashes)} current Golden hashes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
