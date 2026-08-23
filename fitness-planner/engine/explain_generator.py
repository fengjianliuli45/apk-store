"""ExplainGenerator — 解释层（模板模式，不调 LLM）。

将 JSON 计划转化为用户可读的自然语言解释。
"""
from __future__ import annotations

from .profile_validator import UserProfile
from .tdee_calculator import TDEEResult
from .macro_allocator import MacroResult
from .split_selector import SplitResult
from .progression_planner import ProgressionResult


def explain(
    profile: UserProfile,
    tdee: TDEEResult,
    macros: MacroResult,
    split: SplitResult,
    progression: ProgressionResult,
) -> str:
    """生成人类可读的计划解释。"""
    lines: list[str] = []

    # ── 概览 ─────────────────────────────────
    lines.append("=" * 60)
    lines.append("🏋️ 你的健身智能规划方案")
    lines.append("=" * 60)
    lines.append("")

    # ── 身体数据 ─────────────────────────────
    lines.append("📋 身体数据")
    lines.append(f"  性别: {profile.gender} | 年龄: {profile.age} | BMI: {profile.bmi}")
    if profile.body_fat_pct:
        lines.append(f"  体脂率: {profile.body_fat_pct}% → 使用 Katch-McArdle 公式")
    else:
        lines.append(f"  体脂率: 未提供 → 使用 Mifflin-St Jeor 公式")
    lines.append(f"  训练水平: {profile.level} | 目标: {profile.goal}")
    lines.append(f"  每周训练: {profile.days_per_week} 天 × {profile.minutes_per_session} 分钟")
    lines.append("")

    # ── 热量 ─────────────────────────────────
    lines.append("🔥 每日热量")
    lines.append(f"  BMR: {tdee.bmr:.0f} kcal（{tdee.formula_used}）")
    lines.append(f"  TDEE: {tdee.tdee:.0f} kcal（活动水平: {tdee.activity_level}, 乘数: {tdee.activity_multiplier}）")
    surplus_text = {
        "hypertrophy": f"增肌盈余 +{macros.surplus_kcal} kcal",
        "fat_loss": f"减脂缺口 {macros.surplus_kcal} kcal",
        "strength": f"微盈余 +{macros.surplus_kcal} kcal",
        "recomposition": "维持热量",
    }.get(profile.goal, "维持热量")
    lines.append(f"  方向: {surplus_text}")
    lines.append(f"  目标每日热量: {macros.daily_targets['kcal']} kcal")
    lines.append("")

    # ── 营养素 ───────────────────────────────
    lines.append("🥩 三大营养素")
    dt = macros.daily_targets
    lines.append(f"  蛋白质: {dt['protein_g']}g ({macros.per_kg['protein']}g/kg)")
    pk = macros.per_kg['protein']
    if profile.goal == "hypertrophy":
        lines.append(f"    → 根据 Morton 2018（PMID 28698222）对 49 项研究、1863 名参与者的荟萃分析，"
                      f"蛋白质摄入 {pk}g/kg 有助于最大化增肌效果。")
    elif profile.goal == "fat_loss":
        lines.append(f"    → 根据 Longland 2016（PMID 26817506），热量缺口期 {pk}g/kg 蛋白质"
                      f"可有效保护瘦体重。")
    lines.append(f"  脂肪: {dt['fat_g']}g ({macros.per_kg['fat']}g/kg)")
    lines.append(f"  碳水: {dt['carbs_g']}g ({macros.per_kg['carbs']}g/kg)")
    lines.append("")

    # ── 训练分肢 ─────────────────────────────
    lines.append("💪 训练分肢")
    lines.append(f"  方案: {split.split_name}")
    for day in split.weekly_schedule:
        icon = "🏠" if day["type"] == "rest" else "🏋️"
        lines.append(f"  {day['day']}: {icon} {day['type']}")
    if split.warnings:
        for w in split.warnings:
            lines.append(f"  ⚠️ {w}")
    lines.append("")

    # ── 渐进 ─────────────────────────────────
    lines.append("📈 渐进超负荷")
    lines.append(f"  策略: {progression.strategy}")
    lines.append(f"  频率: {progression.progression_freq}")
    lines.append(f"  上肢加重: +{progression.increment_upper_kg}kg/次")
    lines.append(f"  下肢加重: +{progression.increment_lower_kg}kg/次")
    lines.append(f"  双进阶: {progression.double_progression}")
    lines.append(f"  下次检查: 第 {progression.next_check_week} 周")
    if progression.deload_note:
        lines.append(f"  减载: {progression.deload_note}")
    lines.append("")

    # ── 重评估触发 ───────────────────────────
    lines.append("🔄 重评估触发条件")
    for trigger in progression.triggers:
        week_info = f"（第{trigger.week}周）" if trigger.week else ""
        lines.append(f"  • {trigger.condition}{week_info} → {trigger.action}")
    lines.append("")

    # ── 论文依据 ─────────────────────────────
    lines.append("📚 论文依据")
    lines.append(f"  本方案基于 {len(EVIDENCE_PMIDS)} 篇同行评议论文，核心参考包括：")
    for pmid, desc in EVIDENCE_DESC.items():
        lines.append(f"  • PMID {pmid}: {desc}")
    lines.append("")

    lines.append("=" * 60)

    return "\n".join(lines)


EVIDENCE_PMIDS = [
    "41843416", "28834797", "27102172", "27433992",
    "28698222", "29414855", "37432300", "26817506",
]

EVIDENCE_DESC = {
    "41843416": "ACSM 2026 立场——全部训练变量",
    "28834797": "Schoenfeld 2017——低负荷 vs 高负荷等效",
    "27102172": "Schoenfeld 2016——每肌群 2 次/周最优",
    "27433992": "Schoenfeld 2017——组数剂量反应",
    "28698222": "Morton 2018——蛋白质补充→增肌荟萃分析",
    "29414855": "Stokes 2018——MPS 剂量反应",
    "37432300": "Burke 2023——肌酸→增肌荟萃分析",
    "26817506": "Longland 2016——缺口期高蛋白保肌",
}
