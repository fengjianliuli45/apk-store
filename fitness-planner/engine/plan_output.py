"""PlanOutput — 输出层。

将引擎结果序列化为 JSON（API 输出）和人类可读文本。
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from typing import Optional

from .profile_validator import UserProfile
from .tdee_calculator import TDEEResult
from .macro_allocator import MacroResult
from .split_selector import SplitResult
from .session_builder import SessionResult
from .progression_planner import ProgressionResult
from .meal_distributor import MealPlan
from .supplement_advisor import SupplementResult
from .stage_goal_planner import plan_stage_goal


# 全链路用到的论文 PMID
EVIDENCE_BASIS = [
    "41843416",  # ACSM 2026
    "20847704",  # Schoenfeld 2010 增肌三机制
    "28834797",  # Schoenfeld 2017 低vs高负荷
    "27102172",  # Schoenfeld 2016 频率
    "27433992",  # Schoenfeld 2017 剂量反应
    "36334240",  # Refalo 2023 接近力竭
    "28698222",  # Morton 2018 蛋白质 meta
    "29414855",  # Stokes 2018 MPS
    "37432300",  # Burke 2023 肌酸
    "26817506",  # Longland 2016 缺口期高蛋白
]


def generate_json(
    profile: UserProfile,
    tdee: TDEEResult,
    macros: MacroResult,
    split: SplitResult,
    sessions: list[SessionResult],
    progression: ProgressionResult,
    meal_plan: MealPlan,
    supplements: SupplementResult,
    frequency_plan=None,
    recovery_days=None,
    mesocycle=None,
) -> dict:
    """生成完整的 JSON 计划。"""

    # 训练量对账（自适应目标 + 相当于最优的百分比）
    from .session_builder import analyze_volume
    volume_report = analyze_volume(profile, split, sessions)

    from .load_planner import build_one_rm_map, BASELINE_CN
    one_rm = build_one_rm_map(getattr(profile, "strength_baseline", {}) or {})

    return {
        "meta": {
            "version": "1.8",
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "evidence_basis": EVIDENCE_BASIS,
        },
        "profile": {
            "gender": profile.gender,
            "age": profile.age,
            "height_cm": profile.height_cm,
            "weight_kg": profile.weight_kg,
            "bmi": profile.bmi,
            "body_fat_pct": profile.body_fat_pct,
            "level": profile.level,
            "goal": profile.goal,
            "days_per_week": profile.days_per_week,
            "minutes_per_session": profile.minutes_per_session,
            "meals_per_day": profile.meals_per_day,
            "equipment": profile.equipment,
            "injuries": profile.injuries,
            "dietary_restrictions": profile.dietary_restrictions,
            "cooking_access": profile.cooking_access,
            "target_weight_kg": profile.target_weight_kg,
            "volume_cycle_offset": getattr(profile, "volume_cycle_offset", 0),
            "kcal_adjust": getattr(profile, "kcal_adjust", 0),
            "strength_baseline": getattr(profile, "strength_baseline", {}) or {},
            "one_rm_estimates": {b: {"kg": v, "name": BASELINE_CN.get(b, b)} for b, v in one_rm.items()},
            "warnings": profile.warnings,
            "notes": profile.notes,
        },
        "nutrition": {
            "tdee": tdee.to_dict(),
            "macros": macros.to_dict(),
            "meals": meal_plan.to_dict(),
            "supplements": supplements.to_dict()["supplements"],
        },
        "training": {
            "split": split.split_name,
            "weekly_volume_target": volume_report["target"],       # 自适应目标（本计划承诺的量）
            "weekly_volume_optimal": volume_report["optimal"],     # 最优训练量 MAV（上限）
            "weekly_volume_delivered": volume_report["delivered"],
            "weekly_volume_per_group": volume_report["target"],    # 兼容旧字段 = 自适应目标
            "volume_coverage_pct": volume_report["coverage_pct"],  # 对自适应目标，通常 100
            "vs_optimal_pct": volume_report["vs_optimal_pct"],     # 相当于最优的百分比
            "volume_notes": volume_report["notes"],
            "capacity_recommendation": volume_report["recommendation"],
            "frequency_plan": frequency_plan.to_dict() if frequency_plan is not None else None,
            "recovery_days": [rd.to_dict() for rd in (recovery_days or [])],
            "mesocycle": mesocycle.to_dict() if mesocycle is not None else None,
            "schedule": [s.to_dict() for s in sessions],
            "progression": progression.to_dict(),
            "split_warnings": split.warnings,
        },
        "stage_goal": plan_stage_goal(profile, progression, sessions).to_dict(),
    }


def to_json_string(plan: dict, indent: int = 2) -> str:
    """序列化为 JSON 字符串。"""
    return json.dumps(plan, ensure_ascii=False, indent=indent)
