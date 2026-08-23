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


if __name__ == "__main__":
    unittest.main()
