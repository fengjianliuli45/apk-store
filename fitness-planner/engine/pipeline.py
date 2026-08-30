"""Pipeline — 从原始输入到完整计划 JSON 的一站式编排。

调用方（测试、Flutter PlannerGateway 的对照基准）用这个入口，
避免手动串联 10+ 个模块导致 Python/Dart 逐步漂移。

    validate → frequency_planner.resolve → tdee → macros →
    split → sessions → progression → meals → supplements → plan_output
"""
from __future__ import annotations

from typing import Optional

from .profile_validator import validate, UserProfile
from .frequency_planner import resolve as resolve_frequency, FrequencyPlan
from .tdee_calculator import calculate
from .macro_allocator import allocate
from .split_selector import select
from .schedule_planner import reschedule
from .session_builder import build_sessions
from .progression_planner import plan as plan_progression
from .meal_distributor import distribute
from .supplement_advisor import advise
from .recovery_planner import plan_recovery
from .session_builder import analyze_volume
from .exercise_library import ExerciseLibrary
from .plan_output import generate_json


def generate_plan(raw: dict, library: Optional[ExerciseLibrary] = None) -> dict:
    """跑完整链路，返回计划 JSON（含 training.frequency_plan）。"""
    library = library or ExerciseLibrary()

    profile = validate(raw)
    profile, freq_plan = resolve_frequency(profile, library)

    tdee = calculate(profile)
    macros = allocate(profile, tdee)
    split = reschedule(profile, select(profile))
    sessions = build_sessions(profile, split, library)
    progression = plan_progression(profile)
    meals = distribute(profile, macros)
    supplements = advise(profile, macros)
    recovery_days = plan_recovery(profile, split, analyze_volume(profile, split, sessions))

    return generate_json(
        profile, tdee, macros, split, sessions, progression, meals, supplements,
        frequency_plan=freq_plan,
        recovery_days=recovery_days,
    )
