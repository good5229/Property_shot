import tempfile
import unittest
from pathlib import Path

from scripts.web_release_quality_gate import evaluate


def record(width: int, height: int, interactive: bool) -> dict:
    return {
        "viewport": {"width": width, "height": height},
        "interactive_shot_proxy": interactive,
        "console_errors": [],
        "idle": {"p99_ms": 17.6, "over_50ms_count": 0},
        "idle_long_tasks": [],
        "shot": {
            "p95_ms": 17.5 if interactive else None,
            "p99_ms": 17.7 if interactive else None,
            "max_ms": 33.3 if interactive else None,
            "over_50ms_count": 0,
            "over_50ms_ratio": 0.0 if interactive else None,
        },
        "shot_long_tasks": [],
    }


class WebReleaseQualityGateTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.build = Path(self.temp.name)
        (self.build / "assets").mkdir()
        (self.build / "main.dart.js").write_bytes(b"j" * 1024)
        (self.build / "assets" / "sprite.png").write_bytes(b"p" * 512)

    def tearDown(self):
        self.temp.cleanup()

    def payload(self):
        return {
            "records": [
                record(320, 568, False),
                record(390, 844, True),
                record(768, 1024, True),
                record(1440, 900, False),
                record(1920, 1080, False),
            ]
        }

    def test_complete_release_proxy_passes(self):
        result = evaluate(self.payload(), self.build)

        self.assertTrue(result["passed"])
        self.assertEqual(len(result["viewport_results"]), 5)
        self.assertIn("Not field INP", result["measurement_scope"])
        self.assertEqual(result["assets"]["app_payload_bytes"], 1536)

    def test_missing_viewport_console_error_and_slow_shot_fail(self):
        payload = self.payload()
        payload["records"].pop()
        payload["records"][1]["console_errors"] = ["boom"]
        payload["records"][2]["shot"]["p95_ms"] = 30.0

        result = evaluate(payload, self.build)

        self.assertFalse(result["passed"])
        self.assertTrue(any("missing_viewports" in item for item in result["failures"]))
        self.assertIn("390x844:console_errors", result["failures"])
        self.assertIn("768x1024:shot_p95_over_25ms", result["failures"])

    def test_bounded_first_renderer_transfer_passes_but_sustained_jank_fails(self):
        payload = self.payload()
        mobile = payload["records"][1]
        mobile["shot"].update(
            p95_ms=17.5,
            p99_ms=49.0,
            max_ms=533.3,
            over_50ms_count=2,
            over_50ms_ratio=0.01,
        )
        mobile["shot_long_tasks"] = [{"duration_ms": 534.0}]

        self.assertTrue(evaluate(payload, self.build)["passed"])

        mobile["shot"]["over_50ms_ratio"] = 0.03
        mobile["shot_long_tasks"] = [{"duration_ms": 601.0}]
        result = evaluate(payload, self.build)

        self.assertFalse(result["passed"])
        self.assertIn(
            "390x844:shot_over_50ms_ratio_over_2pct", result["failures"]
        )
        self.assertIn("390x844:shot_long_task_over_600ms", result["failures"])

    def test_asset_budgets_fail_closed(self):
        (self.build / "main.dart.js").write_bytes(b"j" * (8 * 1024 * 1024 + 1))
        (self.build / "assets" / "large.png").write_bytes(
            b"p" * (2 * 1024 * 1024 + 1)
        )

        result = evaluate(self.payload(), self.build)

        self.assertFalse(result["passed"])
        self.assertIn("main_dart_js_over_8mb", result["failures"])
        self.assertIn("largest_raster_over_2mb", result["failures"])

    def test_renderer_variants_are_reported_but_not_app_payload(self):
        renderer = self.build / "canvaskit"
        renderer.mkdir()
        (renderer / "canvaskit.wasm").write_bytes(b"w" * (30 * 1024 * 1024))

        result = evaluate(self.payload(), self.build)

        self.assertTrue(result["passed"])
        self.assertGreater(
            result["assets"]["total_build_bytes"],
            result["assets"]["app_payload_bytes"],
        )

    def test_large_software_rendering_is_not_mislabeled_as_device_frame_gate(self):
        payload = self.payload()
        large = payload["records"][-1]
        large["idle"] = {"p99_ms": 120.0, "over_50ms_count": 12}
        large["idle_long_tasks"] = [{"duration_ms": 100.0}]

        result = evaluate(payload, self.build)

        self.assertTrue(result["passed"])


if __name__ == "__main__":
    unittest.main()
