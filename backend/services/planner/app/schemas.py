from typing import Optional

from pydantic import BaseModel, Field


class SubmitProfile(BaseModel):
    sex: str = Field(pattern="^[MmFf]$")
    age: int = Field(ge=14, le=90)
    bmi: float = Field(ge=10, le=60)
    level: str
    goal: str
    equipment: list[str] = []


class SubmitMetrics(BaseModel):
    bench_e1rm_pct: Optional[float] = None
    squat_e1rm_pct: Optional[float] = None
    hinge_e1rm_pct: Optional[float] = None
    row_e1rm_pct: Optional[float] = None
    perf_median_pct: Optional[float] = None
    bodyweight_pct: Optional[float] = None
    adherence_pct: Optional[float] = None
    completed_cycles: Optional[int] = None


class SubmitPayload(BaseModel):
    device_id: str = Field(min_length=6, max_length=200)
    weeks_elapsed: float = Field(ge=0, le=520)
    planner_version: str = ""
    profile: SubmitProfile
    metrics: SubmitMetrics


class SubmitResponse(BaseModel):
    ok: bool = True
    cohort_key: str


class MetricStatsOut(BaseModel):
    n: int
    p25: float
    p50: float
    p75: float


class BenchmarkResponse(BaseModel):
    available: bool
    cohort_key: str
    cohort_size: int = 0
    widened: bool = False
    metrics: dict[str, MetricStatsOut] = {}
    reason: Optional[str] = None
