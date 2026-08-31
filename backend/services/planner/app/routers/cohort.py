import hashlib
import os

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import cohort as C
from ..config import get_settings
from ..db import get_db
from ..models import CohortSubmission
from ..schemas import BenchmarkResponse, SubmitPayload, SubmitResponse

router = APIRouter(prefix="/v1/cohort", tags=["cohort"])

_SALT = os.environ.get("PLANNER_DEVICE_SALT", "stopwatch-dev-salt")


def _hash_device(device_id: str) -> str:
    return hashlib.sha256((device_id + _SALT).encode()).hexdigest()


@router.post("/submit", response_model=SubmitResponse)
def submit(payload: SubmitPayload, db: Session = Depends(get_db)) -> SubmitResponse:
    p = payload.profile
    key = C.build_cohort_key(
        sex=p.sex, age=p.age, bmi=p.bmi, level=p.level, goal=p.goal,
        equipment=p.equipment, weeks_elapsed=payload.weeks_elapsed,
    )
    dh = _hash_device(payload.device_id)
    m = payload.metrics

    settings = get_settings()
    row = None
    if settings.dedup_by_device:
        row = db.execute(
            select(CohortSubmission).where(
                CohortSubmission.device_hash == dh,
                CohortSubmission.weeks_band == key.weeks_band,
            )
        ).scalar_one_or_none()

    fields = dict(
        device_hash=dh, planner_version=payload.planner_version,
        sex=key.sex, age_band=key.age_band, bmi_band=key.bmi_band,
        level=key.level, goal=key.goal, equipment_tier=key.equipment_tier,
        weeks_band=key.weeks_band, weeks_elapsed=payload.weeks_elapsed,
        **m.model_dump(),
    )
    if row is None:
        db.add(CohortSubmission(**fields))
    else:
        for k, v in fields.items():
            setattr(row, k, v)
    db.commit()
    return SubmitResponse(cohort_key=key.as_str())


@router.get("/benchmark", response_model=BenchmarkResponse)
def benchmark(
    db: Session = Depends(get_db),
    sex: str = Query(pattern="^[MmFf]$"),
    age: int = Query(ge=14, le=90),
    bmi: float = Query(ge=10, le=60),
    level: str = Query(),
    goal: str = Query(),
    weeks_elapsed: float = Query(ge=0, le=520),
    equipment: list[str] = Query(default=[]),
) -> BenchmarkResponse:
    base_key = C.build_cohort_key(
        sex=sex, age=age, bmi=bmi, level=level, goal=goal,
        equipment=equipment, weeks_elapsed=weeks_elapsed,
    )

    for i, key in enumerate(C.widen_steps(base_key)):
        rows = db.execute(_cohort_query(key)).scalars().all()
        if len(rows) < C.MIN_COHORT:
            continue
        metrics: dict = {}
        for metric in C.METRICS:
            vals = [getattr(r, metric) for r in rows]
            s = C.metric_stats(vals)
            if s is not None:
                metrics[metric] = s.to_dict()
        if not metrics:
            continue
        return BenchmarkResponse(
            available=True,
            cohort_key=key.as_str(),
            cohort_size=len(rows),
            widened=i > 0,
            metrics=metrics,
        )

    return BenchmarkResponse(
        available=False, cohort_key=base_key.as_str(),
        reason=f"同类样本不足 {C.MIN_COHORT} 人，暂不对比",
    )


def _cohort_query(key: C.CohortKey):
    q = select(CohortSubmission)
    for col, val in key.as_filter().items():
        q = q.where(getattr(CohortSubmission, col) == val)
    return q
