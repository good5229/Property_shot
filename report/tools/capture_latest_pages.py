#!/usr/bin/env python3
"""Capture current contest-report screens from the deployed GitHub Pages app."""

import argparse
from pathlib import Path

from playwright.sync_api import sync_playwright


VIEWPORTS = ((390, 844), (768, 1024))


def home_points(width: int, height: int):
    center = width / 2
    return {
        "start": (center, height * 0.5 + 76),
        "stages": (center, height * 0.506 + 125),
        "daily": (center, height * 0.5 + 234),
    }


def capture(page, output_dir: Path, prefix: str, name: str):
    page.screenshot(path=str(output_dir / f"{prefix}-{name}.png"), full_page=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", default="https://good5229.github.io/Property_shot/")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("report/assets/captures/latest-pages"),
    )
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)

    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True)
        for width, height in VIEWPORTS:
            page = browser.new_page(
                viewport={"width": width, "height": height},
                device_scale_factor=1,
            )
            errors = []
            page.on(
                "console",
                lambda message: errors.append(message.text)
                if message.type == "error"
                else None,
            )
            points = home_points(width, height)
            prefix = f"{width}x{height}"

            page.goto(args.url, wait_until="networkidle")
            page.wait_for_timeout(900)
            capture(page, args.output_dir, prefix, "home")

            page.mouse.click(*points["stages"])
            page.wait_for_timeout(900)
            capture(page, args.output_dir, prefix, "stage-map")

            page.goto(args.url, wait_until="networkidle")
            page.wait_for_timeout(700)
            page.mouse.click(*points["daily"])
            page.wait_for_timeout(900)
            capture(page, args.output_dir, prefix, "daily-challenge")

            page.goto(args.url, wait_until="networkidle")
            page.wait_for_timeout(700)
            page.mouse.click(*points["start"])
            page.wait_for_timeout(1400)
            capture(page, args.output_dir, prefix, "gameplay")

            print(f"{prefix}: 4개 최신 화면 캡처, 콘솔 오류 {len(errors)}건")
            page.close()
        browser.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
