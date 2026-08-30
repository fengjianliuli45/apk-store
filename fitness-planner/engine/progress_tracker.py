"""ProgressTracker — 训练日志 → 阶段评估证据（缺的中间层）。

把 App 记录的「实际做了什么」聚合成 stage_assessor / response_profiler 要的输入。

日志契约：
    LoggedSet     = {reps, weight_kg?, rpe?, rir?}
    LoggedExercise= {exercise_id, planned_sets, sets: [LoggedSet]}
    LoggedSession = {date "YYYY-MM-DD", plan_day, session_type, planned_sets,
                     exercises: [LoggedExercise], aborted, pain_flag}
    BodyEntry     = {date "YYYY-MM-DD", weight_kg, waist_cm?}
"""
from __future__ import annotations

from datetime import date
from statistics import median

from .stage_assessor import StageEvidence
from .response_profiler import ResponseObservation


_RIR_TRUSTWORTHY = 3   # RIR > 3 的组离力竭太远，不能用来估 1RM


def epley_e1rm(weight_kg: float, reps: int, rir: int | None) -> float | None:
    """Epley + RIR 修正。RIR 缺失按 0（练到力竭）；RIR > 3 视为不可信，返回 None。"""
    r = rir if rir is not None else 0
    if r > _RIR_TRUSTWORTHY:
        return None
    eff = min(12, reps + r)
    return round(weight_kg * (1 + eff / 30), 1)


def _iso_week(d: str) -> tuple[int, int]:
    y, m, dd = (int(x) for x in d.split("-"))
    iso = date(y, m, dd).isocalendar()
    return (iso[0], iso[1])


def _completed_sets(sess: dict) -> int:
    return sum(len(ex.get("sets", [])) for ex in sess.get("exercises", []))


def _is_completed(sess: dict) -> bool:
    if sess.get("aborted"):
        return False
    planned = sess.get("planned_sets") or 0
    if planned <= 0:
        return _completed_sets(sess) > 0
    return _completed_sets(sess) / planned >= 0.5


def _baseline_ids(plan: dict) -> list[str]:
    return [b["exercise_id"] for b in plan.get("stage_goal", {}).get("baseline_lifts", [])]


def _lift_series(plan: dict, sessions: list[dict]) -> dict[str, list[dict]]:
    """每个基准动作按时间排的 [{date, best_e1rm, best_reps_at_load, top_load, all_top_range, all_below_bottom}]。"""
    reps_range = _plan_reps_range(plan)
    wanted = set(_baseline_ids(plan))
    series: dict[str, list[dict]] = {i: [] for i in wanted}
    for sess in sorted(sessions, key=lambda s: s.get("date", "")):
        if not _is_completed(sess):
            continue
        for ex in sess.get("exercises", []):
            eid = ex.get("exercise_id")
            if eid not in wanted:
                continue
            sets = ex.get("sets", [])
            e1rms = [
                epley_e1rm(s["weight_kg"], s["reps"], s.get("rir"))
                for s in sets
                if s.get("weight_kg") and s.get("reps")
            ]
            e1rms = [v for v in e1rms if v is not None]
            loads = [s["weight_kg"] for s in sets if s.get("weight_kg")]
            top_load = max(loads) if loads else None
            lo, hi = reps_range.get(eid, (6, 12))
            done_reps = [s["reps"] for s in sets if s.get("reps") is not None]
            entry = {
                "date": sess.get("date"),
                "best_e1rm": max(e1rms) if e1rms else None,
                "top_load": top_load,
                "best_reps_at_top": max(
                    (s["reps"] for s in sets if s.get("weight_kg") == top_load and s.get("reps")),
                    default=None,
                ),
                "all_top_range": bool(done_reps) and all(r >= hi for r in done_reps),
                "any_below_bottom": bool(done_reps) and any(r < lo for r in done_reps),
                "avg_rir": (
                    round(sum(s["rir"] for s in sets if s.get("rir") is not None)
                          / max(1, sum(1 for s in sets if s.get("rir") is not None)), 1)
                    if any(s.get("rir") is not None for s in sets) else None
                ),
            }
            series[eid].append(entry)
    return series


