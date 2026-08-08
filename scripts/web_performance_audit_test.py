import unittest

from scripts.web_performance_audit import _aggregate_trials, _stats


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


if __name__ == "__main__":
    unittest.main()
