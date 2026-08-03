#!/usr/bin/env python3
"""Capture a real Stage 4 interaction sequence from the Web release build."""

import argparse
import json
from pathlib import Path

from playwright.sync_api import sync_playwright


VIEWPORT = {"width": 390, "height": 844}


def capture(page, output_dir: Path, name: str) -> str:
    path = output_dir / f"stage4-{name}.png"
    page.screenshot(path=str(path), full_page=True)
    return str(path)


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
        page = browser.new_page(viewport=VIEWPORT, device_scale_factor=1)
        console_errors: list[str] = []
        page.on(
            "console",
            lambda message: console_errors.append(message.text)
            if message.type == "error"
            else None,
        )

        page.goto(args.url, wait_until="networkidle")
        page.evaluate(
            """
            localStorage.setItem('flutter.property_shot_unlocked_level', '3');
            localStorage.setItem('flutter.unlocked_level', '3');
            localStorage.setItem('flutter.property_shot_cleared_levels', '[0,1,2]');
            """
        )
        page.reload(wait_until="networkidle")
        page.wait_for_timeout(700)

        # 홈 → 섬 지도 → 4단계. 좌표는 390×844 기준 캡처 계약이다.
        page.mouse.click(194, 585)
        page.wait_for_timeout(600)
        page.mouse.click(194, 565)
        page.wait_for_timeout(900)
        screenshots = [capture(page, args.output_dir, "start")]

        # 뾰족함 원본을 열고 속성을 공으로 옮긴다.
        page.mouse.click(88, 260)
        page.wait_for_timeout(350)
        screenshots.append(capture(page, args.output_dir, "source-popup"))
        page.mouse.click(150, 685)
        page.wait_for_timeout(450)
        screenshots.append(capture(page, args.output_dir, "property-ready"))

        # 공에서 풍선 방향으로 조준하고, 길게 눌러 힘을 채운 뒤 놓는다.
        page.mouse.move(60, 623)
        page.mouse.down()
        page.mouse.move(199, 397, steps=8)
        page.mouse.up()
        page.wait_for_timeout(250)
        screenshots.append(capture(page, args.output_dir, "aim"))

        page.mouse.move(60, 623)
        page.mouse.down()
        page.wait_for_timeout(1500)
        screenshots.append(capture(page, args.output_dir, "charge"))
        page.mouse.up()
        for name, delay in (
            ("impact-120ms", 120),
            ("impact-470ms", 350),
            ("result", 800),
        ):
            page.wait_for_timeout(delay)
            screenshots.append(capture(page, args.output_dir, name))

        evidence = {
            "url": args.url,
            "viewport": VIEWPORT,
            "stage": 4,
            "screenshots": screenshots,
            "console_errors": console_errors,
        }
        evidence_path = args.output_dir / "stage4-web-evidence.json"
        evidence_path.write_text(
            json.dumps(evidence, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(
            f"단계4 Web 증거 완료: {len(screenshots)}장, "
            f"콘솔 오류 {len(console_errors)}건, {evidence_path}"
        )
        browser.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
