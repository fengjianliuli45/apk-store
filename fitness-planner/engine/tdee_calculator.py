"""TDEECalculator — 每日总热量消耗计算。

Mifflin-St Jeor（无体脂）或 Katch-McArdle（有体脂）。
"""
from __future__ import annotations

from dataclasses import dataclass
from .profile_validator import UserProfile


@dataclass
class TDEEResult:
    bmr: float
    tdee: float
    formula_used: str
    activity_multiplier: float
    activity_level: str

    def to_dict(self) -> dict:
        return {
            "bmr": round(self.bmr, 1),
            "tdee": round(self.tdee, 1),
            "formula_used": self.formula_used,
            "activity_multiplier": self.activity_multiplier,
            "activity_level": self.activity_level,
        }


def _select_activity_level(p: UserProfile) -> tuple[float, str]:
    """根据训练参数选择活动乘数。"""
    d = p.days_per_week
    m = p.minutes_per_session
    if d == 0:
        return 1.20, "sedentary"
    if d <= 2 or m <= 30:
        return 1.375, "light"
    if 3 <= d <= 4:
        return 1.55, "moderate"
    if 5 <= d <= 6 and m >= 60:
        return 1.725, "active"
    if d == 7:
        return 1.90, "very_active"
    # 默认落在 moderate
    return 1.55, "moderate"


def calculate(profile: UserProfile) -> TDEEResult:
    """计算 BMR 和 TDEE。"""
    if profile.body_fat_pct is not None:
        # Katch-McArdle
        lean = profile.lean_mass_kg
        bmr = 370 + 21.6 * lean
        formula = "katch_mcardle"
    else:
        # Mifflin-St Jeor
        w = profile.weight_kg
        h = profile.height_cm
        a = profile.age
        if profile.gender == "M":
            bmr = 10 * w + 6.25 * h - 5 * a + 5
        else:
            bmr = 10 * w + 6.25 * h - 5 * a - 161
        formula = "mifflin_st_jeor"

    multiplier, level = _select_activity_level(profile)
    tdee = bmr * multiplier

    return TDEEResult(
        bmr=bmr,
        tdee=tdee,
        formula_used=formula,
        activity_multiplier=multiplier,
        activity_level=level,
    )
