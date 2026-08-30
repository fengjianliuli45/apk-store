"""CheckInEngine — 中周期边界的评估 → 调整 → 下一份输入。

    review_cycle(plan_json, workout_log, body_log, completed_cycles) -> CycleReview

规则层，确定性：垂直大模型可解释/陪伴，但不改写这里的结果。
"""
from __future__ import annotations

from dataclasses import dataclass, field

from .stage_goal_planner import StageGoal, OutcomeTarget
from .stage_assessor import assess_stage, StageEvidence
from .response_profiler import profile_response
from .load_planner import BASELINE_LIFTS
from .progress_tracker import (
    aggregate_evidence, aggregate_observation, per_exercise_progress,
    weekly_weight_pct,
)


_LOWER = {"squat", "hinge"}

# 体重周变化率的目标带（%/周）——超出就按 ±150 kcal 微调。
# fat_loss 0.5–1%/周保肌（Helms 2014, PMC4033492）；
# 增肌 0.25–0.5%/周控脂（lean-bulk 文献）。
_KCAL_STEP = 150
_DIET_BANDS = {
    "fat_loss": (-1.1, -0.3),        # 慢于 -0.3 → 加缺口；快于 -1.1 → 减缺口
    "hypertrophy": (0.1, 0.6),       # 慢于 +0.1 → 加盈余；快于 +0.6 → 减盈余
    "recomposition": (-0.35, 0.35),  # 只纠明显偏离
    "strength": (-0.35, 0.5),
}


def _diet_adjust(goal: str, weekly_pct: float | None) -> tuple[int, str]:
    """按体重趋势返回 (kcal 增量, 说明)。数据不足或在目标带内 → (0, "")。

    统一逻辑：体重比目标带低 → 加热量 +150；比目标带高 → 减热量 -150。
    （fat_loss 目标带为负值，掉太快 = 低于下界 → 也是加热量。）
    """
    band = _DIET_BANDS.get(goal)
    if band is None or weekly_pct is None:
        return 0, ""
    low, high = band
    if weekly_pct < low:
        return _KCAL_STEP, f"体重周变化 {weekly_pct:+.2f}%，低于目标带 {low}~{high}%/周，热量上调 {_KCAL_STEP}"
    if weekly_pct > high:
        return -_KCAL_STEP, f"体重周变化 {weekly_pct:+.2f}%，高于目标带 {low}~{high}%/周，热量下调 {_KCAL_STEP}"
    return 0, ""


@dataclass
class LoadChange:
    exercise_id: str
    basis: str | None
    from_kg: float
    to_kg: float
    reason: str

    def to_dict(self) -> dict:
        return {
            "exercise_id": self.exercise_id, "basis": self.basis,
            "from_kg": self.from_kg, "to_kg": self.to_kg, "reason": self.reason,
        }


@dataclass
class CycleReview:
    verdict: str                       # advance | extend | deload_then_retry | address_safety
    summary: str
    assessment: dict
    response_profile: dict
    volume_change: str                 # up_one_step | hold | down_10pct
    makeup_sessions: int
    load_changes: list[LoadChange] = field(default_factory=list)
    unlock_reward: str | None = None
    kcal_change: int = 0               # 下一周期热量增量（相对上一周期），0 = 不变
    diet_note: str = ""
    next_raw: dict = field(default_factory=dict)

    def to_dict(self) -> dict:
        return {
            "verdict": self.verdict,
            "summary": self.summary,
            "assessment": self.assessment,
            "response_profile": self.response_profile,
            "volume_change": self.volume_change,
            "makeup_sessions": self.makeup_sessions,
            "load_changes": [c.to_dict() for c in self.load_changes],
            "unlock_reward": self.unlock_reward,
            "kcal_change": self.kcal_change,
            "diet_note": self.diet_note,
            "next_raw": self.next_raw,
        }


