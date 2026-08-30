"""FoodDB — 小型食物库 + 把「每餐宏量目标」翻成具体吃法。

两套业界成熟做法都用上：
  1. 食物交换份（ADA / 美国营养学会，1950 起）：食物按宏量近似分组，同组互换。
     → FOODS 就是分组后的库；suggest_meal 按每餐目标克数换算份量。
  2. 手掌法（Precision Nutrition）：手掌=蛋白、一捧=碳水、拳头=蔬菜、拇指=脂肪，
     随体型缩放。研究：~80% 估算落在真实值 ±25% 内（PMC4976119）。
     → hand_portions 给不称重 / 在外吃的人。

每项只标两个客观属性，限制由此推导（避免逐项贴 tag 出错）：
  kind      : meat | seafood | egg | dairy | plant
  allergens : {gluten, nut, soy} 的子集（dairy / seafood 由 kind 推）
"""
from __future__ import annotations

# 手掌法：单位份的宏量近似（PN 标准值，克）
PALM_PROTEIN_G = 22     # 1 手掌 ≈ 22g 蛋白
CUPPED_CARB_G = 22      # 1 捧   ≈ 22g 碳水
THUMB_FAT_G = 11        # 1 拇指 ≈ 11g 脂肪

# 限制词归一化：用户输入 → 内部排除标记
_RESTRICTION_ALIASES = {
    "vegetarian": "vegetarian", "veg": "vegetarian", "素": "vegetarian", "蛋奶素": "vegetarian",
    "lacto_ovo": "vegetarian",
    "vegan": "vegan", "纯素": "vegan", "全素": "vegan",
    "halal": "halal", "清真": "halal",
    "no_pork": "no_pork", "不吃猪肉": "no_pork", "no-pork": "no_pork",
    "no_beef": "no_beef", "不吃牛肉": "no_beef", "no-beef": "no_beef",
    "lactose": "no_dairy", "lactose_intolerant": "no_dairy", "no_dairy": "no_dairy",
    "dairy_free": "no_dairy", "乳糖不耐": "no_dairy", "不吃乳制品": "no_dairy",
    "gluten": "no_gluten", "gluten_free": "no_gluten", "no_gluten": "no_gluten",
    "麸质过敏": "no_gluten", "无麸质": "no_gluten", "乳糜泻": "no_gluten",
    "nut_allergy": "no_nut", "no_nut": "no_nut", "坚果过敏": "no_nut",
    "seafood_allergy": "no_seafood", "no_seafood": "no_seafood", "海鲜过敏": "no_seafood",
    "shellfish_allergy": "no_seafood",
}


def normalize_restrictions(raw) -> set[str]:
    out: set[str] = set()
    for r in raw or []:
        key = str(r).strip().lower()
        if key in _RESTRICTION_ALIASES:
            out.add(_RESTRICTION_ALIASES[key])
    if "vegan" in out:
        out.update({"vegetarian", "no_dairy"})
    return out


def _f(id, name, p, fat, c, kind, allergens=(), leu=False, canteen=True):
    return {
        "id": id, "name": name, "kind": kind,
        "per100": {"p": p, "f": fat, "c": c},
        "allergens": set(allergens),
        "leucine_rich": leu, "canteen_ok": canteen,
    }


