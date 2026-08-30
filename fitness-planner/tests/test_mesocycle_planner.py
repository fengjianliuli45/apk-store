"""MesocyclePlanner 测试。"""
import unittest
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).resolve().parent.parent))

from engine.pipeline import generate_plan


class TestMesocyclePlanner(unittest.TestCase):

    def _meso(self, **kw):
        raw = {
            "gender": "M", "age": 28, "height_cm": 178.0, "weight_kg": 80.0,
            "level": "intermediate", "goal": "hypertrophy", "minutes_per_session": 75,
            "equipment": ["barbell", "dumbbell", "cable", "machine"],
        }
        raw.update(kw)
        return generate_plan(raw)["training"]["mesocycle"]

    def test_structure(self):
        m = self._meso()
        self.assertEqual(m["length_weeks"], 5)
        self.assertEqual(m["current_week"], 1)
        self.assertEqual(len(m["weeks"]), 5)
        self.assertEqual(m["weeks"][-1]["phase"], "deload")
        self.assertTrue(m["weeks"][-1]["is_deload"])
        self.assertFalse(m["weeks"][0]["is_deload"])

    def test_rir_decreases_then_deload_relaxes(self):
        weeks = self._meso()["weeks"]
        build = [w["rir_target"] for w in weeks if not w["is_deload"]]
        self.assertEqual(build, sorted(build, reverse=True))  # 3→…→0
        self.assertEqual(build[0], 3)
        self.assertEqual(build[-1], 0)
        self.assertGreaterEqual(weeks[-1]["rir_target"], 2)   # 减载放松

    def test_volume_ramps_up_to_base(self):
        weeks = self._meso()["weeks"]
        build = [w["week_total_sets"] for w in weeks if not w["is_deload"]]
        self.assertEqual(build, sorted(build))               # 非递减
        self.assertLess(build[0], build[-1])                 # 首周 < 末周
        # 减载周总组数最低
        self.assertLess(weeks[-1]["week_total_sets"], build[-1])

    def test_overrides_reference_plan_exercises(self):
        plan = generate_plan({
            "gender": "M", "age": 28, "height_cm": 178.0, "weight_kg": 80.0,
            "level": "beginner", "goal": "hypertrophy", "minutes_per_session": 60,
            "equipment": ["dumbbell", "bodyweight"],
        })["training"]
        ids = {e["exercise_id"] for s in plan["schedule"] for e in s["exercises"]}
        for w in plan["mesocycle"]["weeks"]:
            for day_ov in w["set_overrides"].values():
                for eid, sets in day_ov.items():
                    self.assertIn(eid, ids)
                    self.assertGreaterEqual(sets, 2)


if __name__ == "__main__":
    unittest.main()
