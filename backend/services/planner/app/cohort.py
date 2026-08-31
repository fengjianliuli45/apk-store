"""同类对标的纯逻辑：cohort 分桶、百分位、k-匿名放宽、对比判定。

这里不碰 DB / HTTP，方便单测和跨端对齐。
"""
from __future__ import annotations

from dataclasses import dataclass

# ── cohort 键 ────────────────────────────────────────────────

SEXES = ("M", "F")
LEVELS = ("beginner", "intermediate", "advanced")
GOALS = ("hypertrophy", "fat_loss", "strength", "recomposition")
EQUIPMENT_TIERS = ("home", "gym")

_LOADED_EQUIPMENT = frozenset(
    {"barbell", "dumbbell", "cable", "machine", "kettlebell", "trap_bar"}
)

# 上报的结果指标（% 除非特别说明）
METRICS = (
    "bench_e1rm_pct", "squat_e1rm_pct", "hinge_e1rm_pct", "row_e1rm_pct",
    "perf_median_pct", "bodyweight_pct", "adherence_pct", "completed_cycles",
)

MIN_COHORT = 20   # 桶里少于这个人数不对外（k-匿名）


def age_band(age: int) -> str:
    a = int(age)
    if a < 20:
        return "16-19"
    if a < 40:
        lo = (a // 5) * 5
        return f"{lo}-{lo + 4}"
    if a < 50:
        return "40-49"
    return "50+"


def bmi_band(bmi: float) -> str:
    b = float(bmi)
    if b < 18.5:
        return "<18.5"
    if b < 22:
        return "18.5-22"
    if b < 25:
        return "22-25"
    if b < 28:
        return "25-28"
    return "28+"


def equipment_tier(equipment: list[str]) -> str:
    return "gym" if any(e in _LOADED_EQUIPMENT for e in (equipment or [])) else "home"


def weeks_band(weeks_elapsed: float) -> str:
    w = float(weeks_elapsed or 0)
    if w < 6:
        return "4w"
    if w < 10:
        return "8w"
    if w < 14:
        return "12w"
    return "16w+"


@dataclass(frozen=True)
class CohortKey:
    sex: str
    age_band: str
    bmi_band: str
    level: str
    goal: str
    equipment_tier: str
    weeks_band: str

    def as_str(self) -> str:
        return "|".join(v if v is not None else "*" for v in (
            self.sex, self.age_band, self.bmi_band, self.level,
            self.goal, self.equipment_tier, self.weeks_band))

    def as_filter(self) -> dict:
        """给 DB 查询用的等值条件（None = 不约束该维度）。"""
        return {k: v for k, v in self.__dict__.items() if v is not None}


def build_cohort_key(*, sex: str, age: int, bmi: float, level: str, goal: str,
                     equipment: list[str], weeks_elapsed: float) -> CohortKey:
    return CohortKey(
        sex=sex.upper(),
        age_band=age_band(age),
        bmi_band=bmi_band(bmi),
        level=level.lower(),
        goal=goal.lower(),
        equipment_tier=equipment_tier(equipment),
        weeks_band=weeks_band(weeks_elapsed),
    )


# 桶太小时，按这个顺序逐步放宽（把该维度设成 None = 不约束）
_WIDEN_ORDER = ("bmi_band", "age_band", "equipment_tier")


def widen_steps(key: CohortKey):
    """产出「原桶 → 逐步放宽」的 CohortKey 序列。"""
    d = dict(key.__dict__)
    yield CohortKey(**d)
    for dim in _WIDEN_ORDER:
        d[dim] = None
        yield CohortKey(**d)


# ── 百分位（纯 Python，linear 插值，对齐 numpy.percentile 默认）──

def percentile(sorted_vals: list[float], q: float) -> float:
    n = len(sorted_vals)
    if n == 0:
        raise ValueError("empty")
    if n == 1:
        return float(sorted_vals[0])
    pos = q / 100 * (n - 1)
    lo = int(pos)
    frac = pos - lo
    if lo + 1 >= n:
        return float(sorted_vals[-1])
    return float(sorted_vals[lo] + frac * (sorted_vals[lo + 1] - sorted_vals[lo]))


@dataclass
class MetricStats:
    n: int
    p25: float
    p50: float
    p75: float

    def to_dict(self) -> dict:
        return {"n": self.n, "p25": round(self.p25, 2),
                "p50": round(self.p50, 2), "p75": round(self.p75, 2)}


def metric_stats(values: list[float]) -> MetricStats | None:
    vals = sorted(float(v) for v in values if v is not None)
    if len(vals) < MIN_COHORT:
        return None
    return MetricStats(
        n=len(vals),
        p25=percentile(vals, 25),
        p50=percentile(vals, 50),
        p75=percentile(vals, 75),
    )


# ── 对比判定（B 方案软提示的核心）─────────────────────────────

_BANDS = (
    ("ahead", "领先（超过同类 75%）"),
    ("above", "正常偏上"),
    ("normal", "正常范围"),
    ("behind", "偏慢，可以再逼一点 / 检查恢复与饮食"),
)


def cohort_compare(user_value: float, stats: dict) -> dict:
    """user_value 相对 {p25,p50,p75} 落在哪一档。

    返回 {band, label, vs_median_pct}。
    band ∈ ahead|above|normal|behind
    """
    p25, p50, p75 = stats["p25"], stats["p50"], stats["p75"]
    v = float(user_value)
    if v >= p75:
        band, label = _BANDS[0]
    elif v >= p50:
        band, label = _BANDS[1]
    elif v >= p25:
        band, label = _BANDS[2]
    else:
        band, label = _BANDS[3]
    vs_median = None
    if p50 not in (0, None):
        vs_median = round((v - p50) / abs(p50) * 100, 1)
    return {"band": band, "label": label, "vs_median_pct": vs_median}
