#!/usr/bin/env python3
"""Evaluate the Web release proxy without presenting it as field INP evidence."""

import argparse
import json
from pathlib import Path


REQUIRED_VIEWPORTS = {(320, 568), (390, 844), (768, 1024), (1440, 900), (1920, 1080)}
INTERACTIVE_VIEWPORTS = {(390, 844), (768, 1024)}
MAX_SHOT_P95_MS = 25
MAX_SHOT_P99_MS = 100
MAX_SHOT_FRAME_MS = 600
MAX_SHOT_OVER_50_RATIO = 0.02
MAX_SHOT_LONG_TASK_MS = 600
MAX_TOTAL_BUILD_BYTES = 80 * 1024 * 1024
MAX_APP_PAYLOAD_BYTES = 30 * 1024 * 1024
MAX_MAIN_JS_BYTES = 8 * 1024 * 1024
MAX_RASTER_BYTES = 2 * 1024 * 1024


def evaluate(performance: dict, build_dir: Path) -> dict:
    failures: list[str] = []
    records = performance.get("records")
    if not isinstance(records, list):
        records = []
        failures.append("performance_records_missing")
    by_viewport = {}
    for record in records:
        if not isinstance(record, dict) or not isinstance(record.get("viewport"), dict):
            continue
        viewport = record["viewport"]
        key = (viewport.get("width"), viewport.get("height"))
        by_viewport[key] = record
    missing = sorted(REQUIRED_VIEWPORTS - set(by_viewport))
    if missing:
        failures.append("missing_viewports:" + ",".join(f"{w}x{h}" for w, h in missing))

    viewport_results = []
    for viewport in sorted(REQUIRED_VIEWPORTS):
        record = by_viewport.get(viewport)
        if record is None:
            continue
        local_failures = []
        if record.get("console_errors"):
            local_failures.append("console_errors")
        if viewport in INTERACTIVE_VIEWPORTS:
            idle = record.get("idle") if isinstance(record.get("idle"), dict) else {}
            if idle.get("p99_ms") is None or idle.get("p99_ms") > 50:
                local_failures.append("idle_p99_over_50ms")
            if idle.get("over_50ms_count", 0) > 0:
                local_failures.append("idle_over_50ms")
            if record.get("idle_long_tasks"):
                local_failures.append("idle_long_task")
            if record.get("interactive_shot_proxy") is not True:
                local_failures.append("shot_proxy_missing")
            shot = record.get("shot") if isinstance(record.get("shot"), dict) else {}
            if shot.get("p95_ms") is None or shot.get("p95_ms") > MAX_SHOT_P95_MS:
                local_failures.append("shot_p95_over_25ms")
            if shot.get("p99_ms") is None or shot.get("p99_ms") > MAX_SHOT_P99_MS:
                local_failures.append("shot_p99_over_100ms")
            if shot.get("max_ms") is None or shot.get("max_ms") > MAX_SHOT_FRAME_MS:
                local_failures.append("shot_frame_over_600ms")
            if (
                shot.get("over_50ms_ratio") is None
                or shot.get("over_50ms_ratio") > MAX_SHOT_OVER_50_RATIO
            ):
                local_failures.append("shot_over_50ms_ratio_over_2pct")
            shot_long_tasks = record.get("shot_long_tasks")
            if not isinstance(shot_long_tasks, list):
                local_failures.append("shot_long_tasks_missing")
            elif any(
                task.get("duration_ms", 0) > MAX_SHOT_LONG_TASK_MS
                for task in shot_long_tasks
                if isinstance(task, dict)
            ):
                local_failures.append("shot_long_task_over_600ms")
        if local_failures:
            failures.extend(f"{viewport[0]}x{viewport[1]}:{item}" for item in local_failures)
        viewport_results.append(
            {
                "viewport": f"{viewport[0]}x{viewport[1]}",
                "interactive_shot_proxy": viewport in INTERACTIVE_VIEWPORTS,
                "passed": not local_failures,
                "failures": local_failures,
            }
        )

    files = [path for path in build_dir.rglob("*") if path.is_file()]
    total_bytes = sum(path.stat().st_size for path in files)
    app_files = [
        path
        for path in files
        if not path.relative_to(build_dir).parts[0] == "canvaskit"
    ]
    app_payload_bytes = sum(path.stat().st_size for path in app_files)
    main_js = build_dir / "main.dart.js"
    main_js_bytes = main_js.stat().st_size if main_js.is_file() else None
    rasters = [
        path
        for path in files
        if path.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"}
    ]
    largest_raster = max(rasters, key=lambda path: path.stat().st_size, default=None)
    largest_raster_bytes = largest_raster.stat().st_size if largest_raster else 0
    if not build_dir.is_dir():
        failures.append("build_directory_missing")
    if total_bytes > MAX_TOTAL_BUILD_BYTES:
        failures.append("total_build_over_80mb")
    if app_payload_bytes > MAX_APP_PAYLOAD_BYTES:
        failures.append("app_payload_over_30mb")
    if main_js_bytes is None:
        failures.append("main_dart_js_missing")
    elif main_js_bytes > MAX_MAIN_JS_BYTES:
        failures.append("main_dart_js_over_8mb")
    if largest_raster_bytes > MAX_RASTER_BYTES:
        failures.append("largest_raster_over_2mb")

    return {
        "passed": not failures,
        "measurement_scope": (
            "Headless Chromium console proxy at five viewports and rAF proxy at "
            "390x844/768x1024. Not field INP, physical-device frame time, GPU time, "
            "touch latency, sound, or haptic evidence. Interactive acceptance uses "
            "p95/p99 and bounded-jank ratios; it permits a bounded first CanvasKit "
            "ImageBitmap transfer but fails sustained or over-600ms stalls."
        ),
        "viewport_results": viewport_results,
        "assets": {
            "total_build_bytes": total_bytes,
            "app_payload_bytes": app_payload_bytes,
            "app_payload_scope": "all release files except Flutter canvaskit renderer variants",
            "main_dart_js_bytes": main_js_bytes,
            "largest_raster": None
            if largest_raster is None
            else str(largest_raster.relative_to(build_dir)),
            "largest_raster_bytes": largest_raster_bytes,
        },
        "failures": failures,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--performance", type=Path, action="append", required=True)
    parser.add_argument("--build-dir", type=Path, default=Path("build/web"))
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    sources = [json.loads(path.read_text()) for path in args.performance]
    performance = {
        "records": [
            record
            for source in sources
            for record in source.get("records", [])
        ]
    }
    result = evaluate(performance, args.build_dir)
    result["performance_sources"] = [str(path) for path in args.performance]
    encoded = json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    if args.output is not None:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded)
    print(encoded, end="")
    return 0 if result["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
