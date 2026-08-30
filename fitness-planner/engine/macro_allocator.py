"""MacroAllocator — 三大营养素分配。

根据 TDEE + goal 计算蛋白质、脂肪、碳水目标。
"""
from __future__ import annotations

from dataclasses import dataclass, field
from .profile_validator import UserProfile
from .tdee_calculator import TDEEResult
from .food_db import normalize_restrictions


@dataclass
class MacroResult:
    daily_targets: dict       # kcal, protein_g, fat_g, carbs_g
    per_kg: dict              # protein, fat, carbs
    surplus_kcal: int         # 正=盈余, 负=缺口, 0=维持
    goal: str
    notes: list = field(default_factory=list)

    def to_dict(self) -> dict:
        return {
            "daily_targets": self.daily_targets,
            "per_kg": self.per_kg,
            "surplus_kcal": self.surplus_kcal,
            "goal": self.goal,
            "notes": self.notes,
        }


# 植物蛋白消化率 / 亮氨酸偏低 → 上调 g/kg（PMC11281145, MDPI 16(8)1122）
DIET_PROTEIN_BUMP = {
    "vegan": 0.3,
    "vegetarian": 0.2,
}


# ── 热量方向 ──────────────────────────────────────────────

GOAL_SURPLUS = {
    "hypertrophy": 350,    # +300~500, 默认 350
    "fat_loss": -400,      # -300~-500, 默认 -400
    "strength": 200,       # 维持或微盈
    "recomposition": 0,    # 维持
}

# ── 蛋白质 g/kg ───────────────────────────────────────────

PROTEIN_PER_KG = {
    "hypertrophy": 2.0,
    "fat_loss": 2.2,
    "strength": 1.8,
    "recomposition": 1.8,
}

# ── 脂肪 g/kg ─────────────────────────────────────────────

FAT_PER_KG = {
    "hypertrophy": 1.0,
    "fat_loss": 0.8,
    "strength": 1.0,
    "recomposition": 1.0,
}

PROTEIN_KCAL_PER_G = 4
FAT_KCAL_PER_G = 9
CARB_KCAL_PER_G = 4


def allocate(profile: UserProfile, tdee: TDEEResult) -> MacroResult:
    """计算三大营养素目标。"""
    goal = profile.goal
    w = profile.weight_kg
    notes: list[str] = []

    surplus = GOAL_SURPLUS.get(goal, 0)
    kcal_adjust = int(getattr(profile, "kcal_adjust", 0) or 0)
    daily_kcal = tdee.tdee + surplus + kcal_adjust
    if kcal_adjust:
        direction = "上调" if kcal_adjust > 0 else "下调"
        notes.append(f"按上一周期体重趋势，热量已{direction} {abs(kcal_adjust)} kcal")

    protein_per_kg = PROTEIN_PER_KG[goal]
    restrictions = normalize_restrictions(getattr(profile, "dietary_restrictions", []))
    if "vegan" in restrictions:
        protein_per_kg += DIET_PROTEIN_BUMP["vegan"]
        notes.append("纯素：蛋白已上调 +0.3 g/kg，优先豆制品/大豆蛋白粉（亮氨酸足）")
    elif "vegetarian" in restrictions:
        protein_per_kg += DIET_PROTEIN_BUMP["vegetarian"]
        notes.append("蛋奶素：蛋白已上调 +0.2 g/kg，多用乳清/蛋/豆制品")

    protein_g = round(protein_per_kg * w, 1)
    fat_g = round(FAT_PER_KG[goal] * w, 1)

    protein_kcal = protein_g * PROTEIN_KCAL_PER_G
    fat_kcal = fat_g * FAT_KCAL_PER_G
    carbs_kcal = daily_kcal - protein_kcal - fat_kcal
    carbs_g = round(carbs_kcal / CARB_KCAL_PER_G, 1)

    # 安全检查：碳水不应为负
    if carbs_g < 0:
        carbs_g = 0.0
        # 重新限制总热量
        daily_kcal = protein_kcal + fat_kcal

    return MacroResult(
        daily_targets={
            "kcal": round(daily_kcal),
            "protein_g": protein_g,
            "fat_g": fat_g,
            "carbs_g": carbs_g,
        },
        per_kg={
            "protein": round(protein_g / w, 1),
            "fat": round(fat_g / w, 1),
            "carbs": round(carbs_g / w, 1),
        },
        surplus_kcal=surplus,
        goal=goal,
        notes=notes,
    )
