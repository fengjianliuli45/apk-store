"""InjuryPlanner — 伤病 → 规避不适动作 + 用同肌群安全替代，而不是把整块肌肉删掉。

原则（循证，见 README 来源）：
- 在无痛范围内练；某动作痛就换 ROM / 减重 / 换动作，不是完全不练那块肌肉
- 常见伤病站点：肩 / 下背 / 膝 / 手腕（PMC12591260）
"""
from __future__ import annotations

# ── 伤病词归一（中英 + 常见写法 → 规范键）──────────────────
_INJURY_ALIASES = {
    "knee": "knee", "knees": "knee", "膝": "knee", "膝盖": "knee", "膝关节": "knee",
    "patella": "knee", "patellofemoral": "knee", "meniscus": "knee", "半月板": "knee",
    "shoulder": "shoulder", "shoulders": "shoulder", "肩": "shoulder", "肩膀": "shoulder",
    "肩关节": "shoulder", "impingement": "shoulder", "肩峰": "shoulder", "rotator_cuff": "shoulder",
    "肩袖": "shoulder", "ac_joint": "shoulder",
    "lower_back": "lower_back", "low_back": "lower_back", "back": "lower_back",
    "lumbar": "lower_back", "腰": "lower_back", "腰椎": "lower_back", "下背": "lower_back",
    "腰痛": "lower_back", "腰肌": "lower_back", "disc": "lower_back", "椎间盘": "lower_back",
    "sciatica": "lower_back", "坐骨神经": "lower_back",
    "wrist": "wrist", "wrists": "wrist", "手腕": "wrist", "腕": "wrist", "腕关节": "wrist",
    "elbow": "elbow", "elbows": "elbow", "肘": "elbow", "手肘": "elbow", "肘关节": "elbow",
    "tennis_elbow": "elbow", "golfer_elbow": "elbow", "网球肘": "elbow", "高尔夫球肘": "elbow",
    "epicondylitis": "elbow",
    "hip": "hip", "hips": "hip", "髋": "hip", "髋关节": "hip", "胯": "hip",
    "ankle": "ankle", "ankles": "ankle", "踝": "ankle", "脚踝": "ankle", "踝关节": "ankle",
    "achilles": "ankle", "跟腱": "ankle",
    "neck": "neck", "颈": "neck", "颈椎": "neck", "脖子": "neck", "cervical": "neck",
}

