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
from .load_planner import build_one_rm_map, suggest_load


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

# 最低有效量（MEV，每肌群每周组数）：低于这个才算「没练够」。
# 只要每个肌群 ≥ MEV，计划就是科学完整的——一定能长肌肉（RP 容量地标）。
MEV_WEEKLY = {
    "chest": 8, "back": 10, "quads": 8, "hamstrings": 6, "shoulders": 8,
    "biceps": 6, "triceps": 6, "calves": 6, "core": 4,
}


def weekly_volume_for(level: str, goal: str, cycle_offset: int = 0) -> dict[str, int]:
    """按 level + goal 返回「最优训练量」(MAV)。

    cycle_offset：check-in 产出的中周期档位。+1 每档 ≈ +8% 往 MRV 推，
    -1 下调；夹在 [0.8×, 1.25×MAV]（≈ MRV）。
    """
    base = _BASE_WEEKLY_VOLUME.get(level, _BASE_WEEKLY_VOLUME["beginner"])
    scale = GOAL_VOLUME_SCALE.get(goal, 1.0)
    off = max(0.8, min(1.25, 1.0 + 0.08 * cycle_offset))
    return {m: max(2, _round(v * scale * off)) for m, v in base.items()}

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
    "hypertrophy":     {"load_pct": "65-80% 1RM", "load_pct_mid": 0.72, "reps": "8-12", "sets_range": (3, 4), "rest_sec": 90,  "rpe": 7.5, "tempo": "3-1-2-0", "rir": "1-3"},
    "strength":        {"load_pct": "≥80% 1RM",   "load_pct_mid": 0.85, "reps": "3-6",  "sets_range": (3, 5), "rest_sec": 150, "rpe": 8.0, "tempo": "受控",   "rir": "1-2"},
    "fat_loss":        {"load_pct": "60-75% 1RM", "load_pct_mid": 0.68, "reps": "10-15","sets_range": (3, 4), "rest_sec": 45,  "rpe": 7.0, "tempo": "3-1-2-0", "rir": "2-3"},
    "recomposition":   {"load_pct": "65-80% 1RM", "load_pct_mid": 0.72, "reps": "8-12", "sets_range": (3, 4), "rest_sec": 90,  "rpe": 7.5, "tempo": "3-1-2-0", "rir": "1-3"},
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

