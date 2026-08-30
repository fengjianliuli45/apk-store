"""SplitSelector — 分肢方案选择。

根据 days_per_week / level / goal → 自动匹配分肢方案。
"""
from __future__ import annotations

from dataclasses import dataclass
from .profile_validator import UserProfile


@dataclass
class SplitResult:
    split_name: str
    weekly_schedule: list[dict]   # [{day, type}]
    warnings: list[str]

    def to_dict(self) -> dict:
        return {
            "split_name": self.split_name,
            "weekly_schedule": self.weekly_schedule,
            "warnings": self.warnings,
        }


DAY_NAMES = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]

# 每种分肢的日历模板（不含休息日）
SPLIT_TEMPLATES = {
    "full_body": ["full_body", "rest", "full_body", "rest", "full_body", "rest", "rest"],
    "full_body_4": ["full_body", "full_body", "rest", "full_body", "full_body", "rest", "rest"],
    "push_pull_legs": ["push", "pull", "legs", "rest", "push", "pull", "rest"],
    "upper_lower": ["upper", "lower", "rest", "upper", "lower", "rest", "rest"],
    "ppl_upper_lower": ["push", "pull", "legs", "upper", "lower", "rest", "rest"],
    "ppl_ppl": ["push", "pull", "legs", "push", "pull", "legs", "rest"],
}


def select(profile: UserProfile) -> SplitResult:
    """根据 days_per_week 映射分肢方案。"""
    d = profile.days_per_week
    level = profile.level
    warnings: list[str] = []

    # 决策逻辑
    if d == 2:
        split_name = "full_body"
    elif d == 3:
        # 全身 3 次/周：给定训练量下频率更高，比 3 天 PPL（每肌群 1 次/周）
        # 显著更能兑现周容量。各水平统一全身。
        split_name = "full_body"
        if level != "beginner":
            warnings.append("3 天训练用全身分肢（每肌群 2–3 次/周）比 PPL 更高效；想练 PPL 建议加到 6 天")
    elif d == 4:
        # 新手 4 天仍走全身（每肌群 4 次/周），中级以上用上下分肢
        split_name = "full_body_4" if level == "beginner" else "upper_lower"
    elif d == 5:
        split_name = "ppl_upper_lower"
    elif d == 6:
        split_name = "ppl_ppl"
    elif d == 7:
        split_name = "ppl_ppl"
        warnings.append("每周训练 7 天不推荐，建议至少安排 1 天休息")
    elif d == 1:
        split_name = "full_body"
        warnings.append("每周仅 1 天训练，效果有限，建议至少 2 天")
    else:
        split_name = "full_body"

    template = SPLIT_TEMPLATES[split_name]

    # 根据 days_per_week 截取训练日：模板中超出 d 个训练日的位置改为休息
    training_seen = 0
    adjusted = []
    for day_type in template:
        if day_type != "rest":
            if training_seen < d:
                adjusted.append(day_type)
                training_seen += 1
            else:
                adjusted.append("rest")
        else:
            adjusted.append("rest")

    schedule = []
    for i, day_type in enumerate(adjusted):
        schedule.append({"day": DAY_NAMES[i], "type": day_type})

    return SplitResult(
        split_name=split_name,
        weekly_schedule=schedule,
        warnings=warnings,
    )
