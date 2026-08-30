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

from .profile_validator import UserProfile
from .split_selector import select
from .session_builder import build_sessions, analyze_volume
from .exercise_library import ExerciseLibrary


# 各水平的每周训练天数范围（下限=频率底线，上限=恢复与分肢约束）
LEVEL_DAY_RANGE = {
    "beginner": (3, 4),
    "intermediate": (3, 5),
    "advanced": (3, 6),
}

# 判定「兑现周训练量」的覆盖率门槛
COVERAGE_TARGET = 92

# 课时搜索范围（分钟）
_MIN_SCAN = 30
_MAX_SCAN = 120
_SCAN_STEP = 5


@dataclass
class FrequencyPlan:
    days_per_week: int
    minutes_per_session: int      # 可能被上调到最低训练时长
    min_session_minutes: int      # 该 (水平,目标,器械) 达标所需的最短课时
    coverage_pct: int             # 最终方案的覆盖率
    minutes_raised: bool          # 是否因低于最低时长而上调
    note: str = ""

    def to_dict(self) -> dict:
        return {
            "days_per_week": self.days_per_week,
            "minutes_per_session": self.minutes_per_session,
            "min_session_minutes": self.min_session_minutes,
            "coverage_pct": self.coverage_pct,
            "minutes_raised": self.minutes_raised,
            "note": self.note,
        }


def _coverage_at(profile: UserProfile, days: int, library: ExerciseLibrary) -> int:
    trial = replace(profile, days_per_week=days)
    sp = select(trial)
    sessions = build_sessions(trial, sp, library)
    return analyze_volume(trial, sp, sessions)["coverage_pct"]


def _fewest_days_hitting_target(
    profile: UserProfile, minutes: int, library: ExerciseLibrary
) -> tuple[int, int, bool]:
    """返回 (天数, 覆盖率, 是否达标)。达标=覆盖率≥门槛；否则返回覆盖率最高的天数。"""
    lo, hi = LEVEL_DAY_RANGE.get(profile.level, (3, 5))
    trial_minutes = replace(profile, minutes_per_session=minutes)
    best_days, best_cov = hi, -1
    for d in range(lo, hi + 1):
        cov = _coverage_at(trial_minutes, d, library)
        if cov >= COVERAGE_TARGET:
            return d, cov, True
        if cov > best_cov:
            best_days, best_cov = d, cov
    return best_days, best_cov, False


def min_session_minutes(profile: UserProfile, library: ExerciseLibrary) -> int:
    """能兑现周训练量的最短课时（5 分钟为粒度）。"""
    for m in range(_MIN_SCAN, _MAX_SCAN + 1, _SCAN_STEP):
        _, _, hit = _fewest_days_hitting_target(profile, m, library)
        if hit:
            return m
    return _MAX_SCAN


def plan_frequency(profile: UserProfile, library: ExerciseLibrary) -> FrequencyPlan:
    """决定天数；必要时把课时上调到最低训练时长。

    profile.days_per_week 已显式指定时，尊重该值（只补覆盖率与最低时长信息）。
    """
    requested = profile.minutes_per_session
    min_minutes = min_session_minutes(profile, library)

    if profile.days_per_week is not None:
        days = profile.days_per_week
        coverage = _coverage_at(profile, days, library) if days > 0 else 0
        return FrequencyPlan(
            days_per_week=days,
            minutes_per_session=requested,
            min_session_minutes=min_minutes,
            coverage_pct=coverage,
            minutes_raised=False,
            note=f"按你指定的每周 {days} 天安排。",
        )

    minutes = max(requested, min_minutes)
    raised = minutes > requested

    days, coverage, hit = _fewest_days_hitting_target(profile, minutes, library)

    if raised:
        note = (
            f"{_goal_cn(profile.goal)}每次至少练 {min_minutes} 分钟才能保证每周训练量，"
            f"已按 {min_minutes} 分钟安排（你填的是 {requested} 分钟）。"
        )
    elif not hit:
        note = (
            f"即使每次 {minutes} 分钟、每周 {days} 天，周训练量也只到约 {coverage}%。"
            f"把每次时间再加长可完整兑现。"
        )
    else:
        note = f"按你每次 {minutes} 分钟，安排每周 {days} 天即可兑现目标训练量。"

    return FrequencyPlan(
        days_per_week=days,
        minutes_per_session=minutes,
        min_session_minutes=min_minutes,
        coverage_pct=coverage,
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
