"""SessionBuilder — 训练编排。

对每一天的训练日，生成具体动作列表及其参数。
容量分配 → 训练变量 → 动作编排。

容量模型（2026-08-30 重构，任务 ①）：
- 周目标按「本周该肌群实际被安排的训练日次数」拆到每一节课，且**前重后轻**
  （第一次暴露拿稍多，后续拿余量），这样混合分肢（PPL+上下）里靠后的
  “上肢/下肢”日不会把所有肌群又满量练一遍，日次组数更均衡。
- 单次每肌群受 MAX_SETS_PER_MUSCLE_SESSION 上限约束。
- 课时预算：先扣显式热身时间，再按「按动作类型区分的单组真实耗时」把剩余时间填满。
- 时间不够兑现周目标时，不再静默截断——由 analyze_volume() 产出
  target / delivered / 差额提示（诚实层）。
"""
from __future__ import annotations

from dataclasses import dataclass, field
from math import ceil, floor
from .profile_validator import UserProfile
from .split_selector import SplitResult
from .exercise_library import ExerciseLibrary


def _round(x: float) -> int:
    """半数向上取整（正数域），与 Dart num.round() 对齐，避免 Python 银行家舍入
    在 Python↔Dart 之间产生 1 的偏差。"""
    return floor(x + 0.5)


# ── 每周总组数 ────────────────────────────────────────────
# 基准表 = 增肌目标。其他目标按 GOAL_VOLUME_SCALE 缩放：
# 力量走低容量高强度（组间 2–3 分钟），减脂受热量缺口影响恢复略降。
_BASE_WEEKLY_VOLUME = {
    "beginner":     {"chest": 10, "back": 12, "quads": 10, "hamstrings": 6, "shoulders": 8, "biceps": 6, "triceps": 6, "calves": 4, "core": 4},
    "intermediate": {"chest": 14, "back": 16, "quads": 14, "hamstrings": 8, "shoulders": 12, "biceps": 8, "triceps": 8, "calves": 6, "core": 6},
    "advanced":     {"chest": 16, "back": 18, "quads": 16, "hamstrings": 10, "shoulders": 14, "biceps": 10, "triceps": 10, "calves": 8, "core": 8},
}

GOAL_VOLUME_SCALE = {
    "hypertrophy": 1.0,
    "recomposition": 0.9,
    "fat_loss": 0.85,
    "strength": 0.85,
}

# 兼容旧引用：WEEKLY_VOLUME 仍指增肌基准表
WEEKLY_VOLUME = _BASE_WEEKLY_VOLUME


def weekly_volume_for(level: str, goal: str) -> dict[str, int]:
    """按 level + goal 返回缩放后的每周每肌群组数。"""
    base = _BASE_WEEKLY_VOLUME.get(level, _BASE_WEEKLY_VOLUME["beginner"])
    scale = GOAL_VOLUME_SCALE.get(goal, 1.0)
    return {m: max(2, _round(v * scale)) for m, v in base.items()}

# 单次训练单肌群组数上限。证据：每肌群每次 6–8 个有效组最优，>10–12 组疲劳拖累、
# 收益骤降（Schoenfeld 剂量反应 / 容量地标 MEV-MAV-MRV）。
MAX_SETS_PER_MUSCLE_SESSION = {
    "beginner": 6,
    "intermediate": 9,
    "advanced": 12,
}

# 周目标铺到每次暴露：整除 + 余数摊到靠前的场次（前重后轻各差 1 组），
# 再各自封顶到单次上限。封顶损失的量计入差额提示。

# ── 训练变量（按 goal） ────────────────────────────────────

TRAINING_VARS = {
    "hypertrophy":     {"load_pct": "65-80% 1RM", "reps": "8-12", "sets_range": (3, 4), "rest_sec": 90,  "rpe": 7.5, "tempo": "3-1-2-0", "rir": "1-3"},
    "strength":        {"load_pct": "≥80% 1RM",   "reps": "3-6",  "sets_range": (3, 5), "rest_sec": 150, "rpe": 8.0, "tempo": "受控",   "rir": "1-2"},
    "fat_loss":        {"load_pct": "60-75% 1RM", "reps": "10-15","sets_range": (3, 4), "rest_sec": 45,  "rpe": 7.0, "tempo": "3-1-2-0", "rir": "2-3"},
    "recomposition":   {"load_pct": "65-80% 1RM", "reps": "8-12", "sets_range": (3, 4), "rest_sec": 90,  "rpe": 7.5, "tempo": "3-1-2-0", "rir": "1-3"},
}

