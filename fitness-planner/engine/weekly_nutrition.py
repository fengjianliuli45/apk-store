"""Execution projection; never mutate the saved base plan or profile.

Use the mesocycle's explicit energy delta and the allocator's existing rule:
protein/fat are fixed, carbohydrate receives the residual energy.
"""
from dataclasses import replace
from .macro_allocator import CARB_KCAL_PER_G, MacroResult
from .meal_distributor import distribute


def nutrition_for_week(profile, macros, meals, week=None):
    delta = week.diet_kcal_delta if week is not None else 0
    if not delta:
        return macros, meals
    targets = dict(macros.daily_targets)
    fixed = targets['protein_g'] * 4 + targets['fat_g'] * 9
    targets['kcal'] = max(fixed, targets['kcal'] + delta)
    targets['carbs_g'] = round((targets['kcal'] - fixed) / CARB_KCAL_PER_G, 1)
    adjusted = replace(macros, daily_targets=targets,
        per_kg={**macros.per_kg, 'carbs': round(targets['carbs_g'] / profile.weight_kg, 1)},
        notes=[*macros.notes, f'中周期第 {week.week} 周：相对基准热量调整 {delta:+d} kcal'])
    return adjusted, distribute(profile, adjusted)
