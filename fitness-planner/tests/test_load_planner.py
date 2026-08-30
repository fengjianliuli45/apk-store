"""LoadPlanner 测试：1RM 反推 + 百分比转具体重量。"""
import unittest
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).resolve().parent.parent))

from engine.profile_validator import validate
from engine.load_planner import estimate_1rm, build_one_rm_map, suggest_load
from engine.exercise_library import ExerciseLibrary
from engine.pipeline import generate_plan


class TestLoadPlanner(unittest.TestCase):

    def setUp(self):
        self.lib = ExerciseLibrary()

    def test_epley(self):
        self.assertEqual(estimate_1rm(100, 1), 103.3)
        self.assertEqual(estimate_1rm(100, 5), 116.7)
        # 次数截断到 12
        self.assertEqual(estimate_1rm(50, 20), estimate_1rm(50, 12))

    def test_build_one_rm_map(self):
        m = build_one_rm_map({
            "squat": {"weight_kg": 100, "reps": 5},
            "bench": {"one_rm_kg": 90},
            "bogus": {"weight_kg": 10, "reps": 5},
        })
        self.assertEqual(m["squat"], 116.7)
        self.assertEqual(m["bench"], 90.0)
        self.assertNotIn("bogus", m)

    def test_barbell_bench_gets_kg(self):
        ex = next(e for e in self.lib.all() if e.id == "barbell_bench_press")
        text, kg = suggest_load(ex, {"bench": 90.0}, 0.72, "65-80% 1RM")
        self.assertIsNotNone(kg)
        self.assertIn("kg", text)
        self.assertAlmostEqual(kg, 65.0, delta=2.5)

    def test_bodyweight_move_no_kg(self):
        ex = next(e for e in self.lib.all() if e.id == "push_up")
        text, kg = suggest_load(ex, {"bench": 90.0}, 0.72, "65-80% 1RM")
        self.assertIsNone(kg)
        self.assertIn("自重", text)

    def test_no_baseline_falls_back_to_rpe(self):
        ex = next(e for e in self.lib.all() if e.id == "barbell_bench_press")
        text, kg = suggest_load(ex, {}, 0.72, "65-80% 1RM")
        self.assertIsNone(kg)
        self.assertIn("RPE", text)

    def test_dumbbell_labelled_per_hand(self):
        ex = next(e for e in self.lib.all() if e.id == "dumbbell_bench_press")
        text, kg = suggest_load(ex, {"bench": 90.0}, 0.72, "65-80% 1RM")
        self.assertIn("kg/只", text)

    def test_pipeline_with_baseline(self):
        raw = {
            "gender": "M", "age": 28, "height_cm": 178.0, "weight_kg": 80.0,
            "level": "intermediate", "goal": "hypertrophy", "minutes_per_session": 75,
            "equipment": ["barbell", "dumbbell", "cable", "machine"],
            "strength_baseline": {
                "squat": {"weight_kg": 100, "reps": 5},
                "bench": {"weight_kg": 70, "reps": 8},
                "hinge": {"weight_kg": 120, "reps": 5},
                "row": {"weight_kg": 60, "reps": 10},
            },
        }
        plan = generate_plan(raw, self.lib)
        self.assertEqual(plan["meta"]["version"], "1.8")
        self.assertIn("one_rm_estimates", plan["profile"])
        self.assertEqual(plan["profile"]["one_rm_estimates"]["squat"]["kg"], 116.7)
        # 至少一个动作有具体 kg
        loads = [e for s in plan["training"]["schedule"] for e in s["exercises"]]
        self.assertTrue(any(e["load_kg"] for e in loads))
        # 阶段目标里有标准化测试动作
        self.assertTrue(plan["stage_goal"]["baseline_lifts"])

    def test_pipeline_without_baseline(self):
        raw = {
            "gender": "M", "age": 25, "height_cm": 178.0, "weight_kg": 75.0,
            "level": "beginner", "goal": "hypertrophy", "minutes_per_session": 55,
            "equipment": ["bodyweight"],
        }
        plan = generate_plan(raw, self.lib)
        loads = [e for s in plan["training"]["schedule"] for e in s["exercises"]]
        self.assertTrue(all(e["load_kg"] is None for e in loads))
        self.assertTrue(any("RPE" in n or "起始重量" in n for n in plan["profile"]["notes"]))


if __name__ == "__main__":
    unittest.main()
