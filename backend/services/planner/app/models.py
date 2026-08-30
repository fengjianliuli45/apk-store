import uuid
from datetime import datetime, timezone

from sqlalchemy import Float, Index, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from .db import Base


def _uid() -> str:
    return str(uuid.uuid4())


def _now() -> datetime:
    return datetime.now(timezone.utc)


class CohortSubmission(Base):
    """一条匿名化的 check-in 结果。没有任何可识别个人的字段。

    device_hash = sha256(device_id + server_salt)，只用于「同一设备同一阶段」去重，
    不可反推设备。raw_payload 不存，指标已在客户端算好。
    """
    __tablename__ = "cohort_submissions"
    __table_args__ = (
        UniqueConstraint("device_hash", "weeks_band", name="uq_device_weeksband"),
        Index("ix_cohort_lookup", "sex", "level", "goal", "weeks_band",
              "age_band", "bmi_band", "equipment_tier"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uid)
    device_hash: Mapped[str] = mapped_column(String(64), index=True)
    submitted_at: Mapped[datetime] = mapped_column(default=_now, onupdate=_now)
    planner_version: Mapped[str] = mapped_column(String(16), default="")

    # ── cohort 维度 ──
    sex: Mapped[str] = mapped_column(String(1))
    age_band: Mapped[str] = mapped_column(String(8))
    bmi_band: Mapped[str] = mapped_column(String(10))
    level: Mapped[str] = mapped_column(String(16))
    goal: Mapped[str] = mapped_column(String(20))
    equipment_tier: Mapped[str] = mapped_column(String(8))
    weeks_band: Mapped[str] = mapped_column(String(8))
    weeks_elapsed: Mapped[float] = mapped_column(Float, default=0.0)

    # ── 结果指标（可空）──
    bench_e1rm_pct: Mapped[float | None] = mapped_column(Float, nullable=True)
    squat_e1rm_pct: Mapped[float | None] = mapped_column(Float, nullable=True)
    hinge_e1rm_pct: Mapped[float | None] = mapped_column(Float, nullable=True)
    row_e1rm_pct: Mapped[float | None] = mapped_column(Float, nullable=True)
    perf_median_pct: Mapped[float | None] = mapped_column(Float, nullable=True)
    bodyweight_pct: Mapped[float | None] = mapped_column(Float, nullable=True)
    adherence_pct: Mapped[float | None] = mapped_column(Float, nullable=True)
    completed_cycles: Mapped[int | None] = mapped_column(Integer, nullable=True)
