"""ExerciseLibrary — 动作库管理与筛选。

从 JSON 文件加载动作，提供按训练类型/器械/伤病/等级的筛选接口。
"""
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

DEFAULT_DATA_PATH = Path(__file__).resolve().parent.parent / "data" / "exercises.json"


def _expand_equipment(equipment: list[str]) -> set:
    """把用户器械扩成"实际可用"集合：
    - barbell → 也有 rack / bench；dumbbell → 也有 bench
    - rack / machine → 商业健身房/力量架自带单杠 → pull_up_bar
    - bodyweight 永远可用
    """
    e = set(equipment)
    if "barbell" in e:
        e.update({"rack", "bench"})
    if "dumbbell" in e:
        e.add("bench")
    if "rack" in e or "machine" in e:
        e.add("pull_up_bar")
    e.add("bodyweight")
    return e


@dataclass
class Exercise:
    id: str
    name: str
    name_en: str
    primary_muscles: list[str]
    secondary_muscles: list[str]
    movement_pattern: str
    compound: bool
    equipment_required: list[str]
    skill_level: str
    variations: list[str]
    injury_contraindications: list[str]
    alternatives_if_injured: list[str]
    video_url: Optional[str]
    form_cues: list[str]
    progression_rank: Optional[int] = None   # 徒手动作进阶序号（同 movement_pattern 内 1,2,3…）

    @classmethod
    def from_dict(cls, d: dict) -> "Exercise":
        return cls(
            id=d["id"],
            name=d["name"],
            name_en=d.get("name_en", ""),
            primary_muscles=d.get("primary_muscles", []),
            secondary_muscles=d.get("secondary_muscles", []),
            movement_pattern=d.get("movement_pattern", ""),
            compound=d.get("compound", False),
            equipment_required=d.get("equipment_required", []),
            skill_level=d.get("skill_level", "beginner"),
            variations=d.get("variations", []),
            injury_contraindications=d.get("injury_contraindications", []),
            alternatives_if_injured=d.get("alternatives_if_injured", []),
            video_url=d.get("video_url"),
            form_cues=d.get("form_cues", []),
            progression_rank=d.get("progression_rank"),
        )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "name": self.name,
            "name_en": self.name_en,
            "primary_muscles": self.primary_muscles,
            "secondary_muscles": self.secondary_muscles,
            "movement_pattern": self.movement_pattern,
            "compound": self.compound,
            "equipment_required": self.equipment_required,
            "skill_level": self.skill_level,
            "variations": self.variations,
            "injury_contraindications": self.injury_contraindications,
            "alternatives_if_injured": self.alternatives_if_injured,
            "video_url": self.video_url,
            "form_cues": self.form_cues,
            "progression_rank": self.progression_rank,
        }


# 训练类型 → movement_pattern 映射
TYPE_PATTERNS = {
    "push": ["horizontal_push", "vertical_push"],
    "pull": ["horizontal_pull", "vertical_pull"],
    "legs": ["squat", "hip_hinge", "knee_flexion", "hip_extension", "calf_raise"],
    "upper": ["horizontal_push", "vertical_push", "horizontal_pull", "vertical_pull", "elbow_flexion", "elbow_extension"],
    "lower": ["squat", "hip_hinge", "knee_flexion", "hip_extension", "calf_raise"],
    "full_body": ["horizontal_push", "vertical_push", "horizontal_pull", "vertical_pull", "squat", "hip_hinge", "knee_flexion", "hip_extension", "calf_raise", "core"],
    "core": ["core", "trunk_flexion", "trunk_rotation", "anti_extension"],
}

# 肌群 → 用于容量分配
MUSCLE_GROUPS = {
    "chest", "back", "quads", "hamstrings", "shoulders",
    "biceps", "triceps", "glutes", "calves", "core", "abs",
}


class ExerciseLibrary:
    """动作库管理器。"""

    def __init__(self, data_path: Optional[Path] = None):
        self.data_path = data_path or DEFAULT_DATA_PATH
        self._exercises: list[Exercise] = []
        self._index: dict[str, Exercise] = {}
        self.load()

    def load(self) -> None:
        with open(self.data_path, encoding="utf-8") as f:
            data = json.load(f)
        self._exercises = [Exercise.from_dict(e) for e in data]
        self._index = {e.id: e for e in self._exercises}

    def all(self) -> list[Exercise]:
        return list(self._exercises)

    def count(self) -> int:
        return len(self._exercises)

    def get_by_id(self, exercise_id: str) -> Optional[Exercise]:
        return self._index.get(exercise_id)

    def query(
        self,
        exercise_type: str,
        equipment: list[str],
        injuries: Optional[list[str]] = None,
        level: str = "beginner",
    ) -> list[Exercise]:
        """按训练类型、器械、伤病、等级筛选动作。

        exercise_type: "push" | "pull" | "legs" | "upper" | "lower" | "full_body" | "core"
        equipment: 用户拥有的器械列表
        injuries: 用户伤病列表（过滤不适动作）
        level: 技能等级（beginner 过滤 advanced 动作）
        """
        injuries = injuries or []
        patterns = TYPE_PATTERNS.get(exercise_type, [])
        if not patterns:
            return []

        expanded_equip = _expand_equipment(equipment)

        results = []
        for ex in self._exercises:
            # 匹配 movement pattern
            if ex.movement_pattern not in patterns:
                continue

            # 器械检查：动作所需器械必须全部在用户拥有列表中
            if not all(eq in expanded_equip for eq in ex.equipment_required):
                continue

            # 伤病过滤
            if injuries:
                skip = False
                for inj in injuries:
                    # 模糊匹配：如果伤病关键词出现在 contraindications 中
                    for contraind in ex.injury_contraindications:
                        if inj.lower() in contraind.lower() or contraind.lower() in inj.lower():
                            skip = True
                            break
                    if skip:
                        break
                if skip:
                    continue

            # 等级过滤：beginner 不做 advanced 动作
            if level == "beginner" and ex.skill_level == "advanced":
                continue

            results.append(ex)

        return results

    def query_by_muscle(self, muscle: str, equipment: list[str], level: str = "beginner") -> list[Exercise]:
        """按主肌群筛选。"""
        expanded_equip = _expand_equipment(equipment)

        results = []
        for ex in self._exercises:
            if muscle not in ex.primary_muscles and muscle not in ex.secondary_muscles:
                continue
            if not all(eq in expanded_equip for eq in ex.equipment_required):
                continue
            if level == "beginner" and ex.skill_level == "advanced":
                continue
            results.append(ex)

        return results

    def find_alternatives(self, exercise_id: str, injuries: list[str]) -> list[Exercise]:
        """查找替代动作（当原动作因伤病被排除时）。"""
        ex = self.get_by_id(exercise_id)
        if not ex:
            return []
        alt_ids = ex.alternatives_if_injured
        return [self._index[aid] for aid in alt_ids if aid in self._index]