# ── 时间估算常量 ──────────────────────────────────────────
# 处方里的 rest_sec 是「组间休息下限」；实操中复合大动作会歇更久，做组本身也更慢
# （上下器械、找配重、离心节奏）。这里只用于**估时**，不改动作的处方参数。
WORK_SEC_COMPOUND = 55        # 一组复合动作的做组时间
WORK_SEC_ISOLATION = 35       # 一组孤立动作的做组时间
REST_MULT_COMPOUND = 1.4      # 复合动作实际组间休息 ≈ 处方 × 1.4
WARMUP_SEC_PER_BIG_MUSCLE = 90   # 每个复合大肌群 ~2 组递增热身
WARMUP_CAP_SEC = 8 * 60         # 单节热身时间上限
BIG_MUSCLES = ("chest", "back", "quads", "hamstrings", "shoulders")

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

# 无独立周配额的辅助肌群：每次固定少量补充
ACCESSORY_SETS = {"glutes": 3, "rear_delt": 3}

# 某些分肢日里把小肌群当「次要」：主肌群配额吃饱后才用余量补，单次封顶更低，
# 欠量归入「复合动作间接带到」而非「加时间」。
# 例：upper 日胸背肩复合打满，二头三头吃复合的间接刺激 + 末尾少量补。
SECONDARY_MUSCLES_BY_TYPE = {
    "upper": {"biceps", "triceps"},
}
SECONDARY_SESSION_CAP = 3

