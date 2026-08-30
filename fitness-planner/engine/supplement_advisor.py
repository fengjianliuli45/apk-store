"""SupplementAdvisor — 补剂推荐。

根据用户补剂意愿和目标，输出补剂推荐。
"""
from __future__ import annotations

from dataclasses import dataclass
from .profile_validator import UserProfile
from .macro_allocator import MacroResult
from .food_db import normalize_restrictions


@dataclass
class Supplement:
    name: str
    name_en: str
    dose: str
    condition: str
    note: str
    pmid: str | None = None

    def to_dict(self) -> dict:
        return {
            "name": self.name,
            "name_en": self.name_en,
            "dose": self.dose,
            "condition": self.condition,
            "note": self.note,
            "pmid": self.pmid,
        }


@dataclass
class SupplementResult:
    supplements: list[Supplement]

    def to_dict(self) -> dict:
        return {"supplements": [s.to_dict() for s in self.supplements]}


def advise(profile: UserProfile, macros: MacroResult) -> SupplementResult:
    """根据用户情况生成补剂建议。"""
    results: list[Supplement] = []

    # 肌酸：只要不明确拒绝
    user_supps = [s.lower() for s in profile.supplements]
    explicitly_rejected = any("no" in s or "不" in s or "拒绝" in s for s in user_supps)

    if not explicitly_rejected:
        results.append(Supplement(
            name="肌酸",
            name_en="Creatine Monohydrate",
            dose="5g/日",
            condition="默认推荐（除非明确拒绝）",
            note="持续服用，无需 loading，无需停用期。2-3 周可达饱和。",
            pmid="37432300",
        ))

    # 乳清蛋白：饮食蛋白不足
    daily_protein = macros.daily_targets["protein_g"]
    # 假设普通人每日饮食蛋白约 1.0g/kg
    diet_protein_est = profile.weight_kg * 1.0
    if daily_protein > diet_protein_est:
        deficit = round(daily_protein - diet_protein_est, 1)
        results.append(Supplement(
            name="乳清蛋白粉",
            name_en="Whey Protein",
            dose=f"补足差额约 {deficit}g 蛋白",
            condition="饮食蛋白不足时",
            note="优先从食物摄取，不足部分用蛋白粉补足。",
            pmid="28698222",
        ))

    # 维生素 D：食堂或室内
    if profile.cooking_access == "canteen" or profile.cooking_access == "none":
        results.append(Supplement(
            name="维生素 D3",
            name_en="Vitamin D3",
            dose="2000 IU/日",
            condition="食堂就餐或室内生活方式",
            note="一般健康建议，尤其日晒不足时。",
            pmid=None,
        ))

    # 素食相关：Omega-3；纯素再加 B12（必补）+ 铁
    restrictions = normalize_restrictions(profile.dietary_restrictions)
    if "vegetarian" in restrictions:
        results.append(Supplement(
            name="鱼油 / 藻油",
            name_en="Fish Oil / Algae Oil",
            dose="1-2g EPA+DHA/日",
            condition="素食且无鱼摄入",
            note="补充 Omega-3 脂肪酸，藻油为纯素替代。",
            pmid=None,
        ))
    if "vegan" in restrictions:
        results.append(Supplement(
            name="维生素 B12",
            name_en="Vitamin B12 (cyanocobalamin)",
            dose="约 250 µg/日 或 2000 µg/周",
            condition="纯素（膳食几乎无 B12 来源，必补）",
            note="缺乏会致贫血与不可逆神经损伤，纯素人群务必规律补充。",
            pmid=None,
        ))
        results.append(Supplement(
            name="铁（按需）",
            name_en="Iron",
            dose="按血清铁蛋白结果补，不盲补",
            condition="纯素 + 化验提示缺铁",
            note="植物性非血红素铁吸收率低；搭配维C食物、避开浓茶咖啡。",
            pmid=None,
        ))

    return SupplementResult(supplements=results)