def _plan_reps_range(plan: dict) -> dict[str, tuple[int, int]]:
    out: dict[str, tuple[int, int]] = {}
    for s in plan.get("training", {}).get("schedule", []):
        for e in s.get("exercises", []):
            rr = str(e.get("reps", "")).replace("＋", "+")
            if "-" in rr:
                a, b = rr.split("-", 1)
                try:
                    out[e["exercise_id"]] = (int(a), int(b))
                except ValueError:
                    pass
    return out


def _performance_pct(series: dict[str, list[dict]]) -> tuple[float | None, int]:
    """各基准动作 e1RM 首末变化的中位数 %，以及有 ≥2.5% 提升的动作数。"""
    pcts: list[float] = []
    confirmations = 0
    for entries in series.values():
        pts = [e["best_e1rm"] for e in entries if e["best_e1rm"] is not None]
        if len(pts) < 2:
            continue
        change = (pts[-1] - pts[0]) / pts[0] * 100
        pcts.append(change)
        if change >= 2.5:
            confirmations += 1
    if not pcts:
        return None, 0
    return round(median(pcts), 1), confirmations


def _same_load_rep_gain(series: dict[str, list[dict]]) -> int:
    best = 0
    for entries in series.values():
        first = next((e for e in entries if e["top_load"] and e["best_reps_at_top"]), None)
        if not first:
            continue
        for e in reversed(entries):
            if e["top_load"] == first["top_load"] and e["best_reps_at_top"]:
                best = max(best, e["best_reps_at_top"] - first["best_reps_at_top"])
                break
    return best


def _fit_slope(pairs: list[tuple[float, float]]) -> float:
    """简单线性回归斜率（x=天序，y=值）。"""
    n = len(pairs)
    if n < 2:
        return 0.0
    sx = sum(p[0] for p in pairs); sy = sum(p[1] for p in pairs)
    sxx = sum(p[0] ** 2 for p in pairs); sxy = sum(p[0] * p[1] for p in pairs)
    denom = n * sxx - sx * sx
    return (n * sxy - sx * sy) / denom if denom else 0.0


def _body_trend(body: list[dict], goal: str) -> tuple[bool, float | None, float | None]:
    """(body_trend_target_met, weight_trend_pct, waist_trend_pct)。"""
    if len(body) < 3:
        return False, None, None
    b = sorted(body, key=lambda e: e.get("date", ""))
    d0 = _ordinal(b[0]["date"])
    span_days = _ordinal(b[-1]["date"]) - d0
    if span_days < 10:
        return False, None, None
    w = [(_ordinal(e["date"]) - d0, e["weight_kg"]) for e in b if e.get("weight_kg")]
    weight_pct = None
    if len(w) >= 2 and w[0][1]:
        weight_pct = round((w[-1][1] - w[0][1]) / w[0][1] * 100, 2)
    ws = [(_ordinal(e["date"]) - d0, e["waist_cm"]) for e in b if e.get("waist_cm")]
    waist_pct = None
    if len(ws) >= 2 and ws[0][1]:
        waist_pct = round((ws[-1][1] - ws[0][1]) / ws[0][1] * 100, 2)

    met = False
    if goal == "fat_loss":
        wt_ok = len(w) >= 3 and _fit_slope(w) < 0 and (weight_pct or 0) <= -0.5
        waist_ok = ws and ws[-1][1] is not None and ws[0][1] - ws[-1][1] >= 1.0
        met = bool(wt_ok or waist_ok)
    else:  # hypertrophy / recomposition / strength
        wt_ok = len(w) >= 3 and _fit_slope(w) >= 0 and (weight_pct or 0) >= 0.25
        waist_ok = waist_pct is not None and waist_pct <= 1.0
        met = bool(wt_ok and (waist_ok or waist_pct is None))
    return met, weight_pct, waist_pct


def _ordinal(d: str) -> int:
    y, m, dd = (int(x) for x in d.split("-"))
    return date(y, m, dd).toordinal()


