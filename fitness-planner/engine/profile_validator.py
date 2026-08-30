"""ProfileValidator — 用户输入校验与标准化。

接收原始用户输入 → 校验 → 补默认值 → 输出标准化 UserProfile。
"""

from __future__ import annotations

from dataclasses import dataclass, field, asdict
from typing import Optional

# ── 字段分类 ──────────────────────────────────────────────

REQUIRED_FIELDS = (
    "gender", "age", "height_cm", "weight_kg",
    "level", "goal", "minutes_per_session", "equipment",
)

OPTIONAL_WITH_DEFAULT = {
    "days_per_week": None,       # None → 由 frequency_planner 按时长/目标/水平推导
    "body_fat_pct": None,        # None → 走 Mifflin-St Jeor
    "meals_per_day": 4,
    "supplements": ["creatine"], # 默认建议肌酸
    "target_weight_kg": None,
    "injuries": [],
    "dietary_restrictions": [],
    "cooking_access": "home",
}

TRACKING_ONLY = (
    "arm_cm", "waist_cm", "chest_cm", "fitness_test_data",
)

VALID_GENDERS = ("M", "F")
VALID_LEVELS = ("beginner", "intermediate", "advanced")
VALID_GOALS = ("hypertrophy", "fat_loss", "strength", "recomposition")
VALID_COOKING = ("home", "canteen", "none")


@dataclass
class UserProfile:
    """标准化用户画像。"""
    gender: str
    age: int
    height_cm: float
    weight_kg: float
    level: str
    goal: str
    minutes_per_session: int
    equipment: list[str]
    # optional
    days_per_week: Optional[int] = None   # None → 由 frequency_planner 推导
    body_fat_pct: Optional[float] = None
    meals_per_day: int = 4
    supplements: list[str] = field(default_factory=lambda: ["creatine"])
    target_weight_kg: Optional[float] = None
    injuries: list[str] = field(default_factory=list)
    dietary_restrictions: list[str] = field(default_factory=list)
    cooking_access: str = "home"
    # 校验时生成的元信息
    warnings: list[str] = field(default_factory=list)
    notes: list[str] = field(default_factory=list)

    @property
    def bmi(self) -> float:
        h = self.height_cm / 100
        return round(self.weight_kg / (h * h), 1)

    @property
    def lean_mass_kg(self) -> float:
        if self.body_fat_pct is not None:
            return self.weight_kg * (1 - self.body_fat_pct / 100)
        return self.weight_kg

    def to_dict(self) -> dict:
        return asdict(self)


class ValidationError(Exception):
    """校验错误集合。"""

    def __init__(self, errors: list[str]):
        self.errors = errors
        super().__init__(self.__str__())

    def __str__(self) -> str:
        return "Profile validation failed:\n" + "\n".join(f"  - {e}" for e in self.errors)


# ── 校验器 ────────────────────────────────────────────────