def _stage_goal_from(plan: dict) -> StageGoal:
    sg = plan.get("stage_goal", {})
    return StageGoal(
        stage_type=sg.get("stage_type", "adaptation"),
        goal_type=sg.get("goal_type", "hypertrophy"),
        cycle_weeks=sg.get("cycle_weeks", 4),
        planned_sessions=sg.get("planned_sessions", 12),
        required_sessions=sg.get("required_sessions", 10),
        adherence_target_pct=sg.get("adherence_target_pct", 80),
        minimum_active_weeks=sg.get("minimum_active_weeks", 3),
        minimum_comparable_measurements=sg.get("minimum_comparable_measurements", 2),
        outcome_targets=[OutcomeTarget(**t) for t in sg.get("outcome_targets", [])],
        completion_rule=sg.get("completion_rule", ""),
        unlock_reward=sg.get("unlock_reward", "pet_hatchling"),
        baseline_lifts=sg.get("baseline_lifts", []),
    )


def _basis_of(plan: dict, exercise_id: str) -> str | None:
    """从计划的 one_rm_estimates + baseline_lifts 反推该动作挂哪个基准。"""
    # baseline_lifts 里的顺序 ≈ 复合动作出场序；用动作 id 的关键词粗匹配
    kw = {
        "squat": ("squat", "深蹲", "lunge", "箭步"),
        "bench": ("bench", "press", "卧推", "推举", "dip", "chest"),
        "hinge": ("deadlift", "rdl", "hinge", "硬拉", "thrust", "臀"),
        "row": ("row", "pull", "chin", "划船", "引体", "下拉"),
    }
    eid = exercise_id.lower()
    for basis, keys in kw.items():
        if any(k in eid for k in keys):
            return basis
    return None


def _load_changes(plan: dict, per_ex: dict) -> list[LoadChange]:
    changes: list[LoadChange] = []
    lifts = {b["exercise_id"]: b for b in plan.get("stage_goal", {}).get("baseline_lifts", [])}
    for eid, sig in per_ex.items():
        lift = lifts.get(eid)
        if not lift or not lift.get("start_load_kg"):
            continue
        cur = float(lift["start_load_kg"])
        basis = _basis_of(plan, eid)
        inc = 5.0 if basis in _LOWER else 2.5
        if sig.get("last_all_top_range") and (sig.get("avg_rir") or 3) <= 2:
            changes.append(LoadChange(eid, basis, cur, round(cur + inc, 1), "达到次数上限、留力≤2"))
        elif sig.get("consecutive_below_bottom", 0) >= 2:
            changes.append(LoadChange(eid, basis, cur, round(cur * 0.9 / 2.5) * 2.5, "连续 2 次未达次数下限"))
        elif sig.get("e1rm_declining"):
            changes.append(LoadChange(eid, basis, cur, round(cur * 0.9 / 2.5) * 2.5, "估算 1RM 连降"))
    return changes