# ── 蛋白源（leu=亮氨酸足，能有效触发肌肉蛋白合成）─────────────
PROTEINS = [
    _f("chicken_breast", "鸡胸肉", 31, 3.6, 0, "meat", leu=True),
    _f("chicken_thigh", "鸡腿肉（去皮）", 24, 9, 0, "meat", leu=True),
    _f("lean_beef", "瘦牛肉", 26, 8, 0, "meat", leu=True),
    _f("lean_pork", "猪里脊", 22, 7, 0, "meat", leu=True),
    _f("white_fish", "龙利鱼 / 巴沙鱼", 20, 2, 0, "seafood", leu=True),
    _f("salmon", "三文鱼", 20, 13, 0, "seafood", leu=True),
    _f("shrimp", "虾仁", 20, 1, 1, "seafood", leu=True),
    _f("egg", "全蛋", 13, 11, 1, "egg", leu=True),
    _f("egg_white", "蛋清", 11, 0.2, 0.7, "egg", leu=True),
    _f("greek_yogurt", "无糖希腊酸奶", 9, 4, 4, "dairy", leu=True),
    _f("cottage_cheese", "白干酪 / 茅屋芝士", 11, 4, 3, "dairy", leu=True),
    _f("milk", "牛奶", 3.3, 3.6, 5, "dairy", leu=True),
    _f("whey", "乳清蛋白粉", 80, 6, 8, "dairy", leu=True, canteen=False),
    _f("tofu_firm", "北豆腐", 12, 6, 3, "plant", allergens=("soy",), leu=True),
    _f("tofu_dried", "豆腐干", 16, 8, 4, "plant", allergens=("soy",), leu=True),
    _f("soy_milk", "无糖豆浆", 3.5, 1.8, 1.2, "plant", allergens=("soy",), leu=True),
    _f("edamame", "毛豆", 11, 5, 9, "plant", allergens=("soy",), leu=True),
    _f("tempeh", "天贝", 19, 11, 9, "plant", allergens=("soy",), leu=True),
    _f("soy_protein_powder", "大豆分离蛋白粉", 82, 3, 5, "plant", allergens=("soy",), leu=True, canteen=False),
    _f("seitan", "面筋", 25, 2, 14, "plant", allergens=("gluten",)),
    _f("lentils", "扁豆（熟）", 9, 0.4, 20, "plant"),
    _f("chickpeas", "鹰嘴豆（熟）", 9, 2.6, 27, "plant"),
]

# ── 主食 / 碳水 ─────────────────────────────────────────────
STAPLES = [
    _f("rice", "米饭", 2.6, 0.3, 28, "plant"),
    _f("brown_rice", "糙米饭", 2.7, 0.9, 25, "plant"),
    _f("oats", "燕麦", 13, 7, 60, "plant"),
    _f("sweet_potato", "红薯", 1.6, 0.1, 20, "plant"),
    _f("potato", "土豆", 2, 0.1, 17, "plant"),
    _f("corn", "玉米", 3.4, 1.5, 19, "plant"),
    _f("rice_noodles", "米粉 / 河粉", 3, 0.3, 24, "plant"),
    _f("quinoa", "藜麦（熟）", 4.4, 1.9, 21, "plant"),
    _f("banana", "香蕉", 1.1, 0.3, 23, "plant"),
    _f("whole_wheat_bread", "全麦面包", 12, 4, 43, "plant", allergens=("gluten",)),
    _f("noodles", "面条（熟）", 5, 1, 25, "plant", allergens=("gluten",)),
]

# ── 蔬菜 ───────────────────────────────────────────────────
VEG = [
    _f("broccoli", "西兰花", 2.8, 0.4, 7, "plant"),
    _f("leafy_greens", "青菜 / 菠菜", 2.5, 0.3, 4, "plant"),
    _f("bell_pepper", "彩椒", 1, 0.3, 6, "plant"),
    _f("cucumber_tomato", "黄瓜 / 番茄", 0.9, 0.2, 3.5, "plant"),
    _f("mushroom", "菌菇", 3, 0.3, 3, "plant"),
    _f("carrot", "胡萝卜", 0.9, 0.2, 10, "plant"),
]

# ── 脂肪源 ─────────────────────────────────────────────────
FATS = [
    _f("olive_oil", "橄榄油 / 菜籽油", 0, 100, 0, "plant"),
    _f("avocado", "牛油果", 2, 15, 9, "plant"),
    _f("seeds", "奇亚籽 / 亚麻籽", 17, 31, 42, "plant"),
    _f("nuts_almond", "杏仁 / 混合坚果", 21, 50, 22, "plant", allergens=("nut",)),
    _f("peanut_butter", "花生酱", 25, 50, 20, "plant", allergens=("nut",)),
]

FOODS = PROTEINS + STAPLES + VEG + FATS
_BY_CAT = {"protein": PROTEINS, "staple": STAPLES, "veg": VEG, "fat": FATS}


def _allowed(food: dict, restrictions: set[str]) -> bool:
    kind, al = food["kind"], food["allergens"]
    if "vegetarian" in restrictions and kind not in ("egg", "dairy", "plant"):
        return False
    if "vegan" in restrictions and kind != "plant":
        return False
    if "halal" in restrictions and food["id"] == "lean_pork":
        return False
    if "no_dairy" in restrictions and kind == "dairy":
        return False
    if "no_seafood" in restrictions and kind == "seafood":
        return False
    if "no_gluten" in restrictions and "gluten" in al:
        return False
    if "no_nut" in restrictions and "nut" in al:
        return False
    if "no_pork" in restrictions and food["id"] == "lean_pork":
        return False
    if "no_beef" in restrictions and food["id"] == "lean_beef":
        return False
    return True


