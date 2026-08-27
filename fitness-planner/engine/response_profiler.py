"""ResponseProfiler — 为后续宠物谱系积累训练响应，不做医学诊断。"""
from __future__ import annotations

from dataclasses import dataclass


@dataclass
class ResponseObservation:
    completed_cycles: int
    adherence_pct: float
    performance_improvement_pct: float | None = None
    weight_trend_pct: float | None = None
    waist_trend_pct: float | None = None
    recovery_score: float | None = None


@dataclass
class ResponseProfile:
    maturity: str
    training_style: str
    metabolism_response: str
    muscle_gain_response: str
    fat_loss_response: str
    confidence: str

    def to_dict(self) -> dict:
        return self.__dict__.copy()


def profile_response(observation: ResponseObservation) -> ResponseProfile:
    if observation.adherence_pct >= 85:
        training_style = "steady"
    elif observation.adherence_pct >= 60:
        training_style = "variable"
    else:
        training_style = "still_learning"

    if observation.completed_cycles < 2:
        return ResponseProfile(
            maturity="preliminary",
            training_style=training_style,
            metabolism_response="unknown",
            muscle_gain_response="unknown",
            fat_loss_response="unknown",
            confidence="low",
        )

    performance = observation.performance_improvement_pct
    muscle = "unknown" if performance is None else ("responsive" if performance >= 5 else "steady")
    body_data = observation.weight_trend_pct is not None or observation.waist_trend_pct is not None
    fat = "unknown"
    if body_data:
        improved = (observation.weight_trend_pct or 0) < 0 or (observation.waist_trend_pct or 0) < 0
        fat = "responsive" if improved else "steady"

    # 代谢响应至少需要多周期身体趋势；这里只给训练响应标签，不输出医学快慢代谢。
    metabolism = "observed" if body_data else "unknown"
    known_axes = sum(value != "unknown" for value in (muscle, fat, metabolism))
    return ResponseProfile(
        maturity="developing" if observation.completed_cycles < 3 else "established",
        training_style=training_style,
        metabolism_response=metabolism,
        muscle_gain_response=muscle,
        fat_loss_response=fat,
        confidence="medium" if known_axes >= 2 else "low",
    )
