#!/usr/bin/env python3
"""Capture the dynamic portion of the fixed bouncy_01 gameplay demo.

This tool intentionally has no first-stage fallback.  Supply an action timeline
that has already opened the bouncy_01 deterministic demo route (or an equivalent
pre-seeded local build), review the resulting take, then pass
``--confirm-contract`` to emit the attestation consumed by the composer.
"""

from __future__ import annotations

import argparse
import asyncio
import json
import math
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from playwright.async_api import Page, async_playwright

from verify_demo_pipeline import DEFAULT_MANIFEST, ValidationError, validate_manifest


DEFAULT_ACTIONS = Path(__file__).resolve().parents[1] / "demo_bouncy_01_actions.json"


class TelemetryEvidenceError(RuntimeError):
    """Raised when the captured browser session does not prove the demo contract."""


def _read_actions(path: Path | None) -> list[dict[str, Any]]:
    if path is None:
        raise ValueError("a tracked bouncy_01 action timeline is required")
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, list) or not all(isinstance(item, dict) for item in raw):
        raise ValueError("action timeline must be a JSON array of action objects")
    return raw


def _timeline_duration_milliseconds(actions: list[dict[str, Any]]) -> int:
    """Bound the scripted setup so verified events occur within captured frames."""
    duration = 0
    for index, action in enumerate(actions):
        if action.get("type") != "wait":
            continue
        milliseconds = action.get("milliseconds", 0)
        if not isinstance(milliseconds, int) or milliseconds < 0:
            raise ValueError(f"action {index}: wait milliseconds must be a non-negative integer")
        duration += milliseconds
    return duration


async def _perform_actions(page: Page, actions: list[dict[str, Any]]) -> float:
    """Run deliberately small, reviewable mouse/wait steps from a JSON timeline."""
    for index, action in enumerate(actions):
        kind = action.get("type")
        if kind == "wait":
            milliseconds = int(action.get("milliseconds", 0))
            if milliseconds < 0:
                raise ValueError(f"action {index}: wait must be non-negative")
            await page.wait_for_timeout(milliseconds)
        elif kind == "click":
            await page.mouse.click(float(action["x"]), float(action["y"]))
        elif kind == "move":
            await page.mouse.move(float(action["x"]), float(action["y"]))
        elif kind == "down":
            if "x" in action or "y" in action:
                await page.mouse.move(float(action["x"]), float(action["y"]))
            await page.mouse.down()
        elif kind == "up":
            if "x" in action or "y" in action:
                await page.mouse.move(float(action["x"]), float(action["y"]))
            await page.mouse.up()
        elif kind == "click_role":
            role = str(action["role"])
            name = str(action["name"])
            try:
                # Flutter Web may omit the semantics DOM entirely.  Prefer the
                # reviewed label when present, but fall back quickly enough that
                # five missing roles cannot lengthen the 22-second take.
                await page.get_by_role(role, name=name, exact=True).click(timeout=50)
            except Exception:
                fallback = action.get("fallback")
                if not isinstance(fallback, dict):
                    raise ValueError(
                        f"action {index}: accessible {role}/{name!r} was unavailable and has no fallback"
                    )
                await page.mouse.click(float(fallback["x"]), float(fallback["y"]))
        elif kind == "press_key":
            await page.keyboard.press(str(action["key"]))
        else:
            raise ValueError(f"action {index}: unsupported type {kind!r}")
    return time.monotonic()


def _attestation(contract: dict[str, Any], source_url: str) -> dict[str, Any]:
    return {
        "demoPlanId": contract["demoPlanId"],
        "stageId": contract["stageId"],
        "patternId": contract["patternId"],
        "fixtureId": contract["fixtureId"],
        "aim": contract["aim"],
        "expectedEvents": contract["expectedEvents"],
        "directClear": False,
        "sourceUrl": source_url,
        "capturedAtUtc": datetime.now(timezone.utc).isoformat(),
    }


def _decode_json_value(value: object) -> object:
    """Unwrap the string value used by shared_preferences_web, if needed."""
    current = value
    for _ in range(2):
        if not isinstance(current, str):
            return current
        try:
            current = json.loads(current)
        except json.JSONDecodeError:
            return current
    return current


async def _read_persisted_telemetry(page: Page) -> list[dict[str, Any]]:
    entries = await page.evaluate("() => Object.entries(window.localStorage)")
    events: list[dict[str, Any]] = []
    for key, raw in entries:
        if "property_shot_local_play_log_v1" not in str(key):
            continue
        value = _decode_json_value(raw)
        if isinstance(value, list):
            events.extend(item for item in value if isinstance(item, dict))
    return events


def _event(events: list[dict[str, Any]], code: str, **required: object) -> dict[str, Any]:
    for event in events:
        if event.get("event_code") != code:
            continue
        if all(event.get(key) == value for key, value in required.items()):
            return event
    required_text = ", ".join(f"{key}={value!r}" for key, value in required.items())
    raise TelemetryEvidenceError(f"missing telemetry {code} ({required_text})")


