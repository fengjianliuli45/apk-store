"""StageGoalPlanner — 生成首个四周适应期目标。

训练周期和阶段达成分开：ProgressionPlanner 决定何时复评，
本模块把复评周期变成可验证的阶段目标。
"""
from __future__ import annotations

from dataclasses import dataclass, field
from math import ceil

from .profile_validator import UserProfile
from .progression_planner import ProgressionResult
from .session_builder import SessionResult


@dataclass
class OutcomeTarget:
    metric: str
    threshold: float
    unit: str
    description: str
    required: bool = False

    def to_dict(self) -> dict:
        return {
            "metric": self.metric,
            "threshold": self.threshold,
            "unit": self.unit,
            "description": self.description,
            "required": self.required,
        }


@dataclass
class StageGoal:
    stage_type: str
    goal_type: str
    cycle_weeks: int
    planned_sessions: int
    required_sessions: int
    adherence_target_pct: int
    minimum_active_weeks: int
    minimum_comparable_measurements: int
    outcome_targets: list[OutcomeTarget] = field(default_factory=list)
    completion_rule: str = ""
    unlock_reward: str = "pet_hatchling"

    def to_dict(self) -> dict:
        return {
            "stage_type": self.stage_type,
            "goal_type": self.goal_type,
            "cycle_weeks": self.cycle_weeks,
            "planned_sessions": self.planned_sessions,
            "required_sessions": self.required_sessions,
            "adherence_target_pct": self.adherence_target_pct,
            "minimum_active_weeks": self.minimum_active_weeks,
            "minimum_comparable_measurements": self.minimum_comparable_measurements,
            "outcome_targets": [target.to_dict() for target in self.outcome_targets],
            "completion_rule": self.completion_rule,
            "unlock_reward": self.unlock_reward,
        }


def _targets_for(goal: str) -> list[OutcomeTarget]:
    common = [
        OutcomeTarget(
            metric="same_load_rep_gain",
            threshold=2,
            unit="reps",
            description="同一标准化动作在相同负荷下增加至少 2 次规范重复",
        ),
        OutcomeTarget(
            metric="performance_improvement_pct",
            threshold=2.5,
            unit="percent",
            description="标准化动作表现相对基线提高至少 2.5%，并由两次可比较训练确认",
        ),
    ]
    if goal == "fat_loss":
        common.append(OutcomeTarget(
            metric="body_trend_target_met",
            threshold=1,
            unit="boolean",
            description="多日体重趋势或标准化腰围达到个体阶段目标",
        ))
    elif goal in ("hypertrophy", "recomposition"):
        common.append(OutcomeTarget(
            metric="body_trend_target_met",
            threshold=1,
            unit="boolean",
            description="围度、体重或可选体成分趋势支持正向适应",
        ))
    return common


def plan_stage_goal(
    profile: UserProfile,
    progression: ProgressionResult,
    sessions: list[SessionResult],
) -> StageGoal:
    """生成首个适应期目标；阶段长度默认跟随复评周期。"""
    cycle_weeks = max(4, progression.next_check_week)
    weekly_sessions = sum(1 for session in sessions if session.type != "rest")
    planned_sessions = weekly_sessions * cycle_weeks
    required_sessions = ceil(planned_sessions * 0.8) if planned_sessions else 0

    return StageGoal(
        stage_type="adaptation",
        goal_type=profile.goal,
        cycle_weeks=cycle_weeks,
        planned_sessions=planned_sessions,
        required_sessions=required_sessions,
        adherence_target_pct=80,
        minimum_active_weeks=min(3, cycle_weeks),
        minimum_comparable_measurements=2,
        outcome_targets=_targets_for(profile.goal),
        completion_rule=(
            "完成执行与数据质量门槛，并满足至少一个能力或身体趋势结果；"
            "百分比表现提升必须由两次可比较训练确认；"
            "存在未处理安全问题时不得自动达成"
        ),
    )
