"""LoadPlanner — 把「65-80% 1RM」这种百分比变成具体重量（kg）。

采集（onboarding，混合式）：
- 有器械：对 4 个基准动作做一组，填「重量 × 次数」→ Epley 反推 1RM
- 做不了 / 不确定 / 徒手：留空 → 首周按 RPE 找重量，系统记录

推算：每个动作标一个「基准 + 系数」，
    建议重量 = 基准 1RM × 系数 × 目标 %1RM，取整到 2.5kg。
"""
from __future__ import annotations

from math import floor

from .exercise_library import Exercise


# 4 个基准动作（onboarding 采集）
BASELINE_LIFTS = ("squat", "bench", "hinge", "row")

BASELINE_CN = {
    "squat": "深蹲", "bench": "卧推", "hinge": "硬拉/罗马尼亚硬拉", "row": "划船",
}

# movement_pattern → (基准, 相对基准的系数)
_PATTERN_BASIS = {
    "squat": ("squat", 1.0),
    "hip_hinge": ("hinge", 1.0),
    "knee_flexion": ("hinge", 0.35),      # 腿弯举
    "hip_extension": ("hinge", 0.5),      # 臀桥 / 背伸展
    "calf_raise": ("squat", 0.55),
    "horizontal_push": ("bench", 1.0),
    "vertical_push": ("bench", 0.62),     # 推举 ≈ 卧推 0.62
    "horizontal_pull": ("row", 1.0),
    "vertical_pull": ("row", 0.9),        # 高位下拉 ≈ 划船 0.9
    "elbow_flexion": ("bench", 0.28),     # 弯举
    "elbow_extension": ("bench", 0.32),   # 臂屈伸 / 下压
}

# 常见动作的单独系数覆盖（相对同基准）。哑铃类系数按「每只手」计。
_EXERCISE_COEF = {
    "goblet_squat": ("squat", 0.35),        # 单只哑铃抱胸
    "bodyweight_squat": (None, 0.0),
    "front_squat": ("squat", 0.85),
    "leg_press": ("squat", 2.0),
    "bulgarian_split_squat": ("squat", 0.32),
    "walking_lunges": ("squat", 0.28),      # 每只
    "dumbbell_rdl": ("hinge", 0.38),        # 每只
    "romanian_deadlift": ("hinge", 0.85),
    "hip_thrust": ("hinge", 1.1),
    "incline_barbell_press": ("bench", 0.85),
    "incline_dumbbell_press": ("bench", 0.34),
    "dumbbell_bench_press": ("bench", 0.42),
    "overhead_press": ("bench", 0.62),
    "dumbbell_shoulder_press": ("bench", 0.26),
    "seated_dumbbell_press": ("bench", 0.26),
    "dumbbell_row": ("row", 0.45),
    "seated_cable_row": ("row", 1.0),
    "lat_pulldown": ("row", 0.9),
    "barbell_curl": ("bench", 0.3),
    "dumbbell_curl": ("bench", 0.14),
}

_NO_LOAD_PATTERNS = {"core", "trunk_flexion", "trunk_rotation", "anti_extension"}


def estimate_1rm(weight_kg: float, reps: int) -> float:
    """Epley 公式。次数超过 12 精度下降，截断到 12。"""
    r = max(1, min(int(reps), 12))
    return floor(weight_kg * (1 + r / 30) * 10 + 0.5) / 10


def build_one_rm_map(strength_baseline: dict) -> dict[str, float]:
    """onboarding 的 {basis: {weight_kg, reps}} 或 {basis: {one_rm_kg}} → {basis: 1RM}。"""
    out: dict[str, float] = {}
    for basis, v in (strength_baseline or {}).items():
        if basis not in BASELINE_LIFTS or not isinstance(v, dict):
            continue
        if v.get("one_rm_kg"):
            out[basis] = float(v["one_rm_kg"])
        elif v.get("weight_kg") and v.get("reps"):
            out[basis] = estimate_1rm(float(v["weight_kg"]), int(v["reps"]))
    return out


def _basis_and_coef(ex: Exercise) -> tuple[str | None, float]:
    if ex.id in _EXERCISE_COEF:
        return _EXERCISE_COEF[ex.id]
    if ex.movement_pattern in _NO_LOAD_PATTERNS:
        return None, 0.0
    return _PATTERN_BASIS.get(ex.movement_pattern, (None, 0.0))


def _round_2p5(x: float) -> float:
    return floor(x / 2.5 + 0.5) * 2.5


def suggest_load(
    ex: Exercise,
    one_rm_map: dict[str, float],
    load_pct_mid: float,
    load_pct_label: str,
) -> tuple[str, float | None]:
    """返回 (显示文本, 建议重量kg或None)。

    没有对应基准 1RM，或该动作本就徒手/自重 → 文本为「首周按 RPE 找重量」。
    """
    # 纯自重动作：不给 kg，按次数 / 难度阶梯递进
    if list(ex.equipment_required) == ["bodyweight"]:
        return "自重（按次数 / 难度递进）", None

    basis, coef = _basis_and_coef(ex)
    if basis is None or coef <= 0:
        return f"首周按 RPE 找重量（目标 {load_pct_label}）", None
    one_rm = one_rm_map.get(basis)
    if not one_rm:
        return f"首周按 RPE 找重量（目标 {load_pct_label}）", None
    working = _round_2p5(one_rm * coef * load_pct_mid)
    if working < 2.5:
        return f"首周按 RPE 找重量（目标 {load_pct_label}）", None
    per_hand = "dumbbell" in ex.equipment_required and "barbell" not in ex.equipment_required
    unit = " kg/只" if per_hand else " kg"
    return f"{working:g}{unit}（{load_pct_label}）", working
