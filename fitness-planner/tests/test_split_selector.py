"""SplitSelector 单元测试。"""
import unittest
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).resolve().parent.parent))

from engine.profile_validator import validate
from engine.split_selector import select


class TestSplitSelector(unittest.TestCase):

    def _profile(self, **overrides):
        raw = {
            "gender": "M", "age": 25, "height_cm": 175.0, "weight_kg": 70.0,
            "level": "intermediate", "goal": "hypertrophy", "days_per_week": 5,
            "minutes_per_session": 90, "equipment": ["barbell"],
        }
        raw.update(overrides)
        return validate(raw)

    def test_2_days_full_body(self):
        p = self._profile(days_per_week=2)
        s = select(p)
        self.assertEqual(s.split_name, "full_body")

    def test_3_days_beginner_full_body(self):
        p = self._profile(days_per_week=3, level="beginner")
        s = select(p)
        self.assertEqual(s.split_name, "full_body")

    def test_3_days_intermediate_ppl(self):
        p = self._profile(days_per_week=3, level="intermediate")
        s = select(p)
        self.assertEqual(s.split_name, "push_pull_legs")

    def test_4_days_upper_lower(self):
        p = self._profile(days_per_week=4)
        s = select(p)
        self.assertEqual(s.split_name, "upper_lower")

    def test_5_days_ppl_upper_lower(self):
        p = self._profile(days_per_week=5)
        s = select(p)
        self.assertEqual(s.split_name, "ppl_upper_lower")

    def test_6_days_ppl_ppl(self):
        p = self._profile(days_per_week=6)
        s = select(p)
        self.assertEqual(s.split_name, "ppl_ppl")

    def test_7_days_warning(self):
        p = self._profile(days_per_week=7)
        s = select(p)
        self.assertEqual(s.split_name, "ppl_ppl")
        self.assertTrue(any("不推荐" in w for w in s.warnings))

    def test_1_day_warning(self):
        p = self._profile(days_per_week=1)
        s = select(p)
        self.assertTrue(any("2" in w for w in s.warnings))

    def test_schedule_has_7_days(self):
        p = self._profile(days_per_week=5)
        s = select(p)
        self.assertEqual(len(s.weekly_schedule), 7)

    def test_schedule_day_names(self):
        p = self._profile(days_per_week=5)
        s = select(p)
        self.assertEqual(s.weekly_schedule[0]["day"], "周一")
        self.assertEqual(s.weekly_schedule[6]["day"], "周日")


if __name__ == "__main__":
    unittest.main()
