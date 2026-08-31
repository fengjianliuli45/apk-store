"""纯逻辑单测（不需要 fastapi / db）。"""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.cohort import (  # noqa: E402
    age_band, bmi_band, equipment_tier, weeks_band, build_cohort_key,
    widen_steps, percentile, metric_stats, cohort_compare, MIN_COHORT,
)


class TestCohortBuckets(unittest.TestCase):
    def test_age_band(self):
        self.assertEqual(age_band(18), "16-19")
        self.assertEqual(age_band(20), "20-24")
        self.assertEqual(age_band(27), "25-29")
        self.assertEqual(age_band(34), "30-34")
        self.assertEqual(age_band(45), "40-49")
        self.assertEqual(age_band(60), "50+")

    def test_bmi_band(self):
        self.assertEqual(bmi_band(17), "<18.5")
        self.assertEqual(bmi_band(21), "18.5-22")
        self.assertEqual(bmi_band(23.5), "22-25")
        self.assertEqual(bmi_band(26), "25-28")
        self.assertEqual(bmi_band(31), "28+")

    def test_equipment_tier(self):
        self.assertEqual(equipment_tier(["barbell", "rack"]), "gym")
        self.assertEqual(equipment_tier(["bodyweight", "band"]), "home")
        self.assertEqual(equipment_tier([]), "home")

    def test_weeks_band(self):
        self.assertEqual(weeks_band(4), "4w")
        self.assertEqual(weeks_band(8), "8w")
        self.assertEqual(weeks_band(12), "12w")
        self.assertEqual(weeks_band(20), "16w+")

    def test_key_str_stable(self):
        k = build_cohort_key(sex="m", age=27, bmi=23.5, level="Beginner",
                             goal="Hypertrophy", equipment=["dumbbell"], weeks_elapsed=8)
        self.assertEqual(k.as_str(), "M|25-29|22-25|beginner|hypertrophy|gym|8w")

    def test_widen_steps(self):
        k = build_cohort_key(sex="M", age=27, bmi=23.5, level="beginner",
                             goal="hypertrophy", equipment=["dumbbell"], weeks_elapsed=8)
        steps = list(widen_steps(k))
        self.assertEqual(len(steps), 4)
        self.assertIsNone(steps[1].bmi_band)
        self.assertIsNone(steps[2].age_band)
        self.assertIsNone(steps[3].equipment_tier)
        # 非放宽维度保持不变
        self.assertEqual(steps[3].sex, "M")
        self.assertEqual(steps[3].goal, "hypertrophy")


class TestPercentile(unittest.TestCase):
    def test_matches_linear_interpolation(self):
        vals = list(range(1, 11))  # 1..10
        self.assertAlmostEqual(percentile(vals, 50), 5.5)
        self.assertAlmostEqual(percentile(vals, 25), 3.25)
        self.assertAlmostEqual(percentile(vals, 75), 7.75)

    def test_single_and_edges(self):
        self.assertEqual(percentile([4.0], 50), 4.0)
        self.assertEqual(percentile([1, 2, 3], 0), 1.0)
        self.assertEqual(percentile([1, 2, 3], 100), 3.0)

    def test_metric_stats_k_anon(self):
        self.assertIsNone(metric_stats([1.0] * (MIN_COHORT - 1)))
        s = metric_stats([float(i) for i in range(MIN_COHORT)])
        self.assertIsNotNone(s)
        self.assertEqual(s.n, MIN_COHORT)


class TestCompare(unittest.TestCase):
    stats = {"p25": 6.0, "p50": 12.0, "p75": 18.0}

    def test_bands(self):
        self.assertEqual(cohort_compare(20, self.stats)["band"], "ahead")
        self.assertEqual(cohort_compare(14, self.stats)["band"], "above")
        self.assertEqual(cohort_compare(8, self.stats)["band"], "normal")
        self.assertEqual(cohort_compare(3, self.stats)["band"], "behind")

    def test_vs_median(self):
        self.assertEqual(cohort_compare(9, self.stats)["vs_median_pct"], -25.0)
        self.assertEqual(cohort_compare(12, self.stats)["vs_median_pct"], 0.0)


if __name__ == "__main__":
    unittest.main()
