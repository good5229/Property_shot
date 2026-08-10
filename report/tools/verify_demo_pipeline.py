#!/usr/bin/env python3
"""Validate the deterministic gameplay-demo contract before recording or encoding.

This deliberately validates the source-level plan and data catalog as well as the
video scene list.  A video may not be composed from an arbitrary first-stage
capture: its gameplay take must be attested to the ``demo_bouncy_01_v1`` contract.
"""

from __future__ import annotations

import argparse
import json
import re
import struct
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MANIFEST = ROOT / "report" / "demo_playback_manifest.json"
PLAN_SOURCE = ROOT / "lib" / "game" / "hint" / "demo_playback_plan.dart"
HINT_CATALOG = ROOT / "assets" / "stages" / "hints_v1.json"


class ValidationError(RuntimeError):
    """Raised when a submission-video prerequisite does not hold."""


def _read_json(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise ValidationError(f"missing required file: {path}") from error
    except json.JSONDecodeError as error:
        raise ValidationError(f"invalid JSON: {path}: {error}") from error


def _png_size(path: Path) -> tuple[int, int]:
    try:
        data = path.read_bytes()
    except FileNotFoundError as error:
        raise ValidationError(f"missing feature scene: {path}") from error
    if data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise ValidationError(f"not a readable PNG: {path}")
    return struct.unpack(">II", data[16:24])


def _dart_plan_contract() -> dict[str, Any]:
    try:
        source = PLAN_SOURCE.read_text(encoding="utf-8")
    except FileNotFoundError as error:
        raise ValidationError(f"missing demo plan source: {PLAN_SOURCE}") from error
    block_match = re.search(
        r"const\s+stageBouncy01DemoPlaybackPlan\s*=\s*DemoPlaybackPlan\((.*?)\n\);",
        source,
        flags=re.DOTALL,
    )
    if not block_match:
        raise ValidationError("stageBouncy01DemoPlaybackPlan constant is missing")
    block = block_match.group(1)
    values: dict[str, str] = {}
    for field in ("id", "stageId", "patternId", "fixtureId"):
        match = re.search(rf"{field}:\s*'([^']+)'", block)
        if not match:
            raise ValidationError(f"demo plan field missing: {field}")
        values[field] = match.group(1)
    events_match = re.search(r"expectedEvents:\s*\[([^\]]+)\]", block)
    if not events_match:
        raise ValidationError("demo plan expectedEvents missing")
    values["expectedEvents"] = re.findall(r"'([^']+)'", events_match.group(1))
    return values


def _hint_entry(catalog: dict[str, Any], stage_id: str, pattern_id: str) -> dict[str, Any]:
    for entry in catalog.get("entries", []):
        if entry.get("stageId") == stage_id and entry.get("patternId") == pattern_id:
            return entry
    raise ValidationError(f"hint catalog has no entry for {stage_id}/{pattern_id}")


def validate_manifest(manifest_path: Path) -> list[str]:
    manifest = _read_json(manifest_path)
    if manifest.get("manifestVersion") != 1:
        raise ValidationError("unsupported demo manifest version")
    contract = manifest.get("contract")
    video = manifest.get("video")
    scenes = manifest.get("featureScenes")
    browser = manifest.get("browserCapture")
    source_verification = manifest.get("sourceVerification")
    if not isinstance(contract, dict) or not isinstance(video, dict):
        raise ValidationError("manifest needs contract and video objects")
    if (
        not isinstance(scenes, list)
        or not isinstance(browser, dict)
        or not isinstance(source_verification, dict)
    ):
        raise ValidationError("manifest needs featureScenes, browserCapture, and sourceVerification")

    plan = _dart_plan_contract()
    for key in ("demoPlanId", "stageId", "patternId", "fixtureId"):
        plan_key = "id" if key == "demoPlanId" else key
        if contract.get(key) != plan.get(plan_key):
            raise ValidationError(
                f"manifest {key}={contract.get(key)!r} does not match Dart plan {plan.get(plan_key)!r}"
            )
    if contract.get("expectedEvents") != plan.get("expectedEvents"):
        raise ValidationError("manifest expectedEvents does not match the Dart demo plan")
    if contract.get("forbiddenEvents") != ["direct_clear"]:
        raise ValidationError("direct_clear must be forbidden for this demo")
    if contract.get("aim") != {"degrees": 48, "power": 0.9}:
        raise ValidationError("demo aim must remain the verified 48° / 0.90 fixture")
    if contract.get("launchControlLabel") != "검증된 48도 90퍼센트 시연 발사":
        raise ValidationError("demo must use the exact-input launch control")

    if (video.get("width"), video.get("height"), video.get("fps")) != (390, 844, 8):
        raise ValidationError("video must remain 390x844 at 8fps")
    if video.get("codec") != "h264" or video.get("container") != "mov":
        raise ValidationError("video must be H.264 MOV")
    if video.get("orientation") != "identity":
        raise ValidationError("video orientation must be identity (no mirror or rotation)")

    expected_feature_ids = {
        "key-locked-compact",
        "key-locked",
        "key-locked-reduced-motion",
        "key-collected",
        "key-collected-hidden",
        "hint-available",
        "hint-level-1",
        "hint-level-2",
        "compact-next-hint-reward",
        "reward-icon-set",
        "reward-compact-layout",
        "reward-options-4-6",
        "reward-options-6-8",
        "charge-green",
        "charge-yellow",
        "charge-red",
        "charge-warning",
        "charge-cancelled",
        "gauge-avoids-key",
    }
    actual_ids = {scene.get("id") for scene in scenes if isinstance(scene, dict)}
    if actual_ids != expected_feature_ids:
        raise ValidationError("feature scene IDs differ from the required bouncy/key/hint/reward set")
    required_suites = source_verification.get("requiredSuites")
    expected_suites = {
        "test/hint_key_ui_golden_test.dart",
        "test/hint_ui_widget_test.dart",
        "test/run_reward_selection_widget_test.dart",
        "test/charge_gauge_golden_test.dart",
    }
    if not isinstance(required_suites, list) or set(required_suites) != expected_suites:
        raise ValidationError("feature sources must declare the current targeted Golden suites")
    feature_seconds = 0
    for scene in scenes:
        if not isinstance(scene, dict):
            raise ValidationError("feature scene must be an object")
        seconds = scene.get("seconds")
        if not isinstance(seconds, int) or not 1 <= seconds <= 2:
            raise ValidationError(f"feature scene {scene.get('id')!r} must last 1–2 seconds")
        source = ROOT / str(scene.get("source", ""))
        width, height = _png_size(source)
        if width > video["width"] or height > video["height"]:
            raise ValidationError(f"feature scene exceeds video canvas: {source} ({width}x{height})")
        feature_seconds += seconds

    browser_seconds = browser.get("durationSeconds")
    if browser_seconds != 22 or browser.get("requiredPlanId") != contract["demoPlanId"]:
        raise ValidationError("browser capture must be a 22-second attested bouncy plan take")
    if len(scenes) != 19 or feature_seconds != 38:
        raise ValidationError("the montage must have 19 distinct two-second feature scenes")
    if browser_seconds + feature_seconds != video.get("durationSeconds"):
        raise ValidationError("browser capture + feature scenes must total exactly 60 seconds")

    catalog = _read_json(HINT_CATALOG)
    entry = _hint_entry(catalog, contract["stageId"], contract["patternId"])
    if entry.get("key", {}).get("id") != contract.get("keyId"):
        raise ValidationError("manifest keyId does not match the bouncy hint key")
    if entry.get("directClearPolicy", {}).get("allowed") is not False:
        raise ValidationError("bouncy demo catalog must reject direct clear")
    if [hint.get("level") for hint in entry.get("hints", [])] != contract.get("hintLevels"):
        raise ValidationError("manifest hint levels do not match the bouncy hint catalog")

    return [
        f"contract {contract['demoPlanId']} · {contract['stageId']}/{contract['patternId']}",
        f"fixture {contract['fixtureId']} · 48° / 0.90 · events {', '.join(contract['expectedEvents'])}",
        f"{len(scenes)} distinct feature scenes × 2s + {browser_seconds}s browser take = {video['durationSeconds']}s",
        "H.264 MOV 390x844@8fps · identity orientation",
    ]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    args = parser.parse_args()
    try:
        lines = validate_manifest(args.manifest.resolve())
    except ValidationError as error:
        print(f"DEMO PIPELINE INVALID: {error}", file=sys.stderr)
        return 1
    print("DEMO PIPELINE VALID")
    for line in lines:
        print(f"- {line}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
