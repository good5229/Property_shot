#!/usr/bin/env python3
"""Measure Web requestAnimationFrame timing around a real play flow.

This is a Chromium/Web proxy. It is deliberately not presented as iPhone or
iPad performance evidence.
"""

import argparse
import json
import math
import statistics
from datetime import datetime, timezone
from pathlib import Path

from playwright.sync_api import sync_playwright


VIEWPORTS = ((390, 844), (768, 1024), (320, 568), (1440, 900), (1920, 1080))
INTERACTIVE_VIEWPORTS = {(390, 844), (768, 1024)}
# 390x844 핵심 체험에서 검증된 입력점을 게임판 비율로 보존한다.
LAUNCH_POINT_RATIO = (60 / 390, (580 - 106) / 606.65625)
CORE_EXPERIENCE_POINTS = {
    (320, 568): (160.0, 376.0),
    (390, 844): (195.0, 537.0),
    (768, 1024): (564.0, 461.0),
    (1440, 900): (1010.0, 391.0),
    (1920, 1080): (1250.0, 481.0),
}


def _measure_frames(page, duration_ms: int) -> list[float]:
    return page.evaluate(
        """
        duration => new Promise(resolve => {
          const start = performance.now();
          let previous = null;
          const samples = [];
          const frame = now => {
            if (previous !== null) samples.push(now - previous);
            previous = now;
            if (now - start >= duration) resolve(samples);
            else requestAnimationFrame(frame);
          };
          requestAnimationFrame(frame);
        })
        """,
        duration_ms,
    )


def _start_frame_capture(page) -> None:
    page.evaluate(
        """
        () => {
          window.__propertyShotFrameSamples = [];
          window.__propertyShotPreviousFrame = null;
          const frame = now => {
            if (window.__propertyShotPreviousFrame !== null) {
              window.__propertyShotFrameSamples.push(
                now - window.__propertyShotPreviousFrame
              );
            }
            window.__propertyShotPreviousFrame = now;
            window.__propertyShotFrameCapture = requestAnimationFrame(frame);
          };
          window.__propertyShotFrameCapture = requestAnimationFrame(frame);
        }
        """
    )


def _stop_frame_capture(page) -> list[float]:
    return page.evaluate(
        """
        () => {
          cancelAnimationFrame(window.__propertyShotFrameCapture);
          const samples = window.__propertyShotFrameSamples || [];
          window.__propertyShotFrameSamples = [];
          window.__propertyShotPreviousFrame = null;
          return samples;
        }
        """
    )


def _start_long_task_capture(page) -> None:
    page.evaluate(
        """
        () => {
          window.__propertyShotLongTasks = [];
          if (!('PerformanceObserver' in window)) return;
          const observer = new PerformanceObserver(list => {
            for (const entry of list.getEntries()) {
              window.__propertyShotLongTasks.push({
                duration_ms: entry.duration,
                start_ms: entry.startTime,
              });
            }
          });
          try {
            observer.observe({type: 'longtask'});
            window.__propertyShotLongTaskObserver = observer;
          } catch (_) {
            window.__propertyShotLongTasks = [];
          }
        }
        """
    )


def _drain_long_tasks(page) -> list[dict[str, float]]:
    return page.evaluate(
        """
        () => {
          const tasks = window.__propertyShotLongTasks || [];
          window.__propertyShotLongTasks = [];
          return tasks;
        }
        """
    )


