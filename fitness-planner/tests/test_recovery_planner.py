"""RecoveryPlanner 测试。"""
import unittest
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).resolve().parent.parent))

from engine.pipeline import generate_plan


class TestRecoveryPlanner(unittest.TestCase):

    def _plan(self, **kw):
        raw = {
            "gender": "M", "age": 28, "height_cm": 175.0, "weight_kg": 75.0,
            "level": "intermediate", "goal": "hypertrophy",
            "minutes_per_session": 60, "equipment": ["barbell", "dumbbell", "cable", "machine"],
        }
        raw.update(kw)
        return generate_plan(raw)["training"]

    def _days(self, t):
        return {rd["day"]: rd for rd in t["recovery_days"]}

    def test_every_rest_day_has_content(self):
        t = self._plan()
        rest_days = {s["day"] for s in t["schedule"] if s["type"] == "rest"}
        covered = {rd["day"] for rd in t["recovery_days"]}
        self.assertEqual(rest_days, covered)

    def test_keeps_one_full_rest(self):
        t = self._plan()
        kinds = [rd["kind"] for rd in t["recovery_days"]]
        self.assertIn("rest", kinds)

    def test_fat_loss_gets_cardio(self):
        t = self._plan(goal="fat_loss")
        kinds = [rd["kind"] for rd in t["recovery_days"]]
        self.assertIn("cardio", kinds)

    def test_beginner_no_pump(self):
        t = self._plan(level="beginner", minutes_per_session=50)
        kinds = [rd["kind"] for rd in t["recovery_days"]]
        self.assertNotIn("pump", kinds)

    def test_intermediate_under_target_gets_pump(self):
        # 60 分钟中级增肌 → 覆盖 < 96% → 有一天泵感课
        t = self._plan(level="intermediate", goal="hypertrophy", minutes_per_session=60)
        if t["volume_coverage_pct"] < 96:
            kinds = [rd["kind"] for rd in t["recovery_days"]]
            self.assertIn("pump", kinds)

    def test_recovery_day_shape(self):
        t = self._plan(goal="fat_loss")
        for rd in t["recovery_days"]:
            self.assertIn(rd["kind"], ("rest", "mobility", "cardio", "pump"))
            self.assertIn("title", rd)
            self.assertIn("focus", rd)
            self.assertIsInstance(rd["items"], list)

    def test_six_day_split_still_keeps_full_rest(self):
        t = self._plan(level="advanced", goal="hypertrophy", minutes_per_session=50)
        hard = [s for s in t["schedule"] if s["type"] != "rest"]
        if len(hard) >= 5:
            kinds = [rd["kind"] for rd in t["recovery_days"]]
            self.assertIn("rest", kinds)


if __name__ == "__main__":
    unittest.main()