def _event_time(event: dict[str, Any]) -> datetime:
    raw = event.get("시간")
    if not isinstance(raw, str):
        raise TelemetryEvidenceError("telemetry event is missing its timestamp")
    try:
        return datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError as error:
        raise TelemetryEvidenceError(f"invalid telemetry timestamp: {raw!r}") from error


def _validate_telemetry(
    events: list[dict[str, Any]],
    contract: dict[str, Any],
    *,
    capture_started_at: datetime,
) -> dict[str, Any]:
    """Validate the actual browser session, not merely the manifest values."""
    stage = contract["stageId"]
    pattern = contract["patternId"]
    context = {"stage_id": stage, "pattern_id": pattern}
    current_events = [
        event for event in events if _event_time(event) >= capture_started_at
    ]
    pattern_drawn = _event(current_events, "stage_pattern_drawn", **context)
    session_id = pattern_drawn.get("session_id")
    if not isinstance(session_id, str) or not session_id:
        raise TelemetryEvidenceError("stage-pattern telemetry has no session boundary")
    current_events = [
        event for event in current_events if event.get("session_id") == session_id
    ]
    _event(current_events, "property_transferred", **context)
    _event(
        current_events,
        "attribute_transferred",
        stage_id=stage,
        object_id=contract["traitSourceObjectId"],
        attribute_after="탄성",
    )
    _event(current_events, "key_collected", **context, key_id=contract["keyId"], key_collected=True)
    hint_l1 = _event(current_events, "hint_opened", **context, hint_level=1)
    hint_l2 = _event(current_events, "hint_level_opened", **context, hint_level=2)
    shot = _event(current_events, "shot_released", **context, telemetry_result="cleared")
    if abs(float(shot.get("힘", -1)) - contract["aim"]["power"]) > 0.001:
        raise TelemetryEvidenceError("clearing shot power is not the verified 0.90")
    expected_angle = math.radians(contract["aim"]["degrees"])
    if abs(float(shot.get("각도", 99)) - expected_angle) > math.radians(0.25):
        raise TelemetryEvidenceError("clearing shot angle is not the verified 48°")
    if "bouncy" not in shot.get("ball_traits", []):
        raise TelemetryEvidenceError("clearing shot did not carry the bouncy trait")
    if int(shot.get("wall_use_count", 0)) < contract["expectedEvents"].count("bounced"):
        raise TelemetryEvidenceError("clearing shot did not record all three required wall bounces")
    outcome = _event(current_events, "stage_cleared", **context, direct_clear=False)
    if outcome.get("shot_id") != shot.get("shot_id"):
        raise TelemetryEvidenceError("stage clear is not attributed to the verified clearing shot")
    if not (_event_time(hint_l1) <= _event_time(hint_l2) <= _event_time(outcome)):
        raise TelemetryEvidenceError("L1/L2 hints were not opened before the captured clear")
    gimmicks = set(outcome.get("gimmick_types", []))
    if not {"bouncy", "wall_reflection"}.issubset(gimmicks):
        raise TelemetryEvidenceError("stage outcome lacks the bouncy wall-reflection route")
    if any(event.get("event_code") == "demo_direct_clear_detected" for event in current_events):
        raise TelemetryEvidenceError("direct-clear detector fired during the bouncy demo")
    return {
        "eventCount": len(current_events),
        "sessionId": session_id,
        "captureStartedAtUtc": capture_started_at.isoformat(),
        "shotId": shot.get("shot_id"),
        "angleRadians": shot.get("각도"),
        "power": shot.get("힘"),
        "wallUseCount": shot.get("wall_use_count"),
        "directClear": outcome.get("direct_clear"),
        "gimmickTypes": sorted(gimmicks),
    }