def validate(raw: dict) -> UserProfile:
    """校验原始输入，返回 UserProfile 或抛出 ValidationError。

    required 字段缺失 → 报错
    optional_with_default → 补默认值并记录 note
    tracking_only → 忽略
    """
    errors: list[str] = []
    warnings: list[str] = []
    notes: list[str] = []

    # 1. required 字段检查
    for fname in REQUIRED_FIELDS:
        if fname not in raw or raw[fname] is None:
            errors.append(f"缺少必填字段: {fname}")

    if errors:
        raise ValidationError(errors)

    # 2. 提取 required 值并做类型/范围校验
    gender = str(raw["gender"]).upper()
    if gender not in VALID_GENDERS:
        errors.append(f"gender 必须是 {VALID_GENDERS}，得到: {gender}")

    age = raw["age"]
    if not isinstance(age, (int, float)):
        errors.append(f"age 必须是数字，得到: {type(age).__name__}")
    elif not (16 <= age <= 80):
        errors.append(f"age 范围应为 16-80，得到: {age}")

    height_cm = float(raw["height_cm"])
    if not (120 <= height_cm <= 250):
        errors.append(f"height_cm 范围应为 120-250，得到: {height_cm}")

    weight_kg = float(raw["weight_kg"])
    if not (35 <= weight_kg <= 250):
        errors.append(f"weight_kg 范围应为 35-250，得到: {weight_kg}")

    level = str(raw["level"]).lower()
    if level not in VALID_LEVELS:
        errors.append(f"level 必须是 {VALID_LEVELS}，得到: {level}")

    goal = str(raw["goal"]).lower()
    if goal not in VALID_GOALS:
        errors.append(f"goal 必须是 {VALID_GOALS}，得到: {goal}")

    # days_per_week 可选：不填 → None，交给 frequency_planner 按时长/目标/水平推导
    raw_days = raw.get("days_per_week")
    if raw_days is None:
        days_per_week = None
        notes.append("未指定训练天数，将按每次时长/目标/水平自动安排")
    else:
        days_per_week = int(raw_days)
        if not (0 <= days_per_week <= 7):
            errors.append(f"days_per_week 范围应为 0-7，得到: {days_per_week}")

    minutes_per_session = int(raw["minutes_per_session"])
    if not (0 <= minutes_per_session <= 180):
        errors.append(f"minutes_per_session 范围应为 0-180，得到: {minutes_per_session}")

    equipment = raw["equipment"]
    if not isinstance(equipment, list):
        errors.append(f"equipment 必须是列表，得到: {type(equipment).__name__}")
    elif len(equipment) == 0:
        equipment = ["bodyweight"]
        notes.append("equipment 为空，默认使用 bodyweight")

    if errors:
        raise ValidationError(errors)

    # 3. optional 字段补默认值
    body_fat_pct = raw.get("body_fat_pct", None)
    if body_fat_pct is not None:
        body_fat_pct = float(body_fat_pct)
        if not (3 <= body_fat_pct <= 60):
            errors.append(f"body_fat_pct 范围应为 3-60，得到: {body_fat_pct}")
    else:
        notes.append("body_fat_pct 未提供，将使用 Mifflin-St Jeor 公式")

    meals_per_day = int(raw.get("meals_per_day", 4))
    if not (1 <= meals_per_day <= 8):
        warnings.append(f"meals_per_day={meals_per_day} 不在常见范围 1-8，已保留")
        meals_per_day = max(1, min(meals_per_day, 8))

    supplements = raw.get("supplements", ["creatine"])
    if not isinstance(supplements, list):
        supplements = ["creatine"]
        notes.append("supplements 格式不对，默认为 ['creatine']")

    target_weight_kg = raw.get("target_weight_kg", None)
    if target_weight_kg is not None:
        target_weight_kg = float(target_weight_kg)

    injuries = raw.get("injuries", [])
    if not isinstance(injuries, list):
        injuries = []

    dietary_restrictions = raw.get("dietary_restrictions", [])
    if not isinstance(dietary_restrictions, list):
        dietary_restrictions = []

    cooking_access = raw.get("cooking_access", "home")
    if cooking_access not in VALID_COOKING:
        warnings.append(f"cooking_access={cooking_access} 不在 {VALID_COOKING}，默认 home")
        cooking_access = "home"

    if errors:
        raise ValidationError(errors)

    # 4. 业务逻辑警告
    bmi = weight_kg / ((height_cm / 100) ** 2)
    if bmi < 15:
        warnings.append(f"BMI={bmi:.1f} 偏低（<15），建议咨询医生")
    elif bmi > 40:
        warnings.append(f"BMI={bmi:.1f} 偏高（>40），建议咨询医生")

    if days_per_week == 1:
        warnings.append("days_per_week=1 训练频率过低，建议至少 2 天")

    if goal == "strength" and level == "beginner":
        warnings.append("力量目标+新手 → 建议先以增肌打基础（hypertrophy）3-6 个月")

    # 5. 构建 UserProfile
    profile = UserProfile(
        gender=gender,
        age=int(age),
        height_cm=height_cm,
        weight_kg=weight_kg,
        level=level,
        goal=goal,
        days_per_week=days_per_week,
        minutes_per_session=minutes_per_session,
        equipment=equipment,
        body_fat_pct=body_fat_pct,
        meals_per_day=meals_per_day,
        supplements=supplements,
        target_weight_kg=target_weight_kg,
        injuries=injuries,
        dietary_restrictions=dietary_restrictions,
        cooking_access=cooking_access,
        warnings=warnings,
        notes=notes,
    )
    return profile
