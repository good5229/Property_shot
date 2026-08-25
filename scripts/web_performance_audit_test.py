import argparse
import unittest

from scripts.web_performance_audit import (
    CORE_EXPERIENCE_POINTS,
    INTERACTIVE_VIEWPORTS,
    VIEWPORTS,
    _aggregate_trials,
    _stats,
    _viewport,
)


class WebPerformanceAuditTest(unittest.TestCase):
    def test_stats_reports_nearest_rank_and_missed_vsync(self):
        samples = [16.6] * 18 + [17.2, 33.3]

        result = _stats(samples)

        self.assertEqual(result["samples"], 20)
        self.assertEqual(result["p90_ms"], 16.6)
        self.assertEqual(result["p95_ms"], 17.2)
        self.assertEqual(result["p99_ms"], 33.3)
        self.assertEqual(result["missed_vsync_count"], 1)
        self.assertEqual(result["over_50ms_count"], 0)

    def test_aggregate_trials_uses_all_raw_samples(self):
        trials = [
            {"shot_samples": [16.5, 16.7]},
            {"shot_samples": [16.6, 33.2]},
        ]

        result = _aggregate_trials(trials, "shot")

        self.assertEqual(result["samples"], 4)
        self.assertEqual(result["max_ms"], 33.2)
        self.assertEqual(result["missed_vsync_count"], 1)

    def test_viewport_parser_accepts_only_release_matrix(self):
        self.assertEqual(_viewport("390x844"), (390, 844))
        with self.assertRaises(argparse.ArgumentTypeError):
            _viewport("400x900")

    def test_each_release_viewport_has_a_core_experience_entry_point(self):
        self.assertEqual(set(CORE_EXPERIENCE_POINTS), set(VIEWPORTS))
        self.assertTrue(INTERACTIVE_VIEWPORTS.issubset(set(VIEWPORTS)))


if __name__ == "__main__":
    unittest.main()
