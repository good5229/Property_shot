#!/usr/bin/env python3
"""Capture current Web release states at the target mobile-first viewports."""

import argparse
from pathlib import Path

from playwright.sync_api import sync_playwright


VIEWPORTS = ((390, 844), (768, 1024))
START_POINTS = {(390, 844): (194.5, 530.5), (768, 1024): (383.5, 634.5)}
STAGE_SELECT_POINTS = {(390, 844): (194.5, 585.0), (768, 1024): (383.5, 676.0)}


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

            page.mouse.click(*STAGE_SELECT_POINTS[(width, height)])
            page.wait_for_timeout(700)
            page.screenshot(path=str(prefix.with_name(f"{prefix.name}-map-current.png")), full_page=True)

            page.goto(args.url, wait_until="networkidle")
            page.wait_for_timeout(700)
            page.mouse.click(*START_POINTS[(width, height)])
            page.wait_for_timeout(1000)
            page.screenshot(path=str(prefix.with_name(f"{prefix.name}-play-current.png")), full_page=True)
            print(f"{width}x{height}: 캡처 완료, 콘솔 오류 {len(errors)}건")
            page.close()
        browser.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
