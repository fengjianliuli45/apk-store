"""MacroAllocator 单元测试。"""
import unittest
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).resolve().parent.parent))

from engine.profile_validator import validate
from engine.tdee_calculator import calculate
from engine.macro_allocator import allocate


class TestMacroAllocator(unittest.TestCase):

    def _get(self, **overrides):
        raw = {
            "gender": "M", "age": 25, "height_cm": 175.0, "weight_kg": 70.0,
            "level": "intermediate", "goal": "hypertrophy", "days_per_week": 5,
            "minutes_per_session": 90, "equipment": ["barbell"],
        }
        raw.update(overrides)
        p = validate(raw)
        tdee = calculate(p)
        return p, tdee, allocate(p, tdee)

    def test_hypertrophy_surplus(self):
        p, tdee, m = self._get(goal="hypertrophy")
        self.assertEqual(m.surplus_kcal, 350)
        self.assertAlmostEqual(m.daily_targets["kcal"], tdee.tdee + 350, places=0)

    def test_fat_loss_deficit(self):
        p, tdee, m = self._get(goal="fat_loss")
        self.assertEqual(m.surplus_kcal, -400)

    def test_recomposition_maintenance(self):
        p, tdee, m = self._get(goal="recomposition")
        self.assertEqual(m.surplus_kcal, 0)

    def test_protein_per_kg(self):
        p, tdee, m = self._get(goal="hypertrophy", weight_kg=70.0)
        self.assertAlmostEqual(m.per_kg["protein"], 2.0, places=1)
        self.assertAlmostEqual(m.daily_targets["protein_g"], 140.0, places=1)

    def test_fat_loss_protein(self):
        p, tdee, m = self._get(goal="fat_loss", weight_kg=70.0)
        self.assertAlmostEqual(m.per_kg["protein"], 2.2, places=1)

    def test_carbs_positive(self):
        p, tdee, m = self._get()
        self.assertGreater(m.daily_targets["carbs_g"], 0)

    def test_macro_kcal_consistency(self):
        p, tdee, m = self._get()
        dt = m.daily_targets
        kcal_from_macros = dt["protein_g"] * 4 + dt["fat_g"] * 9 + dt["carbs_g"] * 4
        self.assertAlmostEqual(kcal_from_macros, dt["kcal"], delta=5)


if __name__ == "__main__":
    unittest.main()
