#!/usr/bin/env python3
"""Capture current Web release states at the target mobile-first viewports."""

import argparse
from pathlib import Path

from playwright.sync_api import sync_playwright


VIEWPORTS = ((390, 844), (393, 852), (430, 932), (768, 1024), (1024, 1366))


def interaction_points(width: int, height: int) -> tuple[tuple[float, float], tuple[float, float]]:
    """Return the center points of the home start and stage-select actions."""
    known = {
        (390, 844): ((194.5, 530.5), (194.5, 585.0)),
        (768, 1024): ((383.5, 634.5), (383.5, 676.0)),
        (1024, 1366): ((512.0, 793.0), (512.0, 847.0)),
    }
    if (width, height) in known:
        return known[(width, height)]
    # The mobile home layout is vertically centered. Interpolate from the
    # verified 390px and 768px captures for intermediate and tablet sizes.
    start_y = 0.578 * height + 42.5
    stage_y = 0.506 * height + 158.6
    return ((width / 2, start_y), (width / 2, stage_y))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", default="http://127.0.0.1:8080/")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("screenshots/commercial-vertical-slice"),
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
            errors: list[str] = []
            page.on(
                "console",
                lambda message: errors.append(message.text)
                if message.type == "error"
                else None,
            )
            page.goto(args.url, wait_until="networkidle")
            page.wait_for_timeout(700)
            prefix = args.output_dir / f"{width}x{height}"
            page.screenshot(path=str(prefix.with_name(f"{prefix.name}-home-current.png")), full_page=True)

            _, stage_select_point = interaction_points(width, height)
            page.mouse.click(*stage_select_point)
            page.wait_for_timeout(700)
            page.screenshot(path=str(prefix.with_name(f"{prefix.name}-map-current.png")), full_page=True)

            page.goto(args.url, wait_until="networkidle")
            page.wait_for_timeout(700)
            start_point, _ = interaction_points(width, height)
            page.mouse.click(*start_point)
            page.wait_for_timeout(1000)
            page.screenshot(path=str(prefix.with_name(f"{prefix.name}-play-current.png")), full_page=True)
            print(f"{width}x{height}: 캡처 완료, 콘솔 오류 {len(errors)}건")
            page.close()
        browser.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