# 差额提示里给的肌群中文名
_MUSCLE_CN = {
    "chest": "胸", "back": "背", "quads": "股四头", "hamstrings": "腘绳",
    "shoulders": "肩", "biceps": "二头", "triceps": "三头", "calves": "小腿", "core": "核心",
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
    target_muscle: str = ""  # 这个动作是为哪个肌群配额排进来的（容量统计用）

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
            "target_muscle": self.target_muscle,
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


def _actual_muscle_frequency(schedule: list[dict], primary_only: bool = False) -> dict[str, int]:
    """按真实周日程统计每个肌群被安排的训练日次数。

    primary_only=True 时，只数「该肌群在当天不是次要肌群」的场次。
    """
    freq: dict[str, int] = {}
    for day_info in schedule:
        session_type = day_info["type"]
        if session_type == "rest":
            continue
        secondary = SECONDARY_MUSCLES_BY_TYPE.get(session_type, set()) if primary_only else set()
        for muscle in SESSION_MUSCLES.get(session_type, []):
            if muscle in secondary:
                continue
            freq[muscle] = freq.get(muscle, 0) + 1
    return freq


def _set_seconds(prescribed_rest: int, compound: bool) -> int:
    """单组真实耗时估计（做组 + 实际组间休息），仅用于排课估时。"""
    if compound:
        return WORK_SEC_COMPOUND + _round(prescribed_rest * REST_MULT_COMPOUND)
    return WORK_SEC_ISOLATION + prescribed_rest


def _distribute_weekly(weekly_target: int, frequency: int, cap: int) -> list[int]:
    """把周目标铺成每次暴露的组数序列，前重后轻，各次封顶到 cap。

    例：14 组 / 2 次 / 上限 9 → [7, 7]；10 / 3 / 6 → [4, 3, 3]；
        14 / 1 / 9 → [9]（余 5 无法兑现，由差额提示反映）。
    """
    freq = max(1, frequency)
    base, rem = divmod(weekly_target, freq)
    seq = [base + (1 if i < rem else 0) for i in range(freq)]
    return [min(cap, s) for s in seq]


def build_sessions(
    profile: UserProfile,
    split: SplitResult,
    library: ExerciseLibrary,
) -> list[SessionResult]:
    """为每周每一天生成训练计划。"""
    level = profile.level
    goal = profile.goal
    vars_ = TRAINING_VARS.get(goal, TRAINING_VARS["hypertrophy"])
    weekly_volume = weekly_volume_for(level, goal)
    cap = MAX_SETS_PER_MUSCLE_SESSION.get(level, 8)
    frequency = _actual_muscle_frequency(split.weekly_schedule)
    prescribed_rest = vars_["rest_sec"]
    sets_range = vars_["sets_range"]

    total_budget_sec = max(15 * 60, profile.minutes_per_session * 60)

    # 每个肌群的每次暴露目标序列（前重后轻），跨天按暴露次序取用
    distribution: dict[str, list[int]] = {
        m: _distribute_weekly(wk, frequency.get(m, 0), cap)
        for m, wk in weekly_volume.items()
    }
    exposure: dict[str, int] = {}   # 某肌群本周已暴露次数

    sessions: list[SessionResult] = []
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
        secondary = SECONDARY_MUSCLES_BY_TYPE.get(session_type, set())
        primary_muscles_today = [m for m in target_muscles if m not in secondary]
        secondary_muscles_today = [m for m in target_muscles if m in secondary]

        # 本节课每个肌群的目标组数：取该肌群第 k 次暴露对应的配额
        session_targets: dict[str, int] = {}
        for muscle in target_muscles:
            if muscle not in weekly_volume:
                session_targets[muscle] = ACCESSORY_SETS.get(muscle, 0)
                continue
            k = exposure.get(muscle, 0)
            seq = distribution.get(muscle, [])
            tgt = seq[k] if k < len(seq) else 0
            if muscle in secondary:
                tgt = min(tgt, SECONDARY_SESSION_CAP)
            session_targets[muscle] = tgt
            exposure[muscle] = k + 1

        # 热身预算：本节课涉及的复合大肌群数量（上限封顶）
        n_big = sum(1 for m in target_muscles if m in BIG_MUSCLES)
        warmup_sec = min(WARMUP_CAP_SEC, WARMUP_SEC_PER_BIG_MUSCLE * min(n_big, 4))
        work_budget_sec = max(8 * 60, total_budget_sec - warmup_sec)

        exercises = library.query(
            exercise_type=session_type,
            equipment=profile.equipment,
            injuries=profile.injuries,
            level=level,
        )
        exercises.sort(key=lambda e: (not e.compound, e.skill_level != "beginner"))

        session_exercises: list[ExerciseEntry] = []
        used_ids: set[str] = set()
        state = {"order": 1, "used_sec": 0}
        delivered_session: dict[str, int] = {}

        def _pool(muscle: str) -> list:
            p = [e for e in exercises if muscle in e.primary_muscles and e.id not in used_ids]
            if not p:
                p = [e for e in exercises if muscle in e.secondary_muscles and e.id not in used_ids]
            return p

        def _try_add(muscle: str, want: int) -> int:
            if want < 2:
                return 0
            pool = _pool(muscle)
            if not pool:
                return 0
            ex = pool[0]
            cost = _set_seconds(prescribed_rest, ex.compound)
            fit_sets = (work_budget_sec - state["used_sec"]) // cost
            if fit_sets < 2:
                return 0
            sets = min(want, sets_range[1], fit_sets)
            if sets < 2:
                return 0
            session_exercises.append(ExerciseEntry(
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
                order=state["order"],
                primary_muscles=ex.primary_muscles,
                compound=ex.compound,
                form_cues=ex.form_cues,
                target_muscle=muscle,
            ))
            used_ids.add(ex.id)
            state["order"] += 1
            state["used_sec"] += sets * cost
            delivered_session[muscle] = delivered_session.get(muscle, 0) + sets
            return sets

        # 第 1 遍（广度）：主肌群先各上 1 个动作，保证不被前面的肌群饿死
        for muscle in primary_muscles_today:
            tgt = session_targets.get(muscle, 0)
            if tgt >= 2:
                _try_add(muscle, min(tgt, sets_range[1]))

        # 第 2 遍（深度）：主肌群按 session 目标补足，单肌群最多 3 个动作
        for _ in range(2):
            progressed = False
            for muscle in primary_muscles_today:
                tgt = session_targets.get(muscle, 0)
                got = delivered_session.get(muscle, 0)
                if got == 0 or got >= tgt:
                    continue
                if sum(1 for e in session_exercises if e.target_muscle == muscle) >= 3:
                    continue
                if _try_add(muscle, tgt - got):
                    progressed = True
            if not progressed:
                break

        # 第 3 遍：次要肌群（如 upper 日的二头三头）只用余量补，封顶更低
        for muscle in secondary_muscles_today:
            tgt = session_targets.get(muscle, 0)
            if tgt >= 2:
                _try_add(muscle, tgt)

        session_exercises.sort(key=lambda e: e.order)
        used_sec = state["used_sec"]
        total_sets = sum(e.sets for e in session_exercises)
        if total_sets:
            est_min = _round((warmup_sec + used_sec) / 60)
            est_min = max(1, min(est_min, profile.minutes_per_session))
        else:
            est_min = profile.minutes_per_session
        sessions.append(SessionResult(
            day=day_name,
            type=session_type,
            duration_min=est_min,
            exercises=session_exercises,
            total_sets=total_sets,
        ))

    return sessions


def _recommend_capacity(profile: UserProfile, coverage_pct: int) -> dict:
    """B 方案软提示：容量为锚，反推要完整兑现目标训练量需要的时间/频率。

    不强制、不拦截；只在 coverage 明显不足时给出可选建议。
    """
    if coverage_pct >= 90:
        return {}
    ratio = 100 / max(coverage_pct, 1)
    rec_minutes = min(120, _round(profile.minutes_per_session * ratio / 5) * 5)
    rec_days = min(6, (profile.days_per_week or 3) + 1)
    options = []
    if rec_minutes > profile.minutes_per_session:
        options.append(f"每节练到约 {rec_minutes} 分钟")
    if rec_days > profile.days_per_week:
        options.append(f"训练日加到 {rec_days} 天")
    if not options:
        return {}
    return {
        "coverage_pct": coverage_pct,
        "suggestion": "，或".join(options),
        "text": (
            f"按你选的目标训练量，当前时间/频率约能兑现 {coverage_pct}%。"
            f"想完整拿到：{'，或'.join(options)}。（可选，不影响现在开练）"
        ),
    }


def analyze_volume(
    profile: UserProfile,
    split: SplitResult,
    sessions: list[SessionResult],
) -> dict:
    """诚实层：对比周目标 vs 实际排出的容量，给出差额、覆盖率与补齐建议。

    返回 {target, delivered, frequency, coverage_pct, notes, recommendation}。
    """
    level = profile.level
    weekly_target = weekly_volume_for(level, profile.goal)
    frequency = _actual_muscle_frequency(split.weekly_schedule)
    primary_frequency = _actual_muscle_frequency(split.weekly_schedule, primary_only=True)

    # 按「动作被排进来时对应的配额肌群」计数，不用 primary_muscles，
    # 避免复合动作的多肌群标签把 delivered 灌水。
    delivered: dict[str, int] = {m: 0 for m in weekly_target}
    for s in sessions:
        for ex in s.exercises:
            m = ex.target_muscle
            if m in delivered:
                delivered[m] += ex.sets

    indirect: list[str] = []           # 分肢结构上就不单独练的
    low_freq_short: list[str] = []      # 每周只练 ≤1 次导致的欠量
    time_short: list[str] = []          # 频率够、时间不够导致的欠量
    covered_target = 0
    covered_delivered = 0
    for muscle, target in weekly_target.items():
        got = delivered.get(muscle, 0)
        freq = frequency.get(muscle, 0)
        pfreq = primary_frequency.get(muscle, 0)
        cn = _MUSCLE_CN.get(muscle, muscle)
        # 分肢结构上不单独练（freq 0），或本周只以「次要肌群」身份出现（pfreq 0）：
        # 靠复合动作间接带到，不计入需要「加时间」的欠量。
        if freq == 0 or pfreq == 0:
            indirect.append(cn)
            continue
        covered_target += target
        covered_delivered += min(got, target)
        if target - got >= 3:
            (low_freq_short if pfreq <= 1 else time_short).append(cn)

    coverage_pct = _round(100 * covered_delivered / covered_target) if covered_target else 100

    notes: list[str] = []
    if low_freq_short:
        notes.append(
            f"{'/'.join(low_freq_short)}：当前分肢这些肌群每周只练到 1 次，"
            f"周训练量只能到目标的约 {coverage_pct}%。想显著提升：换 4+ 天分肢，或全身 3 天。"
        )
    if time_short:
        if len(time_short) >= 3:
            notes.append(
                f"课时不足以塞下目标训练量：{'/'.join(time_short)} 等每周偏少（整体约 {coverage_pct}%）。"
                f"每节 +10 分钟 或 +1 训练日可补齐。"
            )
        else:
            for cn in time_short:
                notes.append(f"{cn}：本周训练量略欠，每节 +10 分钟 或 +1 训练日可补。")
    if indirect:
        notes.append(
            f"{'/'.join(indirect)}：当前分肢不单独安排，靠复合动作间接带到；"
            f"想直接练需加训练日或换分肢。"
        )

    recommendation = _recommend_capacity(profile, coverage_pct)
    if recommendation and recommendation.get("text"):
        notes.append(recommendation["text"])

    return {
        "target": weekly_target,
        "delivered": delivered,
        "frequency": frequency,
        "coverage_pct": coverage_pct,
        "notes": notes,
        "recommendation": recommendation,
    }
