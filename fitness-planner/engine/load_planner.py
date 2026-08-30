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


# 自重动作举起的「体重占比」——研究实测（JSCR / Suprak 2011 PMID 20179649；ExRx）。
# 用来把「一次做多少个」换成等效负荷，再走 Epley 估 e1RM。
_BODYMASS_FRACTION = {
    # 水平推
    "push_up": 0.64, "wide_push_up": 0.64, "close_grip_push_up": 0.64,
    "diamond_push_up": 0.64, "incline_push_up": 0.45, "decline_push_up": 0.75,
    "archer_push_up": 0.80, "knee_push_up": 0.49, "bench_dips": 0.40,
    # 垂直推
    "pike_push_up": 0.60, "elevated_pike_push_up": 0.70, "handstand_push_up": 1.0,
    # 垂直拉 / 水平拉
    "pull_up": 1.0, "chin_up": 1.0, "assisted_pull_up": 0.55,
    "inverted_row": 0.60, "feet_elevated_inverted_row": 0.75,
    # 下肢 蹲
    "bodyweight_squat": 0.68, "split_squat": 0.85, "reverse_lunge": 0.85,
    "lunges": 0.85, "step_up": 0.85, "sissy_squat": 0.75, "single_leg_squat": 1.0,
    # 髋铰链 / 髋伸展
    "single_leg_rdl_bw": 0.55, "glute_bridge": 0.40, "single_leg_glute_bridge": 0.55,
    "bodyweight_hip_thrust": 0.55, "single_leg_hip_thrust": 0.75, "frog_pump": 0.35,
    # 勾腿
    "sliding_leg_curl": 0.50, "nordic_curl": 0.65,
    # 提踵
    "bodyweight_calf_raise": 0.95, "single_leg_calf_raise": 1.0,
}

# 兜底：动作不在表里但是纯自重时，按 movement_pattern 给个保守占比
_BW_PATTERN_FRACTION = {
    "horizontal_push": 0.60, "vertical_push": 0.60,
    "vertical_pull": 0.95, "horizontal_pull": 0.60,
    "squat": 0.70, "hip_hinge": 0.55, "hip_extension": 0.45,
    "knee_flexion": 0.50, "calf_raise": 0.90,
}

_BW_REP_CAP = 20   # 徒手常做高次数，Epley 截断放宽到 20（相对追踪仍成立）


def estimate_1rm(weight_kg: float, reps: int) -> float:
    """Epley 公式。次数超过 12 精度下降，截断到 12。"""
    r = max(1, min(int(reps), 12))
    return floor(weight_kg * (1 + r / 30) * 10 + 0.5) / 10


def bodyweight_e1rm(bodyweight_kg: float, ex: Exercise, reps: int) -> float | None:
    """徒手动作：体重 × 体重占比 × Epley → 等效负荷 e1RM（kg）。

    占比查不到（等长动作 / 核心 / 弹力带）→ None。
    """
    frac = _BODYMASS_FRACTION.get(ex.id)
    if frac is None and list(ex.equipment_required) == ["bodyweight"]:
        frac = _BW_PATTERN_FRACTION.get(ex.movement_pattern)
    if not frac or not bodyweight_kg or not reps:
        return None
    r = max(1, min(int(reps), _BW_REP_CAP))
    return floor(bodyweight_kg * frac * (1 + r / 30) * 10 + 0.5) / 10


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
    # 纯自重动作：不给 kg，按次数 / 难度阶梯递进（进阶提示由 session_builder 覆盖）
    if list(ex.equipment_required) == ["bodyweight"]:
        return "自重（按次数 / 难度递进）", None

    # 弹力带：选能做到目标次数、末组留 1-2 次的阻力（换更粗的带 / 缩短带长进阶）
    if list(ex.equipment_required) == ["band"]:
        return "弹力带 · 选阻力做到目标次数、末组留 1-2 次；变强了换更粗的带或缩短带长", None

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