# ── 每个规范伤病：避开的动作模式 / 具体动作 + 一句给用户的说明 ──
INJURY_RULES = {
    "knee": {
        "avoid_patterns": (),
        "avoid_exercises": (
            "single_leg_squat", "sissy_squat", "nordic_curl",
            "walking_lunges", "lunges", "reverse_lunge", "bulgarian_split_squat",
            "step_up", "box_squat",
        ),
        "note": "膝伤：深蹲只到大腿平行、控制膝盖前移；多用髋主导（罗马尼亚硬拉、臀推）"
                "和器械支撑（腿举、高脚杯深蹲）；不做弓步 / 跳跃 / 单腿蹲。",
    },
    "shoulder": {
        # 不整段禁 vertical_push——保留可控幅度的哑铃推举；只砍高风险的
        "avoid_patterns": (),
        "avoid_exercises": (
            "overhead_press", "push_press", "barbell_front_raise",
            "upright_row", "cable_upright_row", "dumbbell_upright_row",
            "dips", "assisted_dips", "decline_barbell_press", "decline_dumbbell_press",
            "lateral_raise", "cable_lateral_raise", "lateral_raise_machine",
            "band_lateral_raise", "pike_push_up", "elevated_pike_push_up",
        ),
        "note": "肩伤 / 撞击：不做杠铃过顶推举、直立划船、侧平举过肩、双杠臂屈伸；"
                "哑铃推举 / 卧推 / 俯卧撑控制在无痛幅度，多做面拉 / 肩胛稳定。",
    },
    "lower_back": {
        "avoid_patterns": (),
        "avoid_exercises": (
            "deadlift", "sumo_deadlift", "trap_bar_deadlift", "dumbbell_deadlift",
            "barbell_row", "pendlay_row", "good_morning", "romanian_deadlift",
            "barbell_back_squat", "front_squat", "overhead_press", "push_press",
            "russian_twist", "cable_woodchop", "cable_russian_twists",
            "kettlebell_swing", "kettlebell_clean", "superman_push_up",
            "back_extension", "hanging_windshield_wiper",
        ),
        "note": "下背伤：不做大重量轴向负荷（杠铃深蹲 / 硬拉 / 站姿推举）和负重脊柱屈曲 / 旋转；"
                "用胸垫划船、腿举、高脚杯深蹲、臀推，核心练死虫 / 鸟狗 / 平板。",
    },
    "wrist": {
        "avoid_patterns": (),
        "avoid_exercises": (
            "front_squat", "barbell_curl", "ez_bar_curl", "upright_row",
            "push_up", "wide_push_up", "diamond_push_up", "close_grip_push_up",
            "archer_push_up", "decline_push_up", "incline_push_up",
            "band_wrist_curl", "dead_hang",
        ),
        "note": "手腕伤：避免手腕背屈负重；用哑铃中立握、器械、助力带 / 俯卧撑握把，"
                "弯举改锤式 / 绳索。",
    },
    "elbow": {
        "avoid_patterns": (),
        "avoid_exercises": (
            "skull_crusher", "french_press", "overhead_triceps_extension",
            "cable_overhead_extension", "band_overhead_triceps_extension",
            "barbell_curl", "ez_bar_curl", "close_grip_bench_press",
            "diamond_push_up", "close_grip_push_up",
        ),
        "note": "肘部肌腱炎：直臂 / 孤立臂部动作减量、用中立握、别练到力竭；"
                "大肌群复合动作正常练。",
    },
    "hip": {
        "avoid_patterns": (),
        "avoid_exercises": (
            "single_leg_squat", "sissy_squat", "bulgarian_split_squat",
            "box_squat", "sumo_deadlift",
        ),
        "note": "髋伤 / 撞击：避免深屈髋和大开脚硬拉；深蹲减幅度，多做臀推 / 臀桥 / 腿举。",
    },
    "ankle": {
        "avoid_patterns": ("calf_raise",),   # 提踵直接压踝 / 跟腱，整段避开
        "avoid_exercises": (
            "walking_lunges", "lunges", "reverse_lunge", "single_leg_squat", "step_up",
        ),
        "note": "踝伤 / 跟腱：不做提踵和跳跃、弓步；下肢用腿举 / 臀推等踝关节负荷小的动作，"
                "小腿暂时不直接练。",
    },
    "neck": {
        "avoid_patterns": (),
        "avoid_exercises": (
            "overhead_press", "push_press", "barbell_shrug", "dumbbell_shrug",
            "upright_row", "band_shrug", "band_y_raise",
        ),
        "note": "颈椎伤：不做过顶推举、耸肩、直立划船；划船 / 下拉保持颈部中立。",
    },
}

# 动作自带的 injury_contraindications 字符串 → 规范伤病键
_CONTRAIND_TO_CANONICAL = {
    "shoulder_impingement": "shoulder", "shoulder_injury": "shoulder",
    "knee_injury": "knee", "knee_pain": "knee",
    "lower_back_injury": "lower_back", "lower_back_pain": "lower_back",
    "wrist_injury": "wrist", "elbow_injury": "elbow",
    "hip_impingement": "hip", "hip_injury": "hip",
    "achilles_injury": "ankle", "ankle_injury": "ankle",
    "neck_injury": "neck",
}


def normalize_injuries(raw) -> set[str]:
    """自由文本伤病 → 规范键集合（认不出的忽略）。"""
    out: set[str] = set()
    for item in raw or []:
        s = str(item).strip().lower()
        if not s:
            continue
        if s in _INJURY_ALIASES:
            out.add(_INJURY_ALIASES[s])
            continue
        # 子串命中任一别名
        for alias, canon in _INJURY_ALIASES.items():
            if len(alias) >= 2 and alias in s:
                out.add(canon)
    return out


def is_contraindicated(ex, canonical_injuries: set[str]) -> bool:
    """硬禁：高置信度不适（整段动作模式 / 具体动作），直接从选池剔除。"""
    if not canonical_injuries:
        return False
    for inj in canonical_injuries:
        rule = INJURY_RULES.get(inj, {})
        if ex.movement_pattern in rule.get("avoid_patterns", ()):
            return True
        if ex.id in rule.get("avoid_exercises", ()):
            return True
    return False


def is_cautioned(ex, canonical_injuries: set[str]) -> bool:
    """软提示：动作自带的 injury_contraindications 命中——保留但排到最后，
    只有实在没别的选项才用，并提示「无痛幅度、减重」。"""
    if not canonical_injuries:
        return False
    for c in ex.injury_contraindications:
        if _CONTRAIND_TO_CANONICAL.get(str(c).strip().lower()) in canonical_injuries:
            return True
    return False


def injury_accommodations(canonical_injuries: set[str]) -> list[dict]:
    """输出层：每个伤病一条说明。"""
    return [
        {"injury": inj, "note": INJURY_RULES.get(inj, {}).get("note", "在无痛范围内训练，痛就换动作。")}
        for inj in sorted(canonical_injuries)
    ]
