"""MealDistributor 单元测试。"""
import unittest
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).resolve().parent.parent))

from engine.profile_validator import validate
from engine.tdee_calculator import calculate
from engine.macro_allocator import allocate
from engine.meal_distributor import distribute


class TestMealDistributor(unittest.TestCase):

    def _get_meal_plan(self, **overrides):
        raw = {
            "gender": "M", "age": 25, "height_cm": 175.0, "weight_kg": 70.0,
            "level": "intermediate", "goal": "hypertrophy", "days_per_week": 5,
            "minutes_per_session": 90, "equipment": ["barbell"],
        }
        raw.update(overrides)
        p = validate(raw)
        tdee = calculate(p)
        macros = allocate(p, tdee)
        return p, macros, distribute(p, macros)

    def test_meal_count(self):
        p, macros, mp = self._get_meal_plan(meals_per_day=4)
        self.assertEqual(len(mp.meals), 4)

    def test_5_meals(self):
        p, macros, mp = self._get_meal_plan(meals_per_day=5)
        self.assertEqual(len(mp.meals), 5)

    def test_total_protein_close(self):
        p, macros, mp = self._get_meal_plan()
        self.assertAlmostEqual(mp.total_protein_g, macros.daily_targets["protein_g"], delta=10)

    def test_per_meal_protein_cap(self):
        # 70kg, 0.4g/kg = 28g per meal cap
        p, macros, mp = self._get_meal_plan(weight_kg=70.0, meals_per_day=8)
        for meal in mp.meals:
            # 训后餐 ×1.2 可能超
            if meal.name == "练后加餐":
                continue
            self.assertLessEqual(meal.protein_g, 70 * 0.4 + 1)

    def test_post_workout_meal_boost(self):
        p, macros, mp = self._get_meal_plan(meals_per_day=5)
        post = [m for m in mp.meals if m.name == "练后加餐"]
        if post:
            non_post = [m for m in mp.meals if m.name != "练后加餐"]
            avg_protein_non = sum(m.protein_g for m in non_post) / len(non_post)
            self.assertGreater(post[0].protein_g, avg_protein_non)

    def test_meal_options_present(self):
        p, macros, mp = self._get_meal_plan()
        for meal in mp.meals:
            self.assertGreater(len(meal.options), 0)
            self.assertTrue(meal.hand_portions)

    def test_vegan_protein_bump_and_filter(self):
        p, macros, mp = self._get_meal_plan(dietary_restrictions=["vegan"])
        # 纯素蛋白 g/kg 应比默认高
        self.assertGreater(macros.per_kg["protein"], 2.0)
        # 方案里不应出现动物蛋白
        joined = " ".join(i for m in mp.meals for o in m.options for i in o["items"])
        for animal in ("鸡", "牛", "猪", "鱼", "虾", "蛋", "奶", "酸奶", "乳清"):
            self.assertNotIn(animal, joined)

    def test_fiber_and_water(self):
        p, macros, mp = self._get_meal_plan()
        self.assertGreater(mp.fiber_g, 0)
        self.assertEqual(mp.water_ml_training, mp.water_ml_rest + 500)

    def test_total_kcal_positive(self):
        p, macros, mp = self._get_meal_plan()
        self.assertGreater(mp.total_kcal, 0)


if __name__ == "__main__":
    unittest.main()