def _pool(cat: str, restrictions: set[str], canteen: bool, prefer_leucine=False) -> list[dict]:
    # 保持 FOODS 里的登记顺序（已是"常用度"排序），只做过滤 + 稳定分层
    pool = [f for f in _BY_CAT[cat] if _allowed(f, restrictions)]
    if canteen:
        pool = [f for f in pool if f["canteen_ok"]] or pool
    if prefer_leucine:
        pool = [f for f in pool if f["leucine_rich"]] + [f for f in pool if not f["leucine_rich"]]
    return pool


def _round(x: float) -> int:
    # 半数向上，与 Dart 端一致（不用 Python round 的银行家舍入）
    import math
    return int(math.floor(x + 0.5))


def _grams_for(food: dict, macro: str, target_g: float) -> int:
    per = food["per100"].get(macro, 0)
    if per <= 0 or target_g <= 0:
        return 0
    return max(5, _round(target_g / per * 100 / 5) * 5)


def hand_portions(meal: dict) -> dict:
    """把每餐宏量目标翻成手掌份数。"""
    return {
        "protein_palms": max(1, _round(meal["protein_g"] / PALM_PROTEIN_G)),
        "carb_cupped": max(0, _round(meal["carbs_g"] / CUPPED_CARB_G)),
        "fat_thumbs": max(0, _round(meal["fat_g"] / THUMB_FAT_G)),
        "veg_fists": 1 if meal.get("carbs_g", 0) < 40 else 2,
    }


def hand_portion_text(meal: dict) -> str:
    hp = hand_portions(meal)
    parts = [f"{hp['protein_palms']} 手掌蛋白"]
    if hp["carb_cupped"]:
        parts.append(f"{hp['carb_cupped']} 捧碳水")
    parts.append(f"{hp['veg_fists']} 拳蔬菜")
    if hp["fat_thumbs"]:
        parts.append(f"{hp['fat_thumbs']} 拇指脂肪")
    return " + ".join(parts)


def suggest_meal(
    meal: dict, restrictions: set[str], cooking_access: str,
    is_post_workout: bool, n_options: int = 2, rotate: int = 0,
) -> list[dict]:
    """meal = {protein_g, carbs_g, fat_g}；返回 1–3 个「怎么吃」的精确方案。

    rotate：按餐次错开选材，让一天各餐不重样。
    """
    canteen = cooking_access in ("canteen", "none")
    # 主蛋白源：排除牛奶 / 豆浆这类稀释饮品（否则要 1kg 才够一餐蛋白）
    proteins = [p for p in _pool("protein", restrictions, canteen, prefer_leucine=True)
                if p["per100"]["p"] >= 8]
    staples = _pool("staple", restrictions, canteen)
    veg = _pool("veg", restrictions, canteen)
    fats = _pool("fat", restrictions, canteen)

    n = min(n_options, max(1, len(proteins)))
    options: list[dict] = []
    for i in range(n):
        k = i + rotate
        items: list[str] = []
        base_fat = 0.0
        if proteins:
            p = proteins[k % len(proteins)]
            g = _grams_for(p, "p", meal["protein_g"])
            base_fat += p["per100"]["f"] * g / 100
            items.append(f"{p['name']} {g}g")
        if staples:
            s = staples[k % len(staples)]
            g = _grams_for(s, "c", meal["carbs_g"])
            base_fat += s["per100"]["f"] * g / 100
            if g:
                items.append(f"{s['name']} {g}g")
        if veg:
            items.append(f"{veg[k % len(veg)]['name']} 150g")
        fat_gap = meal["fat_g"] - base_fat
        if fat_gap >= 4 and fats:
            fsrc = fats[k % len(fats)]
            g = _grams_for(fsrc, "f", fat_gap)
            if g >= 5:
                items.append(f"{fsrc['name']} {g}g")
        note = "练后：先补蛋白 + 快碳" if is_post_workout else ""
        if canteen:
            note = (note + "；" if note else "") + "食堂/外食按份估算：蛋白管够、主食减半、少油"
        options.append({"items": items, "note": note})
    return options


def leucine_rich_names(restrictions: set[str], limit: int = 5) -> list[str]:
    return [f["name"] for f in PROTEINS if f["leucine_rich"] and _allowed(f, restrictions)][:limit]
