"""MealDistributor — 餐次分配。

将单日三大营养素目标拆分为每餐的克数分布。
"""
from __future__ import annotations

from dataclasses import dataclass
from .profile_validator import UserProfile
from .macro_allocator import MacroResult


@dataclass
class Meal:
    name: str
    kcal: float
    protein_g: float
    fat_g: float
    carbs_g: float

    def to_dict(self) -> dict:
        return {
            "name": self.name,
            "kcal": round(self.kcal),
            "protein_g": round(self.protein_g, 1),
            "fat_g": round(self.fat_g, 1),
            "carbs_g": round(self.carbs_g, 1),
        }


@dataclass
class MealPlan:
    meals: list[Meal]
    total_kcal: float
    total_protein_g: float
    total_fat_g: float
    total_carbs_g: float
    food_examples: dict  # protein examples per gram

    def to_dict(self) -> dict:
        return {
            "meals": [m.to_dict() for m in self.meals],
            "total_kcal": round(self.total_kcal),
            "total_protein_g": round(self.total_protein_g, 1),
            "total_fat_g": round(self.total_fat_g, 1),
            "total_carbs_g": round(self.total_carbs_g, 1),
            "food_examples": self.food_examples,
        }


MEAL_NAMES_4 = ["早餐", "午餐", "练后加餐", "晚餐"]
MEAL_NAMES_5 = ["早餐", "午餐", "练后加餐", "晚餐", "晚加餐"]
MEAL_NAMES_3 = ["早餐", "午餐", "晚餐"]
MEAL_NAMES_6 = ["早餐", "早加餐", "午餐", "练后加餐", "晚餐", "晚加餐"]

# 食物替换举例
FOOD_EXAMPLES = {
    "35g_protein": "鸡胸肉 150g ≈ 鸡蛋 5个 ≈ 蛋白粉 1.5勺 ≈ 豆腐 400g",
    "40g_protein": "鸡胸肉 170g ≈ 鸡蛋 6个 ≈ 蛋白粉 1.7勺 ≈ 豆腐 450g",
    "30g_protein": "鸡胸肉 130g ≈ 鸡蛋 4个 ≈ 蛋白粉 1.3勺 ≈ 豆腐 350g",
    "20g_protein": "鸡胸肉 85g ≈ 鸡蛋 3个 ≈ 蛋白粉 0.9勺 ≈ 豆腐 230g",
}


def distribute(profile: UserProfile, macros: MacroResult) -> MealPlan:
    """将每日营养素分配到每餐。"""
    n = profile.meals_per_day

    # 每餐蛋白按日目标均分；不因 MPS 上限裁切日总量（餐次少时单餐可 >0.4g/kg）
    daily_protein = macros.daily_targets["protein_g"]
    daily_fat = macros.daily_targets["fat_g"]
    daily_carbs = macros.daily_targets["carbs_g"]

    per_meal_protein = daily_protein / n
    per_meal_fat = daily_fat / n
    per_meal_carbs = daily_carbs / n

    # 餐次名称
    if n <= 3:
        names = MEAL_NAMES_3[:n]
    elif n == 4:
        names = MEAL_NAMES_4
    elif n == 5:
        names = MEAL_NAMES_5
    else:
        names = MEAL_NAMES_6[:n]

    meals = []
    for i, name in enumerate(names):
        protein = per_meal_protein
        fat = per_meal_fat
        carbs = per_meal_carbs
        kcal = protein * 4 + fat * 9 + carbs * 4

        # 练后餐（最近一餐）蛋白×1.2，碳水×1.2
        is_post_workout = (name == "练后加餐")
        if is_post_workout:
            protein *= 1.2
            carbs *= 1.2
            kcal = protein * 4 + fat * 9 + carbs * 4

        meals.append(Meal(
            name=name,
            kcal=kcal,
            protein_g=protein,
            fat_g=fat,
            carbs_g=carbs,
        ))

    # 练后餐倾斜后，按比例缩放使蛋白/碳水总量贴近每日目标
    total_p = sum(m.protein_g for m in meals)
    total_c = sum(m.carbs_g for m in meals)
    if total_p > 0:
        p_scale = daily_protein / total_p
        for m in meals:
            m.protein_g *= p_scale
    if total_c > 0:
        c_scale = daily_carbs / total_c
        for m in meals:
            m.carbs_g *= c_scale
    for m in meals:
        m.kcal = m.protein_g * 4 + m.fat_g * 9 + m.carbs_g * 4

    total_p = sum(m.protein_g for m in meals)
    total_f = sum(m.fat_g for m in meals)
    total_c = sum(m.carbs_g for m in meals)
    total_k = sum(m.kcal for m in meals)

    return MealPlan(
        meals=meals,
        total_kcal=total_k,
        total_protein_g=total_p,
        total_fat_g=total_f,
        total_carbs_g=total_c,
        food_examples=FOOD_EXAMPLES,
    )
