"""SupplementAdvisor 单元测试。"""
import unittest
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).resolve().parent.parent))

from engine.profile_validator import validate
from engine.tdee_calculator import calculate
from engine.macro_allocator import allocate
from engine.supplement_advisor import advise


class TestSupplementAdvisor(unittest.TestCase):

    def _get(self, **overrides):
        raw = {
            "gender": "M", "age": 25, "height_cm": 175.0, "weight_kg": 70.0,
            "level": "intermediate", "goal": "hypertrophy", "days_per_week": 5,
            "minutes_per_session": 90, "equipment": ["barbell"],
        }
        raw.update(overrides)
        p = validate(raw)
        tdee = calculate(p)
        macros = allocate(p, tdee)
        return p, macros, advise(p, macros)

    def test_creatine_default(self):
        p, macros, result = self._get()
        names = [s.name for s in result.supplements]
        self.assertIn("肌酸", names)

    def test_whey_when_protein_high(self):
        p, macros, result = self._get(goal="fat_loss", weight_kg=80.0)
        # 2.2 * 80 = 176g protein, diet est = 80g → deficit → whey recommended
        names = [s.name for s in result.supplements]
        self.assertIn("乳清蛋白粉", names)

    def test_vitamin_d_canteen(self):
        p, macros, result = self._get(cooking_access="canteen")
        names = [s.name_en for s in result.supplements]
        self.assertIn("Vitamin D3", names)

    def test_fish_oil_vegetarian(self):
        p, macros, result = self._get(dietary_restrictions=["vegetarian"])
        names = [s.name for s in result.supplements]
        self.assertIn("鱼油 / 藻油", names)

    def test_no_fish_oil_if_not_vegetarian(self):
        p, macros, result = self._get()
        names = [s.name for s in result.supplements]
        self.assertNotIn("鱼油 / 藻油", names)

    def test_creatine_dose(self):
        p, macros, result = self._get()
        creatine = [s for s in result.supplements if s.name == "肌酸"]
        self.assertEqual(creatine[0].dose, "5g/日")

    def test_creatine_pmid(self):
        p, macros, result = self._get()
        creatine = [s for s in result.supplements if s.name == "肌酸"]
        self.assertEqual(creatine[0].pmid, "37432300")


if __name__ == "__main__":
    unittest.main()