def _stats(samples: list[float]) -> dict[str, float | int | None]:
    if not samples:
        return {
            "samples": 0,
            "mean_ms": None,
            "median_ms": None,
            "p90_ms": None,
            "p95_ms": None,
            "p99_ms": None,
            "max_ms": None,
            "over_20ms_ratio": None,
            "over_50ms_count": 0,
            "over_50ms_ratio": None,
            "missed_vsync_count": 0,
            "missed_vsync_ratio": None,
        }
    ordered = sorted(samples)

    def percentile(ratio: float) -> float:
        index = min(len(ordered) - 1, max(0, math.ceil(len(ordered) * ratio) - 1))
        return round(ordered[index], 3)

    over_50ms_count = sum(value > 50 for value in samples)
    cadence = statistics.median(samples)
    missed_vsync_count = sum(value > cadence * 1.5 for value in samples)
    return {
        "samples": len(samples),
        "mean_ms": round(statistics.fmean(samples), 3),
        "median_ms": round(cadence, 3),
        "p90_ms": percentile(0.90),
        "p95_ms": percentile(0.95),
        "p99_ms": percentile(0.99),
        "max_ms": round(max(samples), 3),
        "over_20ms_ratio": round(sum(value > 20 for value in samples) / len(samples), 4),
        "over_50ms_count": over_50ms_count,
        "over_50ms_ratio": round(over_50ms_count / len(samples), 4),
        "missed_vsync_count": missed_vsync_count,
        "missed_vsync_ratio": round(missed_vsync_count / len(samples), 4),
    }


def _aggregate_trials(trials: list[dict], section: str) -> dict:
    samples = [
        sample
        for trial in trials
        for sample in trial[f"{section}_samples"]
    ]
    return _stats(samples)


def _viewport(value: str) -> tuple[int, int]:
    try:
        width_text, height_text = value.lower().split("x", maxsplit=1)
        viewport = (int(width_text), int(height_text))
    except (TypeError, ValueError):
        raise argparse.ArgumentTypeError("뷰포트는 390x844 형식이어야 합니다.")
    if viewport not in VIEWPORTS:
        choices = ", ".join(f"{width}x{height}" for width, height in VIEWPORTS)
        raise argparse.ArgumentTypeError(f"지원 뷰포트: {choices}")
    return viewport


