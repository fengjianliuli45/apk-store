"""SchedulePlanner — 按肌群恢复速度把 N 次训练摆到周一~周日。

split_selector 只定「训练日的类型序列」（推→拉→腿→上→下…），
本模块定「摆哪几天」：枚举所有摆法，挑一个让每个肌群「相邻两次训练间隔
≥ 它的恢复窗口」的方案，间隔越均匀、周末越轻越好。

恢复窗口（日历天，同肌群相邻两次训练的最小/理想间隔）——文献：
一般 48h 够、48–72h 最优、大肌群+高容量到 72h；小肌群恢复更快。
"""
from __future__ import annotations

from itertools import combinations

from .profile_validator import UserProfile
from .split_selector import SplitResult, DAY_NAMES
from .session_builder import SESSION_MUSCLES


# 最小间隔（天）：大肌群绝不连续两天
RECOVERY_MIN_GAP = {
    "quads": 2, "hamstrings": 2, "back": 2, "glutes": 2, "chest": 2,
    "shoulders": 2, "biceps": 2, "triceps": 2, "rear_delt": 2,
    "calves": 1, "core": 1, "abs": 1,
}
# 理想间隔（天）：打分用
RECOVERY_IDEAL_GAP = {
    "quads": 3, "hamstrings": 3, "back": 3, "glutes": 3, "chest": 3,
    "shoulders": 2, "biceps": 2, "triceps": 2, "rear_delt": 2,
    "calves": 2, "core": 2, "abs": 2,
}
_DEFAULT_MIN, _DEFAULT_IDEAL = 2, 2


def _max_consecutive(days: list[int]) -> int:
    days = sorted(days)
    best = run = 1
    for a, b in zip(days, days[1:]):
        run = run + 1 if b == a + 1 else 1
        best = max(best, run)
    return best


def _score_placement(placement: list[int], seq_muscles: list[set[str]]) -> float | None:
    """None = 不可行（大肌群间隔 < 最小值）。否则返回分数（越小越好）。"""
    muscle_days: dict[str, list[int]] = {}
    for idx, day in enumerate(placement):
        for m in seq_muscles[idx]:
            muscle_days.setdefault(m, []).append(day)

    score = 0.0
    for m, dd in muscle_days.items():
        if len(dd) < 2:
            continue
        dd = sorted(dd)
        gaps = [b - a for a, b in zip(dd, dd[1:])] + [dd[0] + 7 - dd[-1]]
        if min(gaps) < RECOVERY_MIN_GAP.get(m, _DEFAULT_MIN):
            return None
        ideal = RECOVERY_IDEAL_GAP.get(m, _DEFAULT_IDEAL)
        score += sum((g - ideal) ** 2 for g in gaps)

    # 周末（周六=5 / 周日=6）训练轻惩罚
    score += 0.5 * sum(1 for d in placement if d >= 5)
    # 连续硬练超过 3 天：惩罚
    consec = _max_consecutive(placement)
    if consec > 3:
        score += (consec - 3) * 3
    return score


def reschedule(profile: UserProfile, split: SplitResult) -> SplitResult:
    """返回同 split_name、但按恢复窗口重排日历的 SplitResult。"""
    sequence = [d["type"] for d in split.weekly_schedule if d["type"] != "rest"]
    n = len(sequence)
    if not (2 <= n <= 7):
        return split

    seq_muscles = [set(SESSION_MUSCLES.get(t, [])) for t in sequence]

    best_score: float | None = None
    best_combo: tuple[int, ...] | None = None
    for combo in combinations(range(7), n):
        s = _score_placement(list(combo), seq_muscles)
        if s is None:
            continue
        if best_score is None or s < best_score:
            best_score, best_combo = s, combo

    if best_combo is None:
        return split  # 没有可行摆法（当前分肢不会发生），退回模板

    day_type = ["rest"] * 7
    for idx, day in enumerate(best_combo):
        day_type[day] = sequence[idx]

    schedule = [{"day": DAY_NAMES[k], "type": day_type[k]} for k in range(7)]
    return SplitResult(
        split_name=split.split_name,
        weekly_schedule=schedule,
        warnings=list(split.warnings),
    )
