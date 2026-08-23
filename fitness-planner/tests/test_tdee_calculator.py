"""TDEECalculator 单元测试。"""
import unittest
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).resolve().parent.parent))

from engine.profile_validator import validate
from engine.tdee_calculator import calculate


class TestTDEECalculator(unittest.TestCase):

    def _profile(self, **overrides):
        raw = {
            "gender": "M", "age": 25, "height_cm": 175.0, "weight_kg": 70.0,
            "level": "beginner", "goal": "hypertrophy", "days_per_week": 5,
            "minutes_per_session": 90, "equipment": ["barbell"],
        }
        raw.update(overrides)
        return validate(raw)

    def test_mifflin_male(self):
        p = self._profile()
        r = calculate(p)
        self.assertEqual(r.formula_used, "mifflin_st_jeor")
        # Mifflin: 10*70 + 6.25*175 - 5*25 + 5 = 700+1093.75-125+5 = 1673.75
        self.assertAlmostEqual(r.bmr, 1673.75, places=1)

    def test_mifflin_female(self):
        p = self._profile(gender="F")
        r = calculate(p)
        # F: 700+1093.75-125-161 = 1507.75
        self.assertAlmostEqual(r.bmr, 1507.75, places=1)

    def test_katch_mcardle(self):
        p = self._profile(body_fat_pct=15.0)
        r = calculate(p)
        self.assertEqual(r.formula_used, "katch_mcardle")
        # lean = 70 * 0.85 = 59.5; BMR = 370 + 21.6*59.5 = 370 + 1285.2 = 1655.2
        self.assertAlmostEqual(r.bmr, 1655.2, places=1)

    def test_activity_levels(self):
        # sedentary
        p = self._profile(days_per_week=0, minutes_per_session=0)
        r = calculate(p)
        self.assertEqual(r.activity_level, "sedentary")
        # light
        p = self._profile(days_per_week=2, minutes_per_session=30)
        r = calculate(p)
        self.assertEqual(r.activity_level, "light")
        # moderate
        p = self._profile(days_per_week=4, minutes_per_session=60)
        r = calculate(p)
        self.assertEqual(r.activity_level, "moderate")
        # active
        p = self._profile(days_per_week=6, minutes_per_session=90)
        r = calculate(p)
        self.assertEqual(r.activity_level, "active")
        # very_active
        p = self._profile(days_per_week=7, minutes_per_session=90)
        r = calculate(p)
        self.assertEqual(r.activity_level, "very_active")

    def test_tdee_calculation(self):
        p = self._profile(days_per_week=5, minutes_per_session=90)
        r = calculate(p)
        self.assertAlmostEqual(r.tdee, r.bmr * 1.725, places=1)


if __name__ == "__main__":
    unittest.main()
