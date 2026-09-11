import unittest
from types import SimpleNamespace
from engine.profile_validator import validate
from engine.tdee_calculator import calculate
from engine.macro_allocator import allocate
from engine.meal_distributor import distribute
from engine.weekly_nutrition import nutrition_for_week


class WeeklyNutritionTest(unittest.TestCase):
    def test_delta_and_identity(self):
        profile = validate(dict(gender='M', age=28, height_cm=178, weight_kg=80,
            level='intermediate', goal='fat_loss', minutes_per_session=75,
            equipment=['dumbbell'], days_per_week=3, dietary_restrictions=['vegan'],
            kcal_adjust=100, meals_per_day=6))
        macros = allocate(profile, calculate(profile))
        meals = distribute(profile, macros)
        before = macros.to_dict().copy()
        adjusted, food = nutrition_for_week(profile, macros, meals,
            SimpleNamespace(week=5, diet_kcal_delta=400))
        self.assertEqual(adjusted.daily_targets['kcal'], macros.daily_targets['kcal'] + 400)
        self.assertEqual(adjusted.daily_targets, dict(kcal=2855, protein_g=200.0, fat_g=64.0, carbs_g=369.8))
        self.assertEqual(adjusted.daily_targets['protein_g'], macros.daily_targets['protein_g'])
        self.assertEqual(adjusted.daily_targets['fat_g'], macros.daily_targets['fat_g'])
        self.assertAlmostEqual(adjusted.daily_targets['carbs_g'], macros.daily_targets['carbs_g'] + 100, places=1)
        self.assertAlmostEqual(sum(m.kcal for m in food.meals), adjusted.daily_targets['kcal'], delta=1)
        self.assertEqual(macros.to_dict(), before)
        self.assertIs(nutrition_for_week(profile, macros, meals)[0], macros)
