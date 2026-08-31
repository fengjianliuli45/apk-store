"""同类对标的客户端侧小工具：把 benchmark 结果翻成软提示（B 方案）。

引擎离线，不发网络请求。App 拿计划 / check-in 后：
  1. 用 cohort_query_params() 组 benchmark 查询
  2. 打到 planner 服务的 GET /v1/cohort/benchmark
  3. 用 cohort_compare() 把「你的值 vs 同类 p25/p50/p75」变成一句话
"""
from __future__ import annotations

_LOADED_EQUIPMENT = frozenset(
    {"barbell", "dumbbell", "cable", "machine", "kettlebell", "trap_bar"}
)

_BANDS = {
    "ahead": "领先（超过同类 75%）",
    "above": "正常偏上",
    "normal": "正常范围",
    "behind": "偏慢，可以再逼一点 / 检查恢复与饮食",
}


def cohort_query_params(plan: dict, weeks_elapsed: float) -> dict:
    """从计划 JSON 组 benchmark 查询参数。"""
    p = plan.get("profile", {})
    return {
        "sex": p.get("gender", "M"),
        "age": int(p.get("age", 25)),
        "bmi": float(p.get("bmi") or 22.0),
        "level": p.get("level", "beginner"),
        "goal": p.get("goal", "hypertrophy"),
        "weeks_elapsed": float(weeks_elapsed),
        "equipment": list(p.get("equipment", [])),
    }


def cohort_compare(user_value: float, stats: dict) -> dict:
    """user_value 相对 {p25,p50,p75} 落在哪一档。

    返回 {band, label, vs_median_pct}；band ∈ ahead|above|normal|behind。
    """
    p25 = float(stats["p25"])
    p50 = float(stats["p50"])
    p75 = float(stats["p75"])
    v = float(user_value)
    if v >= p75:
        band = "ahead"
    elif v >= p50:
        band = "above"
    elif v >= p25:
        band = "normal"
    else:
        band = "behind"
    vs_median = None
    if p50 != 0:
        vs_median = round((v - p50) / abs(p50) * 100, 1)
    return {"band": band, "label": _BANDS[band], "vs_median_pct": vs_median}


def cohort_hint(metric_cn: str, user_value: float, stats: dict) -> str:
    """一句话软提示，比如「卧推进步 +8%：同类 8 周中位数 +12%，你在正常范围。」"""
    c = cohort_compare(user_value, stats)
    return (f"{metric_cn} {user_value:+.0f}%：同类中位数 {stats['p50']:+.0f}%"
            f"（p25~p75 {stats['p25']:+.0f}%~{stats['p75']:+.0f}%），{c['label']}。")
