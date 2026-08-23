"""ProgressionPlanner — 渐进超负荷规则。

生成可执行的渐进规则，以及何时触发重新评估。
"""
from __future__ import annotations

from dataclasses import dataclass, field
from .profile_validator import UserProfile


# ── 渐进规则 ──────────────────────────────────────────────

PROGRESSION_RULES = {
    "beginner":     {"freq": "每周",     "upper_kg": 2.5, "lower_kg": 5.0, "cycle_weeks": 4},
    "intermediate": {"freq": "每2周",    "upper_kg": 2.5, "lower_kg": 5.0, "cycle_weeks": 4},
    "advanced":     {"freq": "每月",     "upper_kg": 1.25, "lower_kg": 2.5, "cycle_weeks": 4},
}


@dataclass
class ReassessmentTrigger:
    condition: str
    action: str
    week: int | None = None

    def to_dict(self) -> dict:
        return {
            "condition": self.condition,
            "action": self.action,
            "week": self.week,
        }


@dataclass
class ProgressionResult:
    strategy: str
    increment_upper_kg: float
    increment_lower_kg: float
    progression_freq: str
    double_progression: str
    next_check_week: int
    deload_every_weeks: int = 4
    deload_volume_pct: int = 60
    deload_note: str = ""
    triggers: list[ReassessmentTrigger] = field(default_factory=list)

    def to_dict(self) -> dict:
        return {
            "strategy": self.strategy,
            "increment_upper_kg": self.increment_upper_kg,
            "increment_lower_kg": self.increment_lower_kg,
            "progression_freq": self.progression_freq,
            "double_progression": self.double_progression,
            "next_check_week": self.next_check_week,
            "deload_every_weeks": self.deload_every_weeks,
            "deload_volume_pct": self.deload_volume_pct,
            "deload_note": self.deload_note,
            "reassessment_triggers": [t.to_dict() for t in self.triggers],
        }


def plan(profile: UserProfile) -> ProgressionResult:
    """生成渐进计划。"""
    rules = PROGRESSION_RULES.get(profile.level, PROGRESSION_RULES["beginner"])

    deload_every = rules["cycle_weeks"]
    deload_pct = 60

    triggers = [
        ReassessmentTrigger(
            condition="体重变化 >2kg",
            action="重新计算 TDEE + 营养素",
        ),
        ReassessmentTrigger(
            condition="训练满 4 周",
            action="全动作组数+1 或试加重",
            week=4,
        ),
        ReassessmentTrigger(
            condition=f"每 {deload_every} 周减载周",
            action=f"组数降至平时的 {deload_pct}%，负荷可略降或不加重量",
            week=deload_every,
        ),
        ReassessmentTrigger(
            condition="训练满 12 周",
            action="建议切换分肢方案，检查是否改目标",
            week=12,
        ),
        ReassessmentTrigger(
            condition="连续 2 周无法完成计划",
            action="下调 10% 容量",
        ),
        ReassessmentTrigger(
            condition="中断 >2 周",
            action="回退 10-20% 容量",
        ),
        ReassessmentTrigger(
            condition="目标变更",
            action="全量重算",
        ),
    ]

    strategy_map = {
        "beginner": "linear_weekly",
        "intermediate": "biweekly_double_progression",
        "advanced": "monthly_periodization",
    }

    return ProgressionResult(
        strategy=strategy_map.get(profile.level, "linear_weekly"),
        increment_upper_kg=rules["upper_kg"],
        increment_lower_kg=rules["lower_kg"],
        progression_freq=rules["freq"],
        double_progression="双进阶：当无法再加重量时：先+1次→达到上限次数后降次加重循环",
        next_check_week=rules["cycle_weeks"],
        deload_every_weeks=deload_every,
        deload_volume_pct=deload_pct,
        deload_note=f"第 {deload_every}、{deload_every * 2}、{deload_every * 3}… 周为减载周：组数×{deload_pct / 100:.1f}，保动作模式、不加重量",
        triggers=triggers,
    )
