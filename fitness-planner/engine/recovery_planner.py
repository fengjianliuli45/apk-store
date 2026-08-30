"""RecoveryPlanner — 把日程里的 rest 日填成有内容的「轻日」。

原则：不抢主课的恢复。
- 减脂：rest 日补低强度有氧（Zone2）——减脂的核心刺激是热量缺口，有氧直接补。
- 增肌 / 增肌减脂 且主课没排满、且非新手：补 1 天「快恢复肌群」泵感课
  （二头/三头/小腿/核心/侧平举，低强度，24 小时恢复，不影响第二天大动作）。
- 新手：rest 日只给主动恢复（拉伸 + 走路），缺的量靠加长单次时间，不靠加练。
- 至少保留 1 天完全休息（当 rest 日 ≥ 2 时）。
- 每天都有内容 → 服务「每天开 App / 连续天数 / 宠物」。
"""
from __future__ import annotations

from dataclasses import dataclass, field

from .profile_validator import UserProfile
from .split_selector import SplitResult, DAY_NAMES


PUMP_MOVES = {
    "biceps": ("二头弯举", "哑铃 / 弹力带，3 组 × 15 次，慢放"),
    "triceps": ("三头下压 / 窄距俯卧撑", "3 组 × 15–20 次"),
    "calves": ("站姿提踵", "3 组 × 20 次，顶峰停 1 秒"),
    "core": ("卷腹 + 侧支撑", "卷腹 3×15，侧支撑 3×30 秒/侧"),
    "shoulders": ("哑铃侧平举", "3 组 × 15 次，轻重量"),
}

MOBILITY_ITEMS = [
    "动态拉伸 / 关节活动 8 分钟",
    "6000 步，或散步 15 分钟",
    "泡沫轴放松 5 分钟",
]

CARDIO_ITEMS = [
    "快走 / 椭圆机 / 单车 25–35 分钟，心率 60–70% 最大",
    "结束后静态拉伸 5 分钟",
]


@dataclass
class RecoveryDay:
    day: str
    kind: str            # rest | mobility | cardio | pump
    duration_min: int
    title: str
    focus: str
    items: list[str] = field(default_factory=list)

    def to_dict(self) -> dict:
        return {
            "day": self.day,
            "kind": self.kind,
            "duration_min": self.duration_min,
            "title": self.title,
            "focus": self.focus,
            "items": self.items,
        }


def _rest_days(split: SplitResult) -> list[str]:
    return [d["day"] for d in split.weekly_schedule if d["type"] == "rest"]


def plan_recovery(
    profile: UserProfile,
    split: SplitResult,
    volume_report: dict,
) -> list[RecoveryDay]:
    rest_days = _rest_days(split)
    if not rest_days:
        return []

    goal = profile.goal
    level = profile.level
    coverage = int(volume_report.get("coverage_pct", 100))
    vs_opt = int(volume_report.get("vs_optimal_pct", 100))
    n_rest = len(rest_days)

    # 完全休息天数：文献——新手 2–3 天、中高级 1–2 天，即使高级也留 1 天。
    # 但减脂要留出有氧日、增肌欠量要留泵感课日，所以完全休息让位给这些「补量」日。
    want_full = 2 if level == "beginner" else 1
    if goal == "fat_loss":
        want_cardio = min(2, max(0, n_rest - 1))
    else:
        want_cardio = 0
    want_pump = (
        1 if goal in ("hypertrophy", "recomposition") and level != "beginner"
        and vs_opt < 92 and n_rest - want_cardio - 1 >= 1
        else 0
    )
    keep_full = min(want_full, max(1 if n_rest else 0, n_rest - want_cardio - want_pump))
    keep_full = min(keep_full, n_rest)

    keep_full_days = rest_days[n_rest - keep_full:] if keep_full else []
    fillable = rest_days[: n_rest - keep_full]

    days: list[RecoveryDay] = []
    i = 0

    if want_cardio:
        for _ in range(min(want_cardio, len(fillable))):
            days.append(RecoveryDay(
                day=fillable[i], kind="cardio", duration_min=30,
                title="低强度有氧",
                focus="减脂靠热量缺口，有氧日直接补上这部分",
                items=list(CARDIO_ITEMS),
            ))
            i += 1
    elif want_pump and i < len(fillable):
        # 取还没到最优、且恢复快的肌群
        delivered = volume_report.get("delivered", {})
        opt = volume_report.get("optimal", {})
        targets = [m for m in ("biceps", "triceps", "calves", "core")
                   if delivered.get(m, 0) < opt.get(m, 999)]
        targets = (targets or ["biceps", "triceps", "calves"])[:4]
        items = [f"{PUMP_MOVES[m][0]} — {PUMP_MOVES[m][1]}" for m in targets if m in PUMP_MOVES]
        days.append(RecoveryDay(
            day=fillable[i], kind="pump", duration_min=20,
            title="快恢复肌群泵感课",
            focus=f"主课相当于最优的 {vs_opt}%，这 20 分钟补上手臂/小腿/核心，往最优推一点，不抢大动作的恢复",
            items=items,
        ))
        i += 1

    for d in fillable[i:]:
        days.append(RecoveryDay(
            day=d, kind="mobility", duration_min=12,
            title="主动恢复",
            focus="拉伸 + 走路，保持每天的训练习惯",
            items=list(MOBILITY_ITEMS),
        ))

    for d in keep_full_days:
        days.append(RecoveryDay(
            day=d, kind="rest", duration_min=0,
            title="完全休息",
            focus="睡够，让肌肉和神经系统恢复",
            items=[],
        ))

    order = {name: idx for idx, name in enumerate(DAY_NAMES)}
    days.sort(key=lambda rd: order.get(rd.day, 99))
    return days
