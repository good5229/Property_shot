#!/usr/bin/env python3
"""Print Flutter Web semantics labels and browser-space bounds for QA."""

import argparse

from playwright.sync_api import sync_playwright

from web_performance_audit import CORE_EXPERIENCE_POINTS, _viewport


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", required=True)
    parser.add_argument("--viewport", type=_viewport, required=True)
    args = parser.parse_args()
    width, height = args.viewport
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True)
        page = browser.new_page(viewport={"width": width, "height": height})
        page.goto(args.url)
        page.wait_for_timeout(5000)
        page.mouse.click(*CORE_EXPERIENCE_POINTS[args.viewport])
        page.wait_for_timeout(3000)
        placeholder = page.locator("flt-semantics-placeholder")
        if placeholder.count() > 0:
            placeholder.evaluate("node => node.click()")
            page.wait_for_timeout(1000)
        labels = page.locator("[aria-label]").evaluate_all(
            """
            nodes => nodes.map(node => {
              const rect = node.getBoundingClientRect();
              return {
                label: node.getAttribute('aria-label'),
                x: rect.x,
                y: rect.y,
                width: rect.width,
                height: rect.height,
              };
            }).filter(item => item.width > 0 && item.height > 0)
            """
        )
        for item in labels:
            print(item)
        browser.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
