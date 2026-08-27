"""StageAssessor — 用可复现规则判定适应期达成。"""
from __future__ import annotations

from dataclasses import dataclass, field

from .stage_goal_planner import StageGoal


@dataclass
class StageEvidence:
    completed_sessions: int
    active_weeks: int
    comparable_measurements: int
    performance_improvement_pct: float | None = None
    performance_confirmations: int = 0
    same_load_rep_gain: int | None = None
    body_trend_target_met: bool = False
    stable_positive_response: bool = False
    unresolved_safety_issue: bool = False


@dataclass
class StageAssessment:
    achieved: bool
    status: str
    adherence_met: bool
    data_quality_met: bool
    outcome_met: bool
    safety_met: bool
    confidence: str
    reasons: list[str] = field(default_factory=list)
    next_action: str = ""

    def to_dict(self) -> dict:
        return {
            "achieved": self.achieved,
            "status": self.status,
            "adherence_met": self.adherence_met,
            "data_quality_met": self.data_quality_met,
            "outcome_met": self.outcome_met,
            "safety_met": self.safety_met,
            "confidence": self.confidence,
            "reasons": self.reasons,
            "next_action": self.next_action,
        }


def assess_stage(goal: StageGoal, evidence: StageEvidence) -> StageAssessment:
    reasons: list[str] = []
    adherence_met = (
        evidence.completed_sessions >= goal.required_sessions
        and evidence.active_weeks >= goal.minimum_active_weeks
    )
    if not adherence_met:
        reasons.append(
            f"执行门槛未达成：需要 {goal.required_sessions} 次、"
            f"覆盖 {goal.minimum_active_weeks} 周"
        )

    data_quality_met = evidence.comparable_measurements >= goal.minimum_comparable_measurements
    if not data_quality_met:
        reasons.append(f"可比较测量不足：至少需要 {goal.minimum_comparable_measurements} 次")

    performance_met = (
        (
            (evidence.performance_improvement_pct or 0) >= 2.5
            and evidence.performance_confirmations >= 2
        )
        or (evidence.same_load_rep_gain or 0) >= 2
    )
    outcome_met = performance_met or evidence.body_trend_target_met or evidence.stable_positive_response
    if not outcome_met:
        reasons.append("尚未观察到可复测的能力提升或稳定正向身体趋势")

    safety_met = not evidence.unresolved_safety_issue
    if not safety_met:
        reasons.append("存在未处理的疼痛、伤病或安全问题")

    achieved = adherence_met and data_quality_met and outcome_met and safety_met
    if achieved:
        return StageAssessment(
            achieved=True,
            status="achieved",
            adherence_met=True,
            data_quality_met=True,
            outcome_met=True,
            safety_met=True,
            confidence="high",
            reasons=["第一阶段适应目标已达成"],
            next_action="生成宠物幼体并创建下一阶段目标",
        )

    confidence = "low" if not data_quality_met else "medium"
    next_action = "先处理安全问题，再重新评估" if not safety_met else "延长阶段 2 周并调整容量或动作"
    return StageAssessment(
        achieved=False,
        status="extended",
        adherence_met=adherence_met,
        data_quality_met=data_quality_met,
        outcome_met=outcome_met,
        safety_met=safety_met,
        confidence=confidence,
        reasons=reasons,
        next_action=next_action,
    )
