"""SessionBuilder — 训练编排。

对每一天的训练日，生成具体动作列表及其参数。
容量分配 → 训练变量 → 动作编排。

容量按「真实日程中的肌群周频」回算，并受单次肌群上限与课时时长约束。
"""
from __future__ import annotations

from dataclasses import dataclass, field
from .profile_validator import UserProfile
from .split_selector import SplitResult
from .exercise_library import ExerciseLibrary


# ── 每周总组数（按 level） ─────────────────────────────────

WEEKLY_VOLUME = {
    "beginner":     {"chest": 10, "back": 12, "quads": 10, "hamstrings": 6, "shoulders": 8, "biceps": 6, "triceps": 6, "calves": 4, "core": 4},
    "intermediate": {"chest": 14, "back": 16, "quads": 14, "hamstrings": 8, "shoulders": 12, "biceps": 8, "triceps": 8, "calves": 6, "core": 6},
    "advanced":     {"chest": 18, "back": 20, "quads": 18, "hamstrings": 10, "shoulders": 16, "biceps": 10, "triceps": 10, "calves": 8, "core": 8},
}

# 单次训练单肌群组数上限（超出则周容量无法在低频日程上完全兑现）
MAX_SETS_PER_MUSCLE_SESSION = {
    "beginner": 6,
    "intermediate": 10,
    "advanced": 12,
}

# ── 训练变量（按 goal） ────────────────────────────────────

TRAINING_VARS = {
    "hypertrophy":     {"load_pct": "65-80% 1RM", "reps": "8-12", "sets_range": (3, 4), "rest_sec": 90,  "rpe": 7.5, "tempo": "3-1-2-0", "rir": "1-3"},
    "strength":        {"load_pct": "≥80% 1RM",   "reps": "3-6",  "sets_range": (4, 5), "rest_sec": 150, "rpe": 8.0, "tempo": "受控",   "rir": "1-2"},
    "fat_loss":        {"load_pct": "60-75% 1RM", "reps": "10-15","sets_range": (3, 4), "rest_sec": 45,  "rpe": 7.0, "tempo": "3-1-2-0", "rir": "2-3"},
    "recomposition":   {"load_pct": "65-80% 1RM", "reps": "8-12", "sets_range": (3, 4), "rest_sec": 90,  "rpe": 7.5, "tempo": "3-1-2-0", "rir": "1-3"},
}

# ── 训练类型 → 目标肌群映射 ────────────────────────────────

SESSION_MUSCLES = {
    "push":        ["chest", "shoulders", "triceps"],
    "pull":        ["back", "biceps", "rear_delt"],
    "legs":        ["quads", "hamstrings", "glutes", "calves"],
    "upper":       ["chest", "back", "shoulders", "biceps", "triceps"],
    "lower":       ["quads", "hamstrings", "glutes", "calves"],
    "full_body":   ["chest", "back", "quads", "hamstrings", "shoulders"],
    "core":        ["core", "abs"],
}

# 兼容旧引用；容量计算改走真实日程频次
SPLIT_FREQUENCY = {
    "full_body":         {"chest": 2, "back": 2, "quads": 2, "hamstrings": 2, "shoulders": 2, "biceps": 2, "triceps": 2, "calves": 1, "core": 2},
    "upper_lower":       {"chest": 2, "back": 2, "quads": 2, "hamstrings": 2, "shoulders": 2, "biceps": 2, "triceps": 2, "calves": 2, "core": 1},
    "push_pull_legs":    {"chest": 1.5, "back": 1.5, "quads": 1.5, "hamstrings": 1, "shoulders": 1.5, "biceps": 1.5, "triceps": 1.5, "calves": 1, "core": 1},
    "ppl_upper_lower":   {"chest": 2, "back": 2, "quads": 2, "hamstrings": 1.5, "shoulders": 2.5, "biceps": 2, "triceps": 2, "calves": 1, "core": 1},
    "ppl_ppl":           {"chest": 2, "back": 2, "quads": 2, "hamstrings": 2, "shoulders": 2.5, "biceps": 2, "triceps": 2, "calves": 2, "core": 1},
}


@dataclass
class ExerciseEntry:
    name: str
    name_en: str
    exercise_id: str
    sets: int
    reps: str
    load: str
    rest_sec: int
    rpe: float
    tempo: str
    notes: str
    order: int
    primary_muscles: list[str] = field(default_factory=list)
    compound: bool = False
    form_cues: list[str] = field(default_factory=list)

    def to_dict(self) -> dict:
        return {
            "name": self.name,
            "name_en": self.name_en,
            "exercise_id": self.exercise_id,
            "sets": self.sets,
            "reps": self.reps,
            "load": self.load,
            "rest_sec": self.rest_sec,
            "rpe": self.rpe,
            "tempo": self.tempo,
            "notes": self.notes,
            "order": self.order,
            "primary_muscles": self.primary_muscles,
            "compound": self.compound,
            "form_cues": self.form_cues,
        }


@dataclass
class SessionResult:
    day: str
    type: str
    duration_min: int
    exercises: list[ExerciseEntry]
    total_sets: int

    def to_dict(self) -> dict:
        return {
            "day": self.day,
            "type": self.type,
            "duration_min": self.duration_min,
            "exercises": [e.to_dict() for e in self.exercises],
            "total_sets": self.total_sets,
        }


