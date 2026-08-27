import unittest
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).resolve().parent.parent))

from engine.response_profiler import ResponseObservation, profile_response


class TestResponseProfiler(unittest.TestCase):
    def test_first_cycle_keeps_body_response_unknown(self):
        result = profile_response(ResponseObservation(
            completed_cycles=1, adherence_pct=90, performance_improvement_pct=8,
            weight_trend_pct=-1,
        ))
        self.assertEqual(result.maturity, "preliminary")
        self.assertEqual(result.metabolism_response, "unknown")
        self.assertEqual(result.muscle_gain_response, "unknown")

    def test_multiple_cycles_build_developing_profile(self):
        result = profile_response(ResponseObservation(
            completed_cycles=2, adherence_pct=88, performance_improvement_pct=6,
            waist_trend_pct=-2,
        ))
        self.assertEqual(result.maturity, "developing")
        self.assertEqual(result.training_style, "steady")
        self.assertEqual(result.muscle_gain_response, "responsive")
        self.assertEqual(result.fat_loss_response, "responsive")


if __name__ == "__main__":
    unittest.main()
