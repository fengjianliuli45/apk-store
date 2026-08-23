"""ProfileValidator 单元测试。"""
import unittest
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).resolve().parent.parent))

from engine.profile_validator import validate, ValidationError, UserProfile


class TestProfileValidator(unittest.TestCase):

    def _valid_input(self):
        return {
            "gender": "M", "age": 25, "height_cm": 175.0, "weight_kg": 70.0,
            "level": "beginner", "goal": "hypertrophy", "days_per_week": 5,
            "minutes_per_session": 90, "equipment": ["barbell", "dumbbell"],
        }

    def test_valid_input(self):
        p = validate(self._valid_input())
        self.assertEqual(p.gender, "M")
        self.assertEqual(p.age, 25)
        self.assertEqual(p.bmi, 22.9)
        self.assertIsNone(p.body_fat_pct)
        self.assertEqual(p.meals_per_day, 4)

    def test_missing_required(self):
        raw = self._valid_input()
        del raw["gender"]
        with self.assertRaises(ValidationError) as ctx:
            validate(raw)
        self.assertIn("gender", str(ctx.exception))

    def test_age_boundary(self):
        raw = self._valid_input()
        raw["age"] = 15
        with self.assertRaises(ValidationError):
            validate(raw)
        raw["age"] = 80
        p = validate(raw)
        self.assertEqual(p.age, 80)

    def test_bmi_warning_low(self):
        raw = self._valid_input()
        raw["height_cm"] = 180
        raw["weight_kg"] = 40  # BMI ~12.3
        p = validate(raw)
        self.assertTrue(any("BMI" in w for w in p.warnings))

    def test_bmi_warning_high(self):
        raw = self._valid_input()
        raw["height_cm"] = 170
        raw["weight_kg"] = 130  # BMI ~45
        p = validate(raw)
        self.assertTrue(any("BMI" in w for w in p.warnings))

    def test_days_1_warning(self):
        raw = self._valid_input()
        raw["days_per_week"] = 1
        p = validate(raw)
        self.assertTrue(any("2" in w for w in p.warnings))

    def test_strength_beginner_warning(self):
        raw = self._valid_input()
        raw["goal"] = "strength"
        raw["level"] = "beginner"
        p = validate(raw)
        self.assertTrue(any("增肌" in w for w in p.warnings))

    def test_equipment_empty_defaults_bodyweight(self):
        raw = self._valid_input()
        raw["equipment"] = []
        p = validate(raw)
        self.assertEqual(p.equipment, ["bodyweight"])
        self.assertTrue(any("bodyweight" in n for n in p.notes))

    def test_body_fat_present(self):
        raw = self._valid_input()
        raw["body_fat_pct"] = 15.0
        p = validate(raw)
        self.assertEqual(p.body_fat_pct, 15.0)
        self.assertAlmostEqual(p.lean_mass_kg, 59.5, places=1)

    def test_gender_lowercase(self):
        raw = self._valid_input()
        raw["gender"] = "f"
        p = validate(raw)
        self.assertEqual(p.gender, "F")

    def test_invalid_goal(self):
        raw = self._valid_input()
        raw["goal"] = "bigness"
        with self.assertRaises(ValidationError):
            validate(raw)


if __name__ == "__main__":
    unittest.main()
