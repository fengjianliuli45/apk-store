import unittest
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).resolve().parent.parent))

from engine.profile_validator import validate
from engine.progression_planner import plan
from engine.stage_goal_planner import plan_stage_goal
from engine.session_builder import SessionResult


class TestStageGoalPlanner(unittest.TestCase):
    def _profile(self, goal="hypertrophy"):
        return validate({
            "gender": "M", "age": 25, "height_cm": 175, "weight_kg": 70,
            "level": "beginner", "goal": goal, "days_per_week": 3,
            "minutes_per_session": 45, "equipment": ["bodyweight"],
        })

    def _sessions(self):
        return [
            SessionResult(day=f"d{i}", type="full_body" if i < 3 else "rest",
                          duration_min=45 if i < 3 else 0, exercises=[], total_sets=0)
            for i in range(7)
        ]

    def test_four_week_adaptation_goal(self):
        profile = self._profile()
        result = plan_stage_goal(profile, plan(profile), self._sessions())
        self.assertEqual(result.stage_type, "adaptation")
        self.assertEqual(result.cycle_weeks, 4)
        self.assertEqual(result.planned_sessions, 12)
        self.assertEqual(result.required_sessions, 10)
        self.assertEqual(result.unlock_reward, "pet_hatchling")

    def test_goal_specific_body_trend_target(self):
        profile = self._profile("fat_loss")
        result = plan_stage_goal(profile, plan(profile), self._sessions())
        self.assertTrue(any(t.metric == "body_trend_target_met" for t in result.outcome_targets))


if __name__ == "__main__":
    unittest.main()
