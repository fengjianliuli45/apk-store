"""MealDistributor — 餐次分配 + 具体吃法。

单日三大营养素目标 → 每餐克数 → 每餐「怎么吃」：
  - 精确版：食物交换份法（食物库按宏量换算份量），2 个备选
  - 手掌版：手掌=蛋白、一捧=碳水、拳头=蔬菜、拇指=脂肪（不称重 / 在外吃）
另附每日膳食纤维、饮水目标。
"""
from __future__ import annotations

import math
from dataclasses import dataclass, field
from .profile_validator import UserProfile
from .macro_allocator import MacroResult
from . import food_db


def _round(x: float) -> int:
    return int(math.floor(x + 0.5))


@dataclass
class Meal:
    name: str
    kcal: float
    protein_g: float
    fat_g: float
    carbs_g: float
    options: list = field(default_factory=list)   # 精确吃法（食物库）
    hand_portions: str = ""                        # 手掌法等价
    is_post_workout: bool = False

    def to_dict(self) -> dict:
        return {
            "name": self.name,
            "kcal": round(self.kcal),
            "protein_g": round(self.protein_g, 1),
            "fat_g": round(self.fat_g, 1),
            "carbs_g": round(self.carbs_g, 1),
            "options": self.options,
            "hand_portions": self.hand_portions,
            "is_post_workout": self.is_post_workout,
        }


@dataclass
class MealPlan:
    meals: list
    total_kcal: float
    total_protein_g: float
    total_fat_g: float
    total_carbs_g: float
    fiber_g: int
    water_ml_rest: int
    water_ml_training: int
    diet_notes: list = field(default_factory=list)

    def to_dict(self) -> dict:
        return {
            "meals": [m.to_dict() for m in self.meals],
            "total_kcal": round(self.total_kcal),
            "total_protein_g": round(self.total_protein_g, 1),
            "total_fat_g": round(self.total_fat_g, 1),
            "total_carbs_g": round(self.total_carbs_g, 1),
            "fiber_g": self.fiber_g,
            "water_ml_rest": self.water_ml_rest,
            "water_ml_training": self.water_ml_training,
            "diet_notes": self.diet_notes,
        }


MEAL_NAMES_4 = ["早餐", "午餐", "练后加餐", "晚餐"]
MEAL_NAMES_5 = ["早餐", "午餐", "练后加餐", "晚餐", "晚加餐"]
MEAL_NAMES_3 = ["早餐", "午餐", "晚餐"]
MEAL_NAMES_6 = ["早餐", "早加餐", "午餐", "练后加餐", "晚餐", "晚加餐"]

# 膳食纤维 14g / 1000 kcal（Academy of Nutrition and Dietetics）
FIBER_PER_1000KCAL = 14
# 饮水 33 ml/kg 基线，训练日额外 +500 ml
WATER_ML_PER_KG = 33
WATER_ML_TRAINING_BONUS = 500


def distribute(profile: UserProfile, macros: MacroResult) -> MealPlan:
    """将每日营养素分配到每餐，并给出具体吃法。"""
    n = profile.meals_per_day

    daily_protein = macros.daily_targets["protein_g"]
    daily_fat = macros.daily_targets["fat_g"]
    daily_carbs = macros.daily_targets["carbs_g"]

    per_meal_protein = daily_protein / n
    per_meal_fat = daily_fat / n
    per_meal_carbs = daily_carbs / n

    if n <= 3:
        names = MEAL_NAMES_3[:n]
    elif n == 4:
        names = MEAL_NAMES_4
    elif n == 5:
        names = MEAL_NAMES_5
    else:
        names = MEAL_NAMES_6[:n]

    meals: list[Meal] = []
    for name in names:
        protein = per_meal_protein
        fat = per_meal_fat
        carbs = per_meal_carbs
        is_post_workout = (name == "练后加餐")
        if is_post_workout:
            protein *= 1.2
            carbs *= 1.2
        kcal = protein * 4 + fat * 9 + carbs * 4
        meals.append(Meal(
            name=name, kcal=kcal, protein_g=protein, fat_g=fat, carbs_g=carbs,
            is_post_workout=is_post_workout,
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

    # 具体吃法
    restrictions = food_db.normalize_restrictions(getattr(profile, "dietary_restrictions", []))
    cooking = getattr(profile, "cooking_access", "home")
    for idx, m in enumerate(meals):
        target = {"protein_g": m.protein_g, "carbs_g": m.carbs_g, "fat_g": m.fat_g}
        m.options = food_db.suggest_meal(
            target, restrictions, cooking, m.is_post_workout, rotate=idx)
        m.hand_portions = food_db.hand_portion_text(target)

    total_p = sum(m.protein_g for m in meals)
    total_f = sum(m.fat_g for m in meals)
    total_c = sum(m.carbs_g for m in meals)
    total_k = sum(m.kcal for m in meals)

    # 每日纤维 / 饮水
    fiber_g = _round(total_k / 1000 * FIBER_PER_1000KCAL)
    water_rest = _round(profile.weight_kg * WATER_ML_PER_KG)
    water_training = water_rest + WATER_ML_TRAINING_BONUS

    # 膳食提示
    diet_notes: list[str] = list(macros.notes)
    # 每餐 0.4 g/kg 为最优刺激（Schoenfeld & Aragon 2018），0.3 g/kg 为触发阈值下限
    protein_floor = round(0.3 * profile.weight_kg, 1)
    protein_target = round(0.4 * profile.weight_kg, 1)
    low_meals = [m.name for m in meals if m.protein_g + 1e-6 < protein_floor]
    if low_meals:
        diet_notes.append(
            f"每餐蛋白最优 ~{protein_target}g（0.4 g/kg），下限 {protein_floor}g（0.3 g/kg）；"
            f"偏低的餐：{'、'.join(low_meals)}——把蛋白挪一些过去或加一份"
        )
    diet_notes.append("蛋白尽量均分到各餐，相邻 3–4 小时一次（MPS 窗口 ~2–3h）")
    diet_notes.append(f"膳食纤维 ≥{fiber_g}g/天：每餐一拳蔬菜 + 主食尽量选糙米/燕麦/薯类")
    diet_notes.append(f"饮水：非训练日约 {water_rest}ml，训练日约 {water_training}ml")
    if "vegan" in restrictions:
        diet_notes.append("纯素需额外关注：维生素 B12（必补）、铁、Omega-3（藻油）——见补剂建议")

    return MealPlan(
        meals=meals,
        total_kcal=total_k,
        total_protein_g=total_p,
        total_fat_g=total_f,
        total_carbs_g=total_c,
        fiber_g=fiber_g,
        water_ml_rest=water_rest,
        water_ml_training=water_training,
        diet_notes=diet_notes,
    )
