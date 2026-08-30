"""同类对标软提示。"""
import unittest
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).resolve().parent.parent))

from engine.cohort_compare import cohort_compare, cohort_query_params, cohort_hint


class TestCohortCompare(unittest.TestCase):
    stats = {"p25": 6.0, "p50": 12.0, "p75": 18.0}

    def test_bands(self):
        self.assertEqual(cohort_compare(20, self.stats)["band"], "ahead")
        self.assertEqual(cohort_compare(14, self.stats)["band"], "above")
        self.assertEqual(cohort_compare(8, self.stats)["band"], "normal")
        self.assertEqual(cohort_compare(3, self.stats)["band"], "behind")

    def test_vs_median(self):
        self.assertEqual(cohort_compare(9, self.stats)["vs_median_pct"], -25.0)
        self.assertEqual(cohort_compare(12, self.stats)["vs_median_pct"], 0.0)

    def test_query_params_from_plan(self):
        from engine.pipeline import generate_plan
        p = generate_plan({
            "gender": "M", "age": 27, "height_cm": 178.0, "weight_kg": 78.0,
            "level": "beginner", "goal": "hypertrophy", "minutes_per_session": 60,
            "equipment": ["dumbbell"],
        })
        q = cohort_query_params(p, 8)
        self.assertEqual(q["sex"], "M")
        self.assertEqual(q["age"], 27)
        self.assertEqual(q["level"], "beginner")
        self.assertEqual(q["weeks_elapsed"], 8.0)
        self.assertGreater(q["bmi"], 20)

    def test_hint_text(self):
        h = cohort_hint("卧推进步", 8, self.stats)
        self.assertIn("+8%", h)
        self.assertIn("同类中位数 +12%", h)


if __name__ == "__main__":
    unittest.main()