def _gameplay_bounds(browser, url: str, viewport: tuple[int, int]) -> dict[str, float]:
    width, height = viewport
    context = browser.new_context(viewport={"width": width, "height": height})
    try:
        page = context.new_page()
        page.goto(url)
        page.wait_for_timeout(3000)
        page.mouse.click(*CORE_EXPERIENCE_POINTS[viewport])
        page.wait_for_timeout(3000)
        placeholder = page.locator("flt-semantics-placeholder")
        if placeholder.count() > 0:
            placeholder.evaluate("node => node.click()")
            page.wait_for_timeout(500)
        bounds = page.locator(
            '[aria-label="공을 조준하는 게임 화면"]'
        ).bounding_box()
        if bounds is None:
            raise RuntimeError(
                f"{width}x{height}에서 핵심 체험 게임판 접근성 경계를 찾지 못했습니다."
            )
        return {key: round(float(value), 3) for key, value in bounds.items()}
    finally:
        context.close()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", default="http://127.0.0.1:8080/")
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("harness_docs/qa/web_performance_latest.json"),
    )
    parser.add_argument("--page-warmup-ms", type=int, default=5000)
    parser.add_argument("--play-warmup-ms", type=int, default=5000)
    parser.add_argument("--repetitions", type=int, default=3)
    parser.add_argument(
        "--viewport",
        action="append",
        type=_viewport,
        help="특정 뷰포트만 격리 재측정합니다. 여러 번 지정할 수 있습니다.",
    )
    args = parser.parse_args()
    if args.repetitions < 1:
        parser.error("반복 횟수는 1 이상이어야 합니다.")

    records = []
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True)
        for width, height in args.viewport or VIEWPORTS:
            viewport = (width, height)
            gameplay_bounds = _gameplay_bounds(browser, args.url, viewport)
            launch_point = None
            if viewport in INTERACTIVE_VIEWPORTS:
                launch_point = (
                    gameplay_bounds["x"]
                    + gameplay_bounds["width"] * LAUNCH_POINT_RATIO[0],
                    gameplay_bounds["y"]
                    + gameplay_bounds["height"] * LAUNCH_POINT_RATIO[1],
                )
            trials = []
            for trial_index in range(args.repetitions):
                context = browser.new_context(
                    viewport={"width": width, "height": height},
                    device_scale_factor=1,
                )
                page = context.new_page()
                errors: list[str] = []
                page.on(
                    "console",
                    lambda message, errors=errors: errors.append(message.text)
                    if message.type == "error"
                    else None,
                )
                page.goto(args.url)
                page.wait_for_timeout(args.page_warmup_ms)
                # 모든 뷰포트가 같은 60초 핵심 체험을 측정해야 한다. 기존의
                # 주황 버튼 색상 탐지는 2열 홈에서 다른 행동을 고를 수 있어
                # 반응형 Golden으로 검증된 좌표를 사용한다.
                start = CORE_EXPERIENCE_POINTS[(width, height)]
                page.mouse.click(*start)
                page.wait_for_timeout(args.play_warmup_ms)
                _start_long_task_capture(page)

                idle = _measure_frames(page, 1800)
                idle_long_tasks = _drain_long_tasks(page)

                if launch_point is None:
                    shot = []
                    shot_long_tasks = []
                else:
                    _start_frame_capture(page)
                    page.mouse.move(*launch_point)
                    page.mouse.down()
                    page.wait_for_timeout(650)
                    page.mouse.up()
                    page.wait_for_timeout(2500)
                    shot = _stop_frame_capture(page)
                    shot_long_tasks = _drain_long_tasks(page)
                trials.append(
                    {
                        "trial": trial_index + 1,
                        "start_button": {
                            "x": round(start[0], 1),
                            "y": round(start[1], 1),
                        },
                        "console_errors": errors,
                        "idle": _stats(idle),
                        "idle_samples": idle,
                        "idle_long_tasks": idle_long_tasks,
                        "shot": _stats(shot),
                        "shot_samples": shot,
                        "shot_long_tasks": shot_long_tasks,
                    }
                )
                context.close()
            errors = [error for trial in trials for error in trial["console_errors"]]
            idle_long_tasks = [
                {"trial": trial["trial"], **task}
                for trial in trials
                for task in trial["idle_long_tasks"]
            ]
            shot_long_tasks = [
                {"trial": trial["trial"], **task}
                for trial in trials
                for task in trial["shot_long_tasks"]
            ]
            records.append(
                {
                    "viewport": {"width": width, "height": height},
                    "gameplay_bounds": gameplay_bounds,
                    "interactive_shot_proxy": viewport in INTERACTIVE_VIEWPORTS,
                    "launch_point": None
                    if launch_point is None
                    else {
                        "x": round(launch_point[0], 3),
                        "y": round(launch_point[1], 3),
                    },
                    "console_errors": errors,
                    "idle": _aggregate_trials(trials, "idle"),
                    "idle_long_tasks": idle_long_tasks,
                    "shot": _aggregate_trials(trials, "shot"),
                    "shot_long_tasks": shot_long_tasks,
                    "trials": [
                        {
                            key: value
                            for key, value in trial.items()
                            if not key.endswith("_samples")
                        }
                        for trial in trials
                    ],
                }
            )
        browser.close()

    payload = {
        "measured_at": datetime.now(timezone.utc).isoformat(),
        "url": args.url,
        "runtime": "Chromium headless Web release proxy; not a physical-device result",
        "flow_target": "60-second core experience scene 1",
        "frame_metric": (
            "requestAnimationFrame callback interval; includes browser display "
            "scheduler jitter and is not Flutter build/raster duration"
        ),
        "warmup_ms": {
            "page": args.page_warmup_ms,
            "play": args.play_warmup_ms,
        },
        "repetitions": args.repetitions,
        "shot_window_ms": 3150,
        "frame_target_ms": 16.667,
        "missed_vsync_threshold": "interval > per-section median * 1.5",
        "long_task_threshold_ms": 50.0,
        "records": records,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