def _pain_unresolved(sessions: list[dict]) -> bool:
    if not sessions:
        return False
    recent = sorted(sessions, key=lambda s: s.get("date", ""))[-3:]
    return any(s.get("pain_flag") for s in recent)


def aggregate_evidence(
    plan: dict, workout_log: list[dict], body_log: list[dict],
) -> StageEvidence:
    goal = plan.get("profile", {}).get("goal", "hypertrophy")
    completed = [s for s in workout_log if _is_completed(s)]
    active_weeks = len({_iso_week(s["date"]) for s in completed if s.get("date")})
    series = _lift_series(plan, workout_log)
    comparable = max((len([e for e in v if e["best_e1rm"] is not None]) for v in series.values()), default=0)
    perf_pct, confirmations = _performance_pct(series)
    rep_gain = _same_load_rep_gain(series)
    body_met, _, _ = _body_trend(body_log, goal)
    return StageEvidence(
        completed_sessions=len(completed),
        active_weeks=active_weeks,
        comparable_measurements=comparable,
        performance_improvement_pct=perf_pct,
        performance_confirmations=confirmations,
        same_load_rep_gain=rep_gain or None,
        body_trend_target_met=body_met,
        stable_positive_response=False,
        unresolved_safety_issue=_pain_unresolved(workout_log),
    )


def aggregate_observation(
    plan: dict, workout_log: list[dict], body_log: list[dict], completed_cycles: int,
) -> ResponseObservation:
    goal = plan.get("profile", {}).get("goal", "hypertrophy")
    planned = plan.get("stage_goal", {}).get("planned_sessions") or 1
    completed = [s for s in workout_log if _is_completed(s)]
    adherence = round(len(completed) / planned * 100, 1)
    series = _lift_series(plan, workout_log)
    perf_pct, _ = _performance_pct(series)
    _, weight_pct, waist_pct = _body_trend(body_log, goal)
    # 恢复分：实际 RIR 相对目标 RIR 2 的差（正 = 留力更多 = 更没压榨/更轻松）
    rir_gaps = [2 - e["avg_rir"] for v in series.values() for e in v if e["avg_rir"] is not None]
    recovery = round(sum(rir_gaps) / len(rir_gaps), 2) if rir_gaps else None
    return ResponseObservation(
        completed_cycles=completed_cycles,
        adherence_pct=adherence,
        performance_improvement_pct=perf_pct,
        weight_trend_pct=weight_pct,
        waist_trend_pct=waist_pct,
        recovery_score=recovery,
    )


def per_exercise_progress(plan: dict, workout_log: list[dict]) -> dict[str, dict]:
    """基准动作的进阶信号（给 check_in 做双进阶用）。"""
    series = _lift_series(plan, workout_log)
    out: dict[str, dict] = {}
    for eid, entries in series.items():
        if not entries:
            continue
        last3 = entries[-3:]
        out[eid] = {
            "instances": len(entries),
            "e1rm_change_pct": (
                round((entries[-1]["best_e1rm"] - entries[0]["best_e1rm"])
                      / entries[0]["best_e1rm"] * 100, 1)
                if len(entries) >= 2 and entries[0]["best_e1rm"] and entries[-1]["best_e1rm"]
                else None
            ),
            "last_all_top_range": bool(last3) and all(e["all_top_range"] for e in last3[-1:]),
            "consecutive_below_bottom": _trailing_true(entries, "any_below_bottom"),
            "avg_rir": last3[-1]["avg_rir"] if last3 else None,
            "e1rm_declining": (
                len(entries) >= 3
                and entries[-1]["best_e1rm"] is not None
                and entries[-2]["best_e1rm"] is not None
                and entries[-3]["best_e1rm"] is not None
                and entries[-1]["best_e1rm"] < entries[-2]["best_e1rm"] < entries[-3]["best_e1rm"]
            ),
        }
    return out


def _trailing_true(entries: list[dict], key: str) -> int:
    n = 0
    for e in reversed(entries):
        if e.get(key):
            n += 1
        else:
            break
    return n
