#!/usr/bin/env python3
"""Measure Web requestAnimationFrame timing around a real play flow.

This is a Chromium/Web proxy. It is deliberately not presented as iPhone or
iPad performance evidence.
"""

import argparse
import json
import statistics
from datetime import datetime, timezone
from io import BytesIO
from pathlib import Path

from PIL import Image
from playwright.sync_api import sync_playwright


VIEWPORTS = ((390, 844), (768, 1024))
BALL_POINTS = {(390, 844): (60, 580), (768, 1024): (176, 850)}


def _start_button_center(image_bytes: bytes) -> tuple[float, float]:
    image = Image.open(BytesIO(image_bytes)).convert("RGB")
    width, height = image.size
    row_counts = []
    for y in range(int(height * 0.45), height):
        count = 0
        for x in range(width):
            red, green, blue = image.getpixel((x, y))
            if red > 215 and 75 < green < 145 and blue < 125 and red - green > 80:
                count += 1
        row_counts.append((y, count))

    runs: list[list[int]] = []
    current: list[int] = []
    for y, count in row_counts:
        if count > width * 0.5:
            current.append(y)
        elif current:
            runs.append(current)
            current = []
    if current:
        runs.append(current)
    if not runs:
        raise RuntimeError("시작 버튼 색상 영역을 찾지 못했습니다.")

    button_rows = max(runs, key=lambda run: (run[-1], len(run)))
    points = []
    for y in button_rows:
        for x in range(width):
            red, green, blue = image.getpixel((x, y))
            if red > 215 and 75 < green < 145 and blue < 125 and red - green > 80:
                points.append((x, y))
    if not points:
        raise RuntimeError("시작 버튼의 중심을 계산하지 못했습니다.")
    return (
        (min(point[0] for point in points) + max(point[0] for point in points)) / 2,
        (min(point[1] for point in points) + max(point[1] for point in points)) / 2,
    )


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
            observer.observe({type: 'longtask', buffered: true});
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
        return {"samples": 0, "mean_ms": None, "p95_ms": None, "max_ms": None, "over_20ms_ratio": None}
    ordered = sorted(samples)
    percentile_index = min(len(ordered) - 1, int(len(ordered) * 0.95))
    return {
        "samples": len(samples),
        "mean_ms": round(statistics.fmean(samples), 3),
        "p95_ms": round(ordered[percentile_index], 3),
        "max_ms": round(max(samples), 3),
        "over_20ms_ratio": round(sum(value > 20 for value in samples) / len(samples), 4),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", default="http://127.0.0.1:8080/")
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("harness_docs/qa/web_performance_latest.json"),
    )
    parser.add_argument("--page-warmup-ms", type=int, default=1800)
    parser.add_argument("--play-warmup-ms", type=int, default=1200)
    args = parser.parse_args()

    records = []
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True)
        for width, height in VIEWPORTS:
            page = browser.new_page(viewport={"width": width, "height": height}, device_scale_factor=1)
            errors: list[str] = []
            page.on("console", lambda message: errors.append(message.text) if message.type == "error" else None)
            page.goto(args.url)
            page.wait_for_timeout(args.page_warmup_ms)
            start = _start_button_center(page.screenshot())
            page.mouse.click(*start)
            page.wait_for_timeout(args.play_warmup_ms)
            _start_long_task_capture(page)
            idle = _measure_frames(page, 1800)
            idle_long_tasks = _drain_long_tasks(page)
            page.mouse.move(*BALL_POINTS[(width, height)])
            page.mouse.down()
            page.wait_for_timeout(650)
            page.mouse.up()
            shot = _measure_frames(page, 2500)
            shot_long_tasks = _drain_long_tasks(page)
            records.append(
                {
                    "viewport": {"width": width, "height": height},
                    "start_button": {"x": round(start[0], 1), "y": round(start[1], 1)},
                    "launch_point": {"x": BALL_POINTS[(width, height)][0], "y": BALL_POINTS[(width, height)][1]},
                    "console_errors": errors,
                    "idle": _stats(idle),
                    "idle_long_tasks": idle_long_tasks,
                    "shot": _stats(shot),
                    "shot_long_tasks": shot_long_tasks,
                }
            )
            page.close()
        browser.close()

    payload = {
        "measured_at": datetime.now(timezone.utc).isoformat(),
        "url": args.url,
        "runtime": "Chromium headless Web release proxy; not a physical-device result",
        "warmup_ms": {
            "page": args.page_warmup_ms,
            "play": args.play_warmup_ms,
        },
        "frame_target_ms": 16.667,
        "long_task_threshold_ms": 50.0,
        "records": records,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
