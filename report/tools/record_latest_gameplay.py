#!/usr/bin/env python3
"""Run the guarded bouncy_01 capture → compose → H.264 MOV pipeline."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TOOLS = ROOT / "report" / "tools"


def _run(command: list[str]) -> None:
    subprocess.run(command, cwd=ROOT, check=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", help="pre-seeded bouncy_01 local or deployed demo URL")
    parser.add_argument(
        "--actions",
        type=Path,
        default=ROOT / "report" / "demo_bouncy_01_actions.json",
        help="reviewed JSON interaction timeline",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("recordings/property-shot-gameplay-60s.mov"),
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="verify the fixed plan and 60-second scene budget without recording",
    )
    parser.add_argument(
        "--confirm-contract",
        action="store_true",
        help="required after reviewing the bouncy_01 fixture, key, L1/L2, and non-direct route",
    )
    args = parser.parse_args()

    if args.dry_run:
        _run([sys.executable, str(TOOLS / "verify_demo_pipeline.py")])
        actions = json.loads(args.actions.read_text(encoding="utf-8"))
        wait_budget = sum(
            action.get("milliseconds", 0)
            for action in actions
            if action.get("type") == "wait"
        )
        if wait_budget > 20_500:
            raise SystemExit(
                "DEMO PIPELINE INVALID: scripted waits alone leave less than 1.5 seconds in a 22-second capture"
            )
        print(
            f"action wait budget valid: {wait_budget / 1000:.3f}s; "
            "the recorder verifies actual 1.5–2.0s ending slack"
        )
        _run([sys.executable, str(TOOLS / "compose_gameplay_demo_frames.py"), "--dry-run"])
        return 0
    if not args.url or not args.confirm_contract:
        parser.error(
            "--url and --confirm-contract are required; the old first-stage direct-clear recorder is intentionally disabled"
        )

    # Create a source-hash proof only after the exact Golden suites pass.  The
    # composer checks this proof again, preventing old baseline images from
    # being mixed with the fresh browser take.
    _run(
        [
            sys.executable,
            str(TOOLS / "verify_demo_scene_sources.py"),
            "--evidence",
            "recordings/.recording-frames/demo-scene-evidence.json",
        ]
    )
    _run(
        [
            sys.executable,
            str(TOOLS / "record_gameplay_frames.py"),
            "--url",
            args.url,
            "--actions",
            str(args.actions),
            "--confirm-contract",
        ]
    )
    _run([sys.executable, str(TOOLS / "compose_gameplay_demo_frames.py")])
    _run(
        [
            "swift",
            str(TOOLS / "encode_png_frames.swift"),
            "recordings/.demo-frames",
            "8",
            str(args.output),
        ]
    )
    _run(["swift", str(TOOLS / "verify_demo_video.swift"), str(args.output)])
    print(f"submission demo complete: {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
