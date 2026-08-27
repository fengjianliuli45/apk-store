import unittest
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).resolve().parent.parent))

from engine.stage_goal_planner import StageGoal
from engine.stage_assessor import StageEvidence, assess_stage


def _goal():
    return StageGoal(
        stage_type="adaptation", goal_type="strength", cycle_weeks=4,
        planned_sessions=12, required_sessions=10, adherence_target_pct=80,
        minimum_active_weeks=3, minimum_comparable_measurements=2,
    )


class TestStageAssessor(unittest.TestCase):
    def test_achieves_from_training_performance_without_body_measurements(self):
        result = assess_stage(_goal(), StageEvidence(
            completed_sessions=10, active_weeks=4, comparable_measurements=2,
            same_load_rep_gain=2, body_trend_target_met=False,
        ))
        self.assertTrue(result.achieved)
        self.assertEqual(result.status, "achieved")

    def test_extends_when_data_is_insufficient(self):
        result = assess_stage(_goal(), StageEvidence(
            completed_sessions=12, active_weeks=4, comparable_measurements=1,
            performance_improvement_pct=5,
            performance_confirmations=2,
        ))
        self.assertFalse(result.achieved)
        self.assertEqual(result.status, "extended")
        self.assertEqual(result.confidence, "low")

    def test_percentage_improvement_requires_two_confirmations(self):
        single = assess_stage(_goal(), StageEvidence(
            completed_sessions=12, active_weeks=4, comparable_measurements=2,
            performance_improvement_pct=5, performance_confirmations=1,
        ))
        confirmed = assess_stage(_goal(), StageEvidence(
            completed_sessions=12, active_weeks=4, comparable_measurements=2,
            performance_improvement_pct=2.5, performance_confirmations=2,
        ))
        self.assertFalse(single.achieved)
        self.assertTrue(confirmed.achieved)

    def test_safety_issue_blocks_unlock(self):
        result = assess_stage(_goal(), StageEvidence(
            completed_sessions=12, active_weeks=4, comparable_measurements=2,
            stable_positive_response=True, unresolved_safety_issue=True,
        ))
        self.assertFalse(result.achieved)
        self.assertFalse(result.safety_met)


if __name__ == "__main__":
    unittest.main()
