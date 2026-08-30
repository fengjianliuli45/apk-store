"""ExerciseLibrary 单元测试。"""
import unittest
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).resolve().parent.parent))

from engine.exercise_library import ExerciseLibrary


class TestExerciseLibrary(unittest.TestCase):

    def setUp(self):
        self.lib = ExerciseLibrary()

    def test_loads_exercises(self):
        self.assertGreaterEqual(self.lib.count(), 80)

    def test_get_by_id(self):
        ex = self.lib.get_by_id("barbell_bench_press")
        self.assertIsNotNone(ex)
        self.assertEqual(ex.name, "杠铃卧推")

    def test_query_push(self):
        results = self.lib.query(
            exercise_type="push",
            equipment=["barbell", "bench"],
            injuries=None,
            level="beginner",
        )
        self.assertGreater(len(results), 0)
        for ex in results:
            self.assertIn(ex.movement_pattern, ["horizontal_push", "vertical_push"])

    def test_query_pull(self):
        results = self.lib.query(
            exercise_type="pull",
            equipment=["barbell", "cable"],
            level="beginner",
        )
        self.assertGreater(len(results), 0)

    def test_query_legs(self):
        results = self.lib.query(
            exercise_type="legs",
            equipment=["barbell", "rack"],
            level="intermediate",
        )
        self.assertGreater(len(results), 0)

    def test_equipment_filter(self):
        # bodyweight only
        results = self.lib.query(
            exercise_type="push",
            equipment=[],
            level="beginner",
        )
        for ex in results:
            self.assertTrue(all(eq in ["bodyweight"] for eq in ex.equipment_required))

    def test_injury_filter(self):
        results = self.lib.query(
            exercise_type="push",
            equipment=["barbell", "bench"],
            injuries=["shoulder_impingement"],
            level="beginner",
        )
        for ex in results:
            self.assertNotIn("shoulder_impingement", ex.injury_contraindications)

    def test_level_filter(self):
        results = self.lib.query(
            exercise_type="push",
            equipment=["barbell", "bench", "dumbbell", "cable", "machine"],
            level="beginner",
        )
        for ex in results:
            self.assertNotEqual(ex.skill_level, "advanced")

    def test_query_by_muscle(self):
        results = self.lib.query_by_muscle("chest", ["barbell", "bench"], "intermediate")
        self.assertGreater(len(results), 0)
        for ex in results:
            self.assertIn("chest", ex.primary_muscles + ex.secondary_muscles)

    def test_find_alternatives(self):
        alts = self.lib.find_alternatives("barbell_bench_press", ["shoulder_impingement"])
        self.assertGreater(len(alts), 0)

    # ── 居家动作库扩充（任务 P0 #1）──────────────────────────

    def test_library_expanded(self):
        self.assertGreaterEqual(self.lib.count(), 150)

    def test_home_user_can_train_every_muscle(self):
        """纯自重 + 弹力带 + 单杠 的用户，每个主要肌群都有可练动作。"""
        equip = ["bodyweight", "band", "pull_up_bar"]
        for muscle in ("chest", "back", "shoulders", "biceps", "triceps",
                       "quads", "hamstrings", "glutes", "calves"):
            res = self.lib.query_by_muscle(muscle, equip, "beginner")
            self.assertGreaterEqual(
                len(res), 1, f"{muscle}: 居家用户无可练动作")

    def test_band_and_pull_up_bar_gated(self):
        # 没有弹力带 → 不出现弹力带动作
        res = self.lib.query(exercise_type="pull", equipment=["bodyweight"], level="beginner")
        for ex in res:
            self.assertNotIn("band", ex.equipment_required)
            self.assertNotIn("pull_up_bar", ex.equipment_required)
        # 有单杠 → 引体类回来
        res2 = self.lib.query(exercise_type="pull",
                              equipment=["bodyweight", "pull_up_bar"], level="beginner")
        self.assertTrue(any(ex.id in ("pull_up", "chin_up", "inverted_row") for ex in res2))

    def test_rack_and_machine_imply_pull_up_bar(self):
        from engine.exercise_library import _expand_equipment
        self.assertIn("pull_up_bar", _expand_equipment(["barbell"]))   # barbell→rack→bar
        self.assertIn("pull_up_bar", _expand_equipment(["machine"]))
        self.assertNotIn("pull_up_bar", _expand_equipment(["dumbbell"]))

    def test_progression_rank_parsed(self):
        plank = self.lib.get_by_id("plank")
        archer = self.lib.get_by_id("archer_push_up")
        self.assertIsNone(plank.progression_rank)   # 非阶梯动作无此字段
        self.assertEqual(archer.progression_rank, 6)


if __name__ == "__main__":
    unittest.main()
