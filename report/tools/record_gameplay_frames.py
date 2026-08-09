#!/usr/bin/env python3
"""Capture a real 61-second deployed play session as an 8 fps PNG sequence."""

import argparse
import asyncio
import time
from pathlib import Path

from playwright.async_api import async_playwright


VIEWPORT = {"width": 390, "height": 844}
FPS = 8
DURATION_SECONDS = 61.0


async def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", default="https://good5229.github.io/Property_shot/")
    parser.add_argument(
        "--frames-dir",
        type=Path,
        default=Path("recordings/.recording-frames"),
    )
    args = parser.parse_args()
    args.frames_dir.mkdir(parents=True, exist_ok=True)
    for old in args.frames_dir.glob("frame-*.png"):
        old.unlink()

    errors = []
    async with async_playwright() as playwright:
        browser = await playwright.chromium.launch(headless=True)
        page = await browser.new_page(viewport=VIEWPORT, device_scale_factor=1)
        page.on(
            "console",
            lambda message: errors.append(message.text)
            if message.type == "error"
            else None,
        )
        await page.goto(args.url, wait_until="networkidle")
        await page.wait_for_timeout(4500)

        started = time.monotonic()

        async def capture_frames():
            frame_index = 0
            interval = 1.0 / FPS
            while time.monotonic() - started < DURATION_SECONDS:
                frame_started = time.monotonic()
                await page.screenshot(
                    path=str(args.frames_dir / f"frame-{frame_index:05d}.png")
                )
                frame_index += 1
                elapsed = time.monotonic() - frame_started
                await asyncio.sleep(max(0, interval - elapsed))
            return frame_index

        async def perform_actions():
            await page.wait_for_timeout(1800)
            await page.mouse.click(363, 29)
            await page.wait_for_timeout(1800)
            await page.mouse.click(195, 134)
            await page.wait_for_timeout(650)
            await page.mouse.click(95, 184)
            await page.wait_for_timeout(650)
            await page.mouse.click(195, 204)
            await page.wait_for_timeout(650)
            await page.mouse.click(95, 244)
            await page.wait_for_timeout(1600)
            await page.mouse.click(294, 768)
            await page.wait_for_timeout(2200)

            await page.mouse.click(195, 498)
            await page.wait_for_timeout(3200)
            await page.mouse.click(84, 238)
            await page.wait_for_timeout(1800)
            await page.mouse.click(150, 685)
            await page.wait_for_timeout(1800)

            await page.mouse.move(61, 566)
            await page.mouse.down()
            await page.mouse.move(205, 425, steps=12)
            await page.mouse.up()
            await page.wait_for_timeout(2800)

            await page.mouse.move(61, 566)
            await page.mouse.down()
            await page.wait_for_timeout(1450)
            await page.mouse.up()
            await page.wait_for_timeout(11000)

        frame_count, _ = await asyncio.gather(capture_frames(), perform_actions())
        await browser.close()

    print(
        f"프레임 캡처 완료: {frame_count}장 · {FPS}fps · "
        f"{DURATION_SECONDS:.0f}초 · 콘솔 오류 {len(errors)}건"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
