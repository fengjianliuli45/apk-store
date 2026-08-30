"""MesocyclePlanner — 把「一份周计划」展开成 4–6 周中周期。

现代循证做法（RP / autoregulation 文献）：
- 积累期若干周：容量从 ~MEV 线性爬到 MAV，RIR 从 3 递减到 0–1
- 末周减载：组数砍到 ~55%、保持重量、RIR 放松，5–7 天把疲劳清掉
- 组间负荷进阶在中周期边界由 check-in 按实际表现处理（双进阶）

本模块只产结构：每周对基准 session 的「组数覆盖」+ RIR 目标。
session 的动作、重量、时长仍来自 session_builder（基准 = MAV 那一周）。
"""
from __future__ import annotations

from dataclasses import dataclass, field
from math import floor

from .profile_validator import UserProfile
from .progression_planner import ProgressionResult
from .session_builder import SessionResult


def _round(x: float) -> int:
    return floor(x + 0.5)


VOL_START, VOL_END = 0.7, 1.0     # 积累期首周 → 末周的容量系数
RIR_START, RIR_END = 3, 0


@dataclass
class WeekPlan:
    week: int
    phase: str                     # accumulation | deload
    rir_target: int
    is_deload: bool
    volume_mult: float
    set_overrides: dict            # {day: {exercise_id: sets}}
    week_total_sets: int

    def to_dict(self) -> dict:
        return {
            "week": self.week,
            "phase": self.phase,
            "rir_target": self.rir_target,
            "is_deload": self.is_deload,
            "volume_mult": round(self.volume_mult, 2),
            "set_overrides": self.set_overrides,
            "week_total_sets": self.week_total_sets,
        }


@dataclass
class Mesocycle:
    length_weeks: int
    current_week: int
    weeks: list[WeekPlan] = field(default_factory=list)

    def to_dict(self) -> dict:
        return {
            "length_weeks": self.length_weeks,
            "current_week": self.current_week,
            "weeks": [w.to_dict() for w in self.weeks],
        }


def _week_plan(
    num: int, phase: str, rir: int, vmult: float,
    sessions: list[SessionResult], is_deload: bool,
) -> WeekPlan:
    overrides: dict = {}
    total = 0
    for s in sessions:
        if s.type == "rest" or not s.exercises:
            continue
        day_ov: dict = {}
        for e in s.exercises:
            scaled = max(2, _round(e.sets * vmult))
            day_ov[e.exercise_id] = scaled
            total += scaled
        overrides[s.day] = day_ov
    return WeekPlan(num, phase, rir, is_deload, vmult, overrides, total)


def plan_mesocycle(
    profile: UserProfile,
    sessions: list[SessionResult],
    progression: ProgressionResult,
    current_week: int = 1,
) -> Mesocycle:
    build_weeks = max(3, progression.next_check_week)
    weeks: list[WeekPlan] = []
    for w in range(1, build_weeks + 1):
        frac = (w - 1) / max(1, build_weeks - 1)
        vmult = VOL_START + (VOL_END - VOL_START) * frac
        rir = _round(RIR_START - (RIR_START - RIR_END) * frac)
        weeks.append(_week_plan(w, "accumulation", rir, vmult, sessions, False))
    deload_mult = max(0.4, progression.deload_volume_pct / 100)
    weeks.append(_week_plan(build_weeks + 1, "deload", 3, deload_mult, sessions, True))
    return Mesocycle(
        length_weeks=build_weeks + 1,
        current_week=max(1, min(current_week, build_weeks + 1)),
        weeks=weeks,
    )