def _actual_muscle_frequency(schedule: list[dict]) -> dict[str, int]:
    """按真实周日程统计每个肌群被安排的训练日次数。"""
    freq: dict[str, int] = {}
    for day_info in schedule:
        session_type = day_info["type"]
        if session_type == "rest":
            continue
        for muscle in SESSION_MUSCLES.get(session_type, []):
            freq[muscle] = freq.get(muscle, 0) + 1
    return freq


def _sets_per_session_map(
    weekly_volume: dict[str, int],
    frequency: dict[str, int],
    level: str,
) -> dict[str, int]:
    """周目标 ÷ 真实周频，并截断到单次肌群上限。"""
    cap = MAX_SETS_PER_MUSCLE_SESSION.get(level, 8)
    out: dict[str, int] = {}
    for muscle, total_sets in weekly_volume.items():
        freq = max(1, frequency.get(muscle, 0))
        per = max(2, round(total_sets / freq))
        out[muscle] = min(per, cap)
    return out


def _estimate_set_seconds(rest_sec: int) -> int:
    """单组耗时粗估：做组 ~45s + 组间休息。"""
    return 45 + rest_sec


def build_sessions(
    profile: UserProfile,
    split: SplitResult,
    library: ExerciseLibrary,
) -> list[SessionResult]:
    """为每周每一天生成训练计划。"""
    level = profile.level
    goal = profile.goal
    vars_ = TRAINING_VARS.get(goal, TRAINING_VARS["hypertrophy"])
    weekly_volume = WEEKLY_VOLUME.get(level, WEEKLY_VOLUME["beginner"])
    frequency = _actual_muscle_frequency(split.weekly_schedule)
    muscle_sets_per_session = _sets_per_session_map(weekly_volume, frequency, level)

    # 课时预算（留 ~15% 给热身/换器械）
    budget_sec = max(15 * 60, int(profile.minutes_per_session * 60 * 0.85))
    set_cost = _estimate_set_seconds(vars_["rest_sec"])
    sets_range = vars_["sets_range"]

    sessions = []
    for day_info in split.weekly_schedule:
        day_name = day_info["day"]
        session_type = day_info["type"]

        if session_type == "rest":
            sessions.append(SessionResult(
                day=day_name, type="rest", duration_min=0,
                exercises=[], total_sets=0,
            ))
            continue

        target_muscles = SESSION_MUSCLES.get(session_type, [])

        exercises = library.query(
            exercise_type=session_type,
            equipment=profile.equipment,
            injuries=profile.injuries,
            level=level,
        )
        exercises.sort(key=lambda e: (not e.compound, e.skill_level != "beginner"))

        session_exercises: list[ExerciseEntry] = []
        order = 1
        used_ids: set[str] = set()
        used_sec = 0

        for muscle in target_muscles:
            sets_needed = muscle_sets_per_session.get(muscle)
            if sets_needed is None:
                # 无独立周配额的辅助肌群：少量补充
                if muscle in ("glutes", "rear_delt"):
                    sets_needed = 3
                else:
                    continue
            if sets_needed <= 0:
                continue

            remaining_budget_sets = max(0, (budget_sec - used_sec) // set_cost)
            if remaining_budget_sets < 2:
                break
            sets_needed = min(sets_needed, remaining_budget_sets)

            muscle_exercises = [
                e for e in exercises
                if muscle in e.primary_muscles and e.id not in used_ids
            ]
            if not muscle_exercises:
                muscle_exercises = [
                    e for e in exercises
                    if muscle in e.secondary_muscles and e.id not in used_ids
                ]
            if not muscle_exercises:
                continue

            remaining_sets = sets_needed
            candidates = muscle_exercises[:3]  # 最多 3 个动作凑满该肌群组数
            n_ex = len(candidates)
            for i, ex in enumerate(candidates):
                if remaining_sets <= 0:
                    break
                remaining_budget_sets = max(0, (budget_sec - used_sec) // set_cost)
                if remaining_budget_sets < 2:
                    break

                # 前几个动作按常规组数；最后一个吃掉剩余（仍受课时约束）
                if i == n_ex - 1:
                    sets = min(remaining_sets, remaining_budget_sets)
                else:
                    sets = min(remaining_sets, sets_range[1], remaining_budget_sets)

                if sets < sets_range[0]:
                    if remaining_sets >= 2 and i == n_ex - 1:
                        sets = min(remaining_sets, remaining_budget_sets)
                    elif remaining_sets >= sets_range[0]:
                        sets = sets_range[0]
                    else:
                        break
                if sets < 2:
                    break

                entry = ExerciseEntry(
                    name=ex.name,
                    name_en=ex.name_en,
                    exercise_id=ex.id,
                    sets=sets,
                    reps=vars_["reps"],
                    load=vars_["load_pct"],
                    rest_sec=vars_["rest_sec"],
                    rpe=vars_["rpe"],
                    tempo=vars_["tempo"],
                    notes=f"RIR {vars_['rir']}",
                    order=order,
                    primary_muscles=ex.primary_muscles,
                    compound=ex.compound,
                    form_cues=ex.form_cues,
                )
                session_exercises.append(entry)
                used_ids.add(ex.id)
                order += 1
                remaining_sets -= sets
                used_sec += sets * set_cost

        total_sets = sum(e.sets for e in session_exercises)
        # 实际估时（分钟），不超过用户设定
        est_min = min(
            profile.minutes_per_session,
            max(0, round(used_sec / 60) + max(5, int(profile.minutes_per_session * 0.15))),
        ) if total_sets else 0
        sessions.append(SessionResult(
            day=day_name,
            type=session_type,
            duration_min=est_min or profile.minutes_per_session,
            exercises=session_exercises,
            total_sets=total_sets,
        ))

    return sessions