def _next_raw(plan: dict, load_changes: list[LoadChange], volume_change: str,
              kcal_delta: int = 0) -> dict:
    prof = plan.get("profile", {})
    one_rm = plan.get("profile", {}).get("one_rm_estimates", {})
    raw = {
        "gender": prof.get("gender"), "age": prof.get("age"),
        "height_cm": prof.get("height_cm"), "weight_kg": prof.get("weight_kg"),
        "level": prof.get("level"), "goal": prof.get("goal"),
        "minutes_per_session": prof.get("minutes_per_session"),
        "days_per_week": prof.get("days_per_week"),
        "equipment": list(prof.get("equipment", [])),
        "body_fat_pct": prof.get("body_fat_pct"),
        "injuries": list(prof.get("injuries", [])),
        "dietary_restrictions": list(prof.get("dietary_restrictions", [])),
        "cooking_access": prof.get("cooking_access"),
        "meals_per_day": prof.get("meals_per_day"),
    }
    # 热量微调：在上一周期基础上累加，钳在 ±500
    prev_kcal = int(prof.get("kcal_adjust", 0) or 0)
    raw["kcal_adjust"] = max(-500, min(500, prev_kcal + int(kcal_delta)))
    # 起始重量：按 load_changes 里「该基准最重的那个动作」的比例更新估算 1RM
    sb = {}
    ratio: dict[str, float] = {}
    heaviest: dict[str, float] = {}
    for c in load_changes:
        if not c.basis or not c.from_kg:
            continue
        if c.from_kg >= heaviest.get(c.basis, 0):
            heaviest[c.basis] = c.from_kg
            ratio[c.basis] = c.to_kg / c.from_kg
    for basis in BASELINE_LIFTS:
        cur = (one_rm.get(basis) or {}).get("kg")
        if cur:
            sb[basis] = {"one_rm_kg": round(cur * ratio.get(basis, 1.0), 1)}
    if sb:
        raw["strength_baseline"] = sb
    if volume_change == "up_one_step":
        raw["volume_cycle_offset"] = int(prof.get("volume_cycle_offset", 0)) + 1
    elif volume_change == "down_10pct":
        raw["volume_cycle_offset"] = max(-2, int(prof.get("volume_cycle_offset", 0)) - 1)
    else:
        raw["volume_cycle_offset"] = int(prof.get("volume_cycle_offset", 0))
    return {k: v for k, v in raw.items() if v is not None}


def review_cycle(
    plan_json: dict,
    workout_log: list[dict],
    body_log: list[dict] | None = None,
    completed_cycles: int = 0,
) -> CycleReview:
    body_log = body_log or []
    goal = _stage_goal_from(plan_json)
    evidence = aggregate_evidence(plan_json, workout_log, body_log)
    assessment = assess_stage(goal, evidence)
    obs = aggregate_observation(plan_json, workout_log, body_log, completed_cycles + 1)
    response = profile_response(obs)
    per_ex = per_exercise_progress(plan_json, workout_log)
    load_changes = _load_changes(plan_json, per_ex)

    if not assessment.safety_met:
        verdict, vol, summary = "address_safety", "hold", "先处理疼痛 / 伤病，患处动作降负荷，再评估"
        makeup = 0
    elif assessment.achieved:
        verdict, vol = "advance", "up_one_step"
        makeup = 0
        summary = "阶段达成：进入下一中周期，训练量往 MRV 推一档，达标动作加重"
    elif evidence.completed_sessions < goal.required_sessions:
        verdict, vol = "extend", "hold"
        makeup = goal.required_sessions - evidence.completed_sessions
        summary = f"出勤未达标（{evidence.completed_sessions}/{goal.required_sessions}），延长 2 周并补 {makeup} 次"
    elif not assessment.outcome_met and evidence.active_weeks >= 3:
        verdict, vol = "deload_then_retry", "down_10pct"
        makeup = 0
        summary = "出勤够但表现停滞：额外减载 1 周，容量下调 10%，再冲一个中周期"
    else:
        verdict, vol = "extend", "hold"
        makeup = 0
        summary = "接近达成：同容量再跑一个中周期，数据攒够即达标"

    # 饮食微调：安全问题优先处理时不动饮食；其余按体重趋势调 ±150 kcal
    kcal_delta, diet_note = (0, "")
    if verdict != "address_safety":
        weekly_pct = weekly_weight_pct(body_log)
        kcal_delta, diet_note = _diet_adjust(
            plan_json.get("profile", {}).get("goal", "hypertrophy"), weekly_pct)

    next_raw = _next_raw(plan_json, load_changes, vol, kcal_delta)

    return CycleReview(
        verdict=verdict,
        summary=summary,
        assessment=assessment.to_dict(),
        response_profile=response.to_dict(),
        volume_change=vol,
        makeup_sessions=makeup,
        load_changes=load_changes,
        unlock_reward=goal.unlock_reward if verdict == "advance" else None,
        kcal_change=kcal_delta,
        diet_note=diet_note,
        next_raw=next_raw,
    )
