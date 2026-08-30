"""FrequencyPlanner — 引擎决定「一周练几天」。

用户只填「每次能练多久」，训练频率是结果不是输入：
在该水平允许的天数范围里，挑**最少的、能兑现每周训练量**的天数。
若连该水平的最多天数、最短课时都兑现不了 → 该课时低于「最低训练时长」，
上调到最低时长（科学健身优先：先保证周训练量）。

依赖真实的 build_sessions + analyze_volume（不做解析近似），
所以调用方需要传入 ExerciseLibrary。
"""
from __future__ import annotations

from dataclasses import dataclass, replace
from typing import Optional

from .profile_validator import UserProfile
from .split_selector import select
from .session_builder import build_sessions, analyze_volume
from .exercise_library import ExerciseLibrary


# 各水平的每周训练天数范围（下限=频率底线，上限=恢复与分肢约束）
LEVEL_DAY_RANGE = {
    "beginner": (3, 3),
    "intermediate": (3, 5),
    "advanced": (3, 6),
}

# 训练量「完成」= 每个肌群 ≥ MEV（自适应 coverage_pct 达到这个即算完成）
COVERAGE_TARGET = 100
# 训练量「到最优」= 相当于 MAV 的百分比达到这个即不必再加天数
OPTIMAL_TARGET = 98

# 课时搜索范围（分钟）
_MIN_SCAN = 30
_MAX_SCAN = 120
_SCAN_STEP = 5


@dataclass
class FrequencyPlan:
    days_per_week: int
    minutes_per_session: int      # 可能被上调到最低训练时长
    min_session_minutes: int      # 保证「训练量完成（≥MEV）」的最短课时
    coverage_pct: int             # 对自适应目标的覆盖率（通常 100）
    vs_optimal_pct: int           # 相当于最优训练量(MAV)的百分比
    minutes_raised: bool          # 是否因低于最低时长而上调
    note: str = ""

    def to_dict(self) -> dict:
        return {
            "days_per_week": self.days_per_week,
            "minutes_per_session": self.minutes_per_session,
            "min_session_minutes": self.min_session_minutes,
            "coverage_pct": self.coverage_pct,
            "vs_optimal_pct": self.vs_optimal_pct,
            "minutes_raised": self.minutes_raised,
            "note": self.note,
        }


def _analyze_at(
    profile: UserProfile, days: int, minutes: int, library: ExerciseLibrary
) -> tuple[int, int]:
    """返回 (coverage_pct, vs_optimal_pct)。"""
    trial = replace(profile, days_per_week=days, minutes_per_session=minutes)
    sp = select(trial)
    sessions = build_sessions(trial, sp, library)
    rep = analyze_volume(trial, sp, sessions)
    return rep["coverage_pct"], rep["vs_optimal_pct"]


def _pick_days(
    profile: UserProfile, minutes: int, library: ExerciseLibrary
) -> tuple[int, int, int]:
    """给定时长，挑天数：优先「最少的、能到最优训练量」的天数；
    没有能到最优的 → 选「相当于最优」最高的天数。
    返回 (天数, coverage_pct, vs_optimal_pct)。"""
    lo, hi = LEVEL_DAY_RANGE.get(profile.level, (3, 5))
    best = None
    for d in range(lo, hi + 1):
        cov, vs_opt = _analyze_at(profile, d, minutes, library)
        if vs_opt >= OPTIMAL_TARGET:
            return d, cov, vs_opt
        if best is None or vs_opt > best[2]:
            best = (d, cov, vs_opt)
    return best


def min_session_minutes(profile: UserProfile, library: ExerciseLibrary) -> int:
    """保证「训练量完成」（每个肌群 ≥ MEV → coverage_pct 达 100）的最短课时。"""
    lo, hi = LEVEL_DAY_RANGE.get(profile.level, (3, 5))
    for m in range(_MIN_SCAN, _MAX_SCAN + 1, _SCAN_STEP):
        if any(
            _analyze_at(profile, d, m, library)[0] >= COVERAGE_TARGET
            for d in range(lo, hi + 1)
        ):
            return m
    return _MAX_SCAN


def min_session_minutes_for(
    level: str, goal: str, equipment: list[str],
    library: Optional[ExerciseLibrary] = None,
) -> int:
    """onboarding 用：在用户选完 目标/水平/器械 后、还没选时长时，
    算出「每次至少练多少分钟」，让 UI 的时长选项从这里起步，
    而不是给一个更短的选项再事后上调。
    """
    library = library or ExerciseLibrary()
    probe = UserProfile(
        gender="M", age=30, height_cm=175.0, weight_kg=75.0,
        level=level, goal=goal, minutes_per_session=60,
        equipment=list(equipment) or ["bodyweight"],
    )
    return min_session_minutes(probe, library)


def plan_frequency(profile: UserProfile, library: ExerciseLibrary) -> FrequencyPlan:
    """决定天数；必要时把课时上调到最低训练时长。

    profile.days_per_week 已显式指定时，尊重该值（只补覆盖率与最低时长信息）。
    """
    requested = profile.minutes_per_session
    min_minutes = min_session_minutes(profile, library)

    if profile.days_per_week is not None:
        days = profile.days_per_week
        cov, vs_opt = _analyze_at(profile, days, requested, library) if days > 0 else (0, 0)
        return FrequencyPlan(
            days_per_week=days,
            minutes_per_session=requested,
            min_session_minutes=min_minutes,
            coverage_pct=cov,
            vs_optimal_pct=vs_opt,
            minutes_raised=False,
            note=f"按你指定的每周 {days} 天安排。",
        )

    minutes = max(requested, min_minutes)
    raised = minutes > requested

    days, coverage, vs_opt = _pick_days(profile, minutes, library)

    if raised:
        note = (
            f"{_goal_cn(profile.goal)}每次至少练 {min_minutes} 分钟才能完成每周训练量，"
            f"已按 {min_minutes} 分钟安排（你填的是 {requested} 分钟）。"
        )
    elif coverage < COVERAGE_TARGET:
        note = (
            f"每次 {minutes} 分钟 / 每周 {days} 天，训练量约 {coverage}%（略欠最低有效量）。"
            f"每次再加长一点可补上。"
        )
    elif vs_opt < OPTIMAL_TARGET:
        note = (
            f"每次 {minutes} 分钟 / 每周 {days} 天，训练量已完成（相当于最优的 {vs_opt}%）。"
            f"想冲最大增速：每次加约 15 分钟。"
        )
    else:
        note = f"每次 {minutes} 分钟 / 每周 {days} 天，训练量到位（已接近最优）。"

    return FrequencyPlan(
        days_per_week=days,
        minutes_per_session=minutes,
        min_session_minutes=min_minutes,
        coverage_pct=coverage,
        vs_optimal_pct=vs_opt,
        minutes_raised=raised,
        note=note,
    )


def resolve(profile: UserProfile, library: ExerciseLibrary) -> tuple[UserProfile, FrequencyPlan]:
    """把「引擎定频率」的结果落到一个新的 UserProfile 上。"""
    fp = plan_frequency(profile, library)
    notes = list(profile.notes)
    if fp.note and fp.note not in notes:
        notes.append(fp.note)
    resolved = replace(
        profile,
        days_per_week=fp.days_per_week,
        minutes_per_session=fp.minutes_per_session,
        notes=notes,
    )
    return resolved, fp


_GOAL_CN = {
    "hypertrophy": "增肌", "fat_loss": "减脂", "strength": "力量", "recomposition": "增肌减脂",
}


def _goal_cn(goal: str) -> str:
    return _GOAL_CN.get(goal, goal)
