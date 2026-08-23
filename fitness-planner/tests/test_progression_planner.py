"""ProgressionPlanner 单元测试。"""
import unittest
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).resolve().parent.parent))

from engine.profile_validator import validate
from engine.progression_planner import plan


class TestProgressionPlanner(unittest.TestCase):

    def _profile(self, **overrides):
        raw = {
            "gender": "M", "age": 25, "height_cm": 175.0, "weight_kg": 70.0,
            "level": "beginner", "goal": "hypertrophy", "days_per_week": 5,
            "minutes_per_session": 90, "equipment": ["barbell"],
        }
        raw.update(overrides)
        return validate(raw)

    def test_beginner_linear(self):
        p = self._profile(level="beginner")
        r = plan(p)
        self.assertEqual(r.strategy, "linear_weekly")
        self.assertEqual(r.increment_upper_kg, 2.5)
        self.assertEqual(r.increment_lower_kg, 5.0)

    def test_intermediate_biweekly(self):
        p = self._profile(level="intermediate")
        r = plan(p)
        self.assertEqual(r.strategy, "biweekly_double_progression")

    def test_advanced_monthly(self):
        p = self._profile(level="advanced")
        r = plan(p)
        self.assertEqual(r.strategy, "monthly_periodization")
        self.assertEqual(r.increment_upper_kg, 1.25)

    def test_has_triggers(self):
        p = self._profile()
        r = plan(p)
        self.assertGreaterEqual(len(r.triggers), 5)
        conditions = [t.condition for t in r.triggers]
        self.assertIn("体重变化 >2kg", conditions)
        self.assertIn("目标变更", conditions)

    def test_next_check_week(self):
        p = self._profile()
        r = plan(p)
        self.assertEqual(r.next_check_week, 4)

    def test_double_progression_described(self):
        p = self._profile()
        r = plan(p)
        self.assertIn("双进阶", r.double_progression)

    def test_deload_programmed(self):
        p = self._profile()
        r = plan(p)
        self.assertEqual(r.deload_every_weeks, 4)
        self.assertEqual(r.deload_volume_pct, 60)
        self.assertIn("减载", r.deload_note)
        conditions = [t.condition for t in r.triggers]
        self.assertTrue(any("减载" in c for c in conditions))


if __name__ == "__main__":
    unittest.main()