# 负重器械：拥有其一即视为"有器械"，纯自重动作在选池里降权
_LOADED_EQUIPMENT = frozenset(
    {"barbell", "dumbbell", "cable", "machine", "kettlebell", "trap_bar"}
)

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
    load_kg: float | None = None  # 有起始 1RM 时算出的建议重量；否则 None（首周找）

    def to_dict(self) -> dict:
        return {
            "name": self.name,
            "name_en": self.name_en,
            "exercise_id": self.exercise_id,
            "sets": self.sets,
            "reps": self.reps,
            "load": self.load,
            "load_kg": self.load_kg,
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
    """把周目标铺成每次暴露的组数序列，前重后轻，各次封顶到 cap，每次 ≥2 组。

    周目标小的时候，宁可少练几次、每次 ≥2 组，也不排「1 组」的无效暴露。
    例：14/2 → [7, 7]；10/3 → [4, 3, 3]；5/3 → [3, 2, 0]（腘绳每周练 2 次）。
    """
    freq = max(1, frequency)
    # 每次至少 2 组 → 有效暴露次数不超过 weekly // 2
    eff_freq = max(1, min(freq, weekly_target // 2))
    base, rem = divmod(weekly_target, eff_freq)
    seq = [min(cap, base + (1 if i < rem else 0)) for i in range(eff_freq)]
    return seq + [0] * (freq - eff_freq)


def build_sessions(
    profile: UserProfile,
    split: SplitResult,
    library: ExerciseLibrary,
) -> list[SessionResult]:
    """为每周每一天生成训练计划。"""
    level = profile.level
    goal = profile.goal
    vars_ = TRAINING_VARS.get(goal, TRAINING_VARS["hypertrophy"])
    weekly_volume = weekly_volume_for(level, goal, getattr(profile, "volume_cycle_offset", 0))
    exercise_offset = max(0, int(getattr(profile, "exercise_cycle_offset", 0) or 0))
    cap = MAX_SETS_PER_MUSCLE_SESSION.get(level, 8)
    frequency = _actual_muscle_frequency(split.weekly_schedule)
    prescribed_rest = vars_["rest_sec"]
    sets_range = vars_["sets_range"]
    one_rm_map = build_one_rm_map(getattr(profile, "strength_baseline", {}) or {})
    load_mid = vars_.get("load_pct_mid", 0.72)
    load_label = vars_["load_pct"]

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
        session_exposure: dict[str, int] = {}   # 本周该肌群第几次练（0 起）
        for muscle in target_muscles:
            if muscle not in weekly_volume:
                session_targets[muscle] = ACCESSORY_SETS.get(muscle, 0)
                continue
            k = exposure.get(muscle, 0)
            session_exposure[muscle] = k
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
        # 有负重器械的用户，纯自重动作排到后面（否则轮换会给他轮到俯卧撑）；
        # 只有弹力带 / 单杠 / 自重的居家用户不降权。
        has_loaded_gear = any(
            eq in _LOADED_EQUIPMENT for eq in profile.equipment
        )

        def _bodyweight_demoted(e) -> int:
            return 1 if (has_loaded_gear and e.equipment_required == ["bodyweight"]) else 0

        exercises.sort(key=lambda e: (
            _bodyweight_demoted(e), not e.compound, e.skill_level != "beginner"))

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
            # 锚定动作（该肌群本节课第一个动作）永远取 pool[0]，保证双进阶 / 1RM 追踪；
            # 之后的辅助动作按「跨中周期档位 + 本周该肌群第几次练」轮换到同肌群兄弟动作。
            if muscle in delivered_session:
                rot = exercise_offset + session_exposure.get(muscle, 0)
                ex = pool[rot % len(pool)]
            else:
                ex = pool[0]
            cost = _set_seconds(prescribed_rest, ex.compound)
            fit_sets = (work_budget_sec - state["used_sec"]) // cost
            if fit_sets < 2:
                return 0
            sets = min(want, sets_range[1], fit_sets)
            if sets < 2:
                return 0
            load_text, load_kg = suggest_load(ex, one_rm_map, load_mid, load_label)
            session_exercises.append(ExerciseEntry(
                name=ex.name,
                name_en=ex.name_en,
                exercise_id=ex.id,
                sets=sets,
                reps=vars_["reps"],
                load=load_text,
                load_kg=load_kg,
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
    """训练量对账（自适应目标）。

    目标不是一张固定表，而是「用户这个时长/天数排得满的量」，夹在 [MEV, MAV] 之间：
    只要每个肌群 ≥ MEV，计划就是科学完整的（一定长肌肉）→ coverage_pct 通常 100。
    另给 vs_optimal_pct：相当于最优训练量(MAV)的百分比，是「还能更好」的提示。

    返回 {target, optimal, delivered, frequency, coverage_pct, vs_optimal_pct,
          notes, recommendation}。
    """
    level = profile.level
    optimal = weekly_volume_for(level, profile.goal, getattr(profile, "volume_cycle_offset", 0))  # MAV 上限
    frequency = _actual_muscle_frequency(split.weekly_schedule)
    primary_frequency = _actual_muscle_frequency(split.weekly_schedule, primary_only=True)

    # 按「动作被排进来时对应的配额肌群」计数
    delivered: dict[str, int] = {m: 0 for m in optimal}
    for s in sessions:
        for ex in s.exercises:
            m = ex.target_muscle
            if m in delivered:
                delivered[m] += ex.sets

    target: dict[str, int] = {}          # 自适应目标（这份计划承诺的量）
    indirect: list[str] = []             # 分肢结构上不单独练的
    below_mev: list[str] = []            # 低于最低有效量（真·没练够）
    covered_t = covered_d = 0
    opt_t = opt_d = 0
    for muscle, hi in optimal.items():
        got = delivered.get(muscle, 0)
        # MEV 不会高于该目标下的 MAV（小肌群在减脂/力量缩放后 MAV 可能已很低）
        mev = min(MEV_WEEKLY.get(muscle, 6), hi)
        freq = frequency.get(muscle, 0)
        pfreq = primary_frequency.get(muscle, 0)
        cn = _MUSCLE_CN.get(muscle, muscle)
        # 自适应目标：排得满多少就定多少，但至少 MEV、至多 MAV
        tgt = max(mev, min(got, hi))
        target[muscle] = tgt
        if freq == 0 or pfreq == 0:
            indirect.append(cn)
            continue
        covered_t += tgt
        covered_d += min(got, tgt)
        opt_t += hi
        opt_d += min(got, hi)
        if got < mev:
            below_mev.append(cn)

    coverage_pct = _round(100 * covered_d / covered_t) if covered_t else 100
    vs_optimal_pct = _round(100 * opt_d / opt_t) if opt_t else 100

    notes: list[str] = []
    recommendation: dict = {}
    if below_mev:
        recommendation = _recommend_capacity(profile, coverage_pct)
        opts = recommendation.get("suggestion", "每次加长时间")
        notes.append(
            f"{'/'.join(below_mev)}：每周训练量还没到最低有效量。{opts} 可补上。"
        )
    elif vs_optimal_pct < 90:
        notes.append(
            f"训练量已达标（相当于最优的 {vs_optimal_pct}%）。想冲最大增速：每次加约 15 分钟。"
        )
    if indirect:
        notes.append(
            f"{'/'.join(indirect)}：当前分肢不单独安排，靠复合动作间接带到；"
            f"想直接练需加训练日或换分肢。"
        )

    return {
        "target": target,
        "optimal": optimal,
        "delivered": delivered,
        "frequency": frequency,
        "coverage_pct": coverage_pct,
        "vs_optimal_pct": vs_optimal_pct,
        "notes": notes,
        "recommendation": recommendation,
    }