async def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--url", required=True, help="pre-seeded bouncy_01 local or deployed demo URL")
    parser.add_argument(
        "--actions",
        type=Path,
        default=DEFAULT_ACTIONS,
        help="tracked JSON mouse/wait timeline (defaults to the bouncy_01 sequence)",
    )
    parser.add_argument(
        "--frames-dir", type=Path, default=Path("recordings/.recording-frames")
    )
    parser.add_argument(
        "--confirm-contract",
        action="store_true",
        help="write the bouncy_01 attestation after visually reviewing the recording setup",
    )
    args = parser.parse_args()
    manifest_path = args.manifest.resolve()
    try:
        validate_manifest(manifest_path)
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        actions = _read_actions(args.actions)
        timeline_ms = _timeline_duration_milliseconds(actions)
        capture_ms = manifest["browserCapture"]["durationSeconds"] * 1000
        # The final clear can settle for only 1.5–2.0 seconds.  A longer
        # tail would turn the browser portion into the very static popup the
        # submission video is meant to avoid.
        if timeline_ms > capture_ms - 1500:
            raise ValueError(
                "scripted waits alone leave less than 1.5 seconds before browser capture ends"
            )
    except (ValidationError, ValueError, json.JSONDecodeError) as error:
        print(f"DEMO RECORD INVALID: {error}")
        return 1
    if not args.confirm_contract:
        print(
            "DEMO RECORD REFUSED: review the bouncy_01 setup and rerun with "
            "--confirm-contract; first-stage/direct-clear capture is never accepted."
        )
        return 1

    video = manifest["video"]
    capture = manifest["browserCapture"]
    frame_count = video["fps"] * capture["durationSeconds"]
    args.frames_dir.mkdir(parents=True, exist_ok=True)
    for old in args.frames_dir.glob("frame-*.png"):
        old.unlink()
    errors: list[str] = []
    video_dir = args.frames_dir / ".playwright-video"
    video_dir.mkdir(parents=True, exist_ok=True)
    for old in video_dir.glob("*.webm"):
        old.unlink()
    async with async_playwright() as playwright:
        browser = await playwright.chromium.launch(headless=True)
        context = await browser.new_context(
            viewport={"width": video["width"], "height": video["height"]},
            device_scale_factor=1,
            record_video_dir=str(video_dir),
            record_video_size={"width": video["width"], "height": video["height"]},
        )
        page = await context.new_page()
        page_created_at = time.monotonic()
        video_artifact = page.video
        page.on(
            "console",
            lambda message: errors.append(message.text) if message.type == "error" else None,
        )
        await page.goto(args.url, wait_until="networkidle")
        # Retain progress needed by a pre-seeded demo route, but remove only
        # old telemetry so evidence cannot be borrowed from a prior session.
        await page.evaluate(
            "() => Object.keys(window.localStorage)"
            ".filter(key => key.includes('property_shot_local_play_log_v1'))"
            ".forEach(key => window.localStorage.removeItem(key))"
        )
        capture_started_at = datetime.now(timezone.utc)
        await page.reload(wait_until="networkidle")
        await page.wait_for_timeout(1200)
        started = time.monotonic()
        actions_task = asyncio.create_task(_perform_actions(page, actions))
        # Playwright records the compositor in real time. Per-frame PNG
        # screenshots are too slow for CanvasKit and turn a 22-second take
        # into minutes of duplicated clear-popup frames.
        await page.wait_for_timeout(capture["durationSeconds"] * 1000)
        actions_finished_at = await actions_task
        tail_seconds = capture["durationSeconds"] - (actions_finished_at - started)
        if not 1.5 <= tail_seconds <= 2.0:
            await browser.close()
            print(
                "DEMO RECORD INVALID: actual action timeline left "
                f"{tail_seconds:.3f}s of browser capture; expected 1.5–2.0s"
            )
            return 1
        await page.wait_for_timeout(850)
        if errors:
            await browser.close()
            print(
                "DEMO RECORD INVALID: browser console errors: "
                + " | ".join(errors[:8])
            )
            return 1
        telemetry_events = await _read_persisted_telemetry(page)
        try:
            evidence = _validate_telemetry(
                telemetry_events,
                manifest["contract"],
                capture_started_at=capture_started_at,
            )
        except TelemetryEvidenceError as error:
            await browser.close()
            print(f"DEMO RECORD INVALID: {error}")
            return 1
        (args.frames_dir / "demo-telemetry.json").write_text(
            json.dumps(telemetry_events, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        evidence["captureTailSeconds"] = round(tail_seconds, 3)
        await context.close()
        if video_artifact is None:
            await browser.close()
            print("DEMO RECORD INVALID: Playwright did not create a video artifact")
            return 1
        webm_path = await video_artifact.path()
        await browser.close()

    ffmpeg_candidates = sorted(
        Path.home().glob("Library/Caches/ms-playwright/ffmpeg-*/ffmpeg-mac"),
        reverse=True,
    )
    if not ffmpeg_candidates:
        print("DEMO RECORD INVALID: Playwright ffmpeg executable is missing")
        return 1
    capture_offset = max(0.0, started - page_created_at)
    subprocess.run(
        [
            str(ffmpeg_candidates[0]),
            "-y",
            "-ss",
            f"{capture_offset:.3f}",
            "-i",
            str(webm_path),
            "-r",
            str(video["fps"]),
            "-frames:v",
            str(frame_count),
            "-start_number",
            "0",
            str(args.frames_dir / "frame-%05d.png"),
        ],
        check=True,
    )
    extracted = len(list(args.frames_dir.glob("frame-*.png")))
    if extracted != frame_count:
        print(
            f"DEMO RECORD INVALID: expected {frame_count} extracted real-time frames, found {extracted}"
        )
        return 1

    attestation = _attestation(manifest["contract"], args.url)
    attestation["telemetryEvidence"] = evidence
    (args.frames_dir / "demo-attestation.json").write_text(
        json.dumps(attestation, ensure_ascii=False, indent=2)
        + "\n",
        encoding="utf-8",
    )
    print(
        f"bouncy_01 capture complete: {frame_count} frames · "
        f"{capture['durationSeconds']}s · {video['fps']}fps · console errors {len(errors)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
