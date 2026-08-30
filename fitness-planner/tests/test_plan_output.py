"""PlanOutput 单元测试。"""
import unittest
import sys
import json
sys.path.insert(0, str(__import__('pathlib').Path(__file__).resolve().parent.parent))

from engine.profile_validator import validate
from engine.tdee_calculator import calculate
from engine.macro_allocator import allocate
from engine.split_selector import select
from engine.exercise_library import ExerciseLibrary
from engine.session_builder import build_sessions
from engine.progression_planner import plan
from engine.meal_distributor import distribute
from engine.supplement_advisor import advise
from engine.plan_output import generate_json, to_json_string


class TestPlanOutput(unittest.TestCase):

    def setUp(self):
        self.lib = ExerciseLibrary()

    def _generate(self):
        raw = {
            "gender": "M", "age": 25, "height_cm": 175.0, "weight_kg": 70.0,
            "level": "intermediate", "goal": "hypertrophy", "days_per_week": 5,
            "minutes_per_session": 90, "equipment": ["barbell", "dumbbell", "cable", "machine"],
            "meals_per_day": 5,
        }
        p = validate(raw)
        tdee = calculate(p)
        macros = allocate(p, tdee)
        split = select(p)
        sessions = build_sessions(p, split, self.lib)
        prog = plan(p)
        meals = distribute(p, macros)
        supps = advise(p, macros)
        return generate_json(p, tdee, macros, split, sessions, prog, meals, supps)

    def test_has_meta(self):
        plan_json = self._generate()
        self.assertIn("meta", plan_json)
        self.assertEqual(plan_json["meta"]["version"], "1.3")
        self.assertIn("generated_at", plan_json["meta"])
        self.assertGreater(len(plan_json["meta"]["evidence_basis"]), 0)

    def test_has_profile(self):
        plan_json = self._generate()
        self.assertEqual(plan_json["profile"]["gender"], "M")
        self.assertIn("bmi", plan_json["profile"])

    def test_has_nutrition(self):
        plan_json = self._generate()
        self.assertIn("nutrition", plan_json)
        self.assertIn("tdee", plan_json["nutrition"])
        self.assertIn("macros", plan_json["nutrition"])
        self.assertIn("meals", plan_json["nutrition"])
        self.assertIn("supplements", plan_json["nutrition"])

    def test_has_training(self):
        plan_json = self._generate()
        self.assertIn("training", plan_json)
        self.assertIn("split", plan_json["training"])
        self.assertIn("schedule", plan_json["training"])
        self.assertIn("progression", plan_json["training"])

    def test_schedule_has_7_days(self):
        plan_json = self._generate()
        self.assertEqual(len(plan_json["training"]["schedule"]), 7)

    def test_json_serializable(self):
        plan_json = self._generate()
        s = to_json_string(plan_json)
        parsed = json.loads(s)
        self.assertEqual(parsed["meta"]["version"], "1.3")

    def test_has_first_stage_goal(self):
        plan_json = self._generate()
        stage = plan_json["stage_goal"]
        self.assertEqual(stage["stage_type"], "adaptation")
        self.assertEqual(stage["cycle_weeks"], 4)
        self.assertEqual(stage["adherence_target_pct"], 80)
        self.assertEqual(stage["unlock_reward"], "pet_hatchling")

    def test_has_volume_report(self):
        plan_json = self._generate()
        training = plan_json["training"]
        self.assertIn("weekly_volume_delivered", training)
        self.assertIn("volume_coverage_pct", training)
        self.assertIn("volume_notes", training)
        self.assertIn("capacity_recommendation", training)
        self.assertIsInstance(training["volume_coverage_pct"], int)
        self.assertLessEqual(training["volume_coverage_pct"], 100)

    def test_evidence_basis_contains_pmids(self):
        plan_json = self._generate()
        for pmid in plan_json["meta"]["evidence_basis"]:
            self.assertIsInstance(pmid, str)


if __name__ == "__main__":
    unittest.main()
