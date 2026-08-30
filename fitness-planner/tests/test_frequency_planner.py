"""FrequencyPlanner / Pipeline 测试。"""
import unittest
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).resolve().parent.parent))

from engine.profile_validator import validate
from engine.exercise_library import ExerciseLibrary
from engine.frequency_planner import plan_frequency, resolve, LEVEL_DAY_RANGE, COVERAGE_TARGET
from engine.pipeline import generate_plan


class TestFrequencyPlanner(unittest.TestCase):

    def setUp(self):
        self.lib = ExerciseLibrary()

    def _p(self, **kw):
        raw = {
            "gender": "M", "age": 28, "height_cm": 175.0, "weight_kg": 72.0,
            "level": "beginner", "goal": "hypertrophy",
            "minutes_per_session": 60, "equipment": ["dumbbell", "bodyweight"],
        }
        raw.update(kw)
        return validate(raw)

    def test_days_optional_in_validate(self):
        p = self._p()
        self.assertIsNone(p.days_per_week)

    def test_explicit_days_respected(self):
        p = self._p(days_per_week=4)
        fp = plan_frequency(p, self.lib)
        self.assertEqual(fp.days_per_week, 4)
        self.assertFalse(fp.minutes_raised)

    def test_engine_picks_days_in_level_range(self):
        for level in ("beginner", "intermediate", "advanced"):
            lo, hi = LEVEL_DAY_RANGE[level]
            fp = plan_frequency(self._p(level=level, minutes_per_session=60), self.lib)
            self.assertGreaterEqual(fp.days_per_week, lo)
            self.assertLessEqual(fp.days_per_week, hi)

    def test_below_min_length_raises_minutes(self):
        fp = plan_frequency(self._p(level="beginner", goal="hypertrophy", minutes_per_session=30), self.lib)
        self.assertTrue(fp.minutes_raised)
        self.assertGreaterEqual(fp.minutes_per_session, fp.min_session_minutes)
        self.assertIn("至少", fp.note)

    def test_enough_time_hits_target(self):
        fp = plan_frequency(self._p(level="beginner", goal="hypertrophy", minutes_per_session=75), self.lib)
        self.assertFalse(fp.minutes_raised)
        self.assertGreaterEqual(fp.coverage_pct, COVERAGE_TARGET)

    def test_fewest_days_preference(self):
        """时间充足时，优先排更少的天数。"""
        short = plan_frequency(self._p(level="intermediate", minutes_per_session=55), self.lib)
        long = plan_frequency(self._p(level="intermediate", minutes_per_session=90), self.lib)
        self.assertLessEqual(long.days_per_week, short.days_per_week)

    def test_resolve_fills_profile(self):
        p = self._p(minutes_per_session=30)
        resolved, fp = resolve(p, self.lib)
        self.assertEqual(resolved.days_per_week, fp.days_per_week)
        self.assertEqual(resolved.minutes_per_session, fp.minutes_per_session)
        self.assertIn(fp.note, resolved.notes)
        # 原 profile 不被污染
        self.assertIsNone(p.days_per_week)

    def test_fat_loss_min_lower_than_hypertrophy(self):
        fl = plan_frequency(self._p(goal="fat_loss", minutes_per_session=30), self.lib)
        hy = plan_frequency(self._p(goal="hypertrophy", minutes_per_session=30), self.lib)
        self.assertLessEqual(fl.min_session_minutes, hy.min_session_minutes)

    def test_min_session_minutes_for_matches_plan(self):
        """onboarding 查询到的最低时长 == 实际排计划时用的最低时长。"""
        from engine.frequency_planner import min_session_minutes_for
        equip = ["dumbbell", "bodyweight"]
        m = min_session_minutes_for("beginner", "hypertrophy", equip, self.lib)
        fp = plan_frequency(self._p(minutes_per_session=m), self.lib)
        self.assertEqual(fp.min_session_minutes, m)
        self.assertFalse(fp.minutes_raised)
        # 比它短一档就会被上调
        fp_short = plan_frequency(self._p(minutes_per_session=m - 5), self.lib)
        self.assertTrue(fp_short.minutes_raised)


class TestPipeline(unittest.TestCase):

    def setUp(self):
        self.lib = ExerciseLibrary()

    def test_generate_plan_without_days(self):
        raw = {
            "gender": "M", "age": 28, "height_cm": 175.0, "weight_kg": 72.0,
            "level": "beginner", "goal": "hypertrophy",
            "minutes_per_session": 60, "equipment": ["dumbbell", "bodyweight"],
        }
        plan = generate_plan(raw, self.lib)
        self.assertEqual(plan["meta"]["version"], "1.3")
        self.assertEqual(len(plan["training"]["schedule"]), 7)
        fp = plan["training"]["frequency_plan"]
        self.assertIsNotNone(fp)
        self.assertIn(fp["days_per_week"], (3, 4))
        self.assertEqual(plan["profile"]["days_per_week"], fp["days_per_week"])

    def test_generate_plan_with_explicit_days(self):
        raw = {
            "gender": "F", "age": 30, "height_cm": 165.0, "weight_kg": 60.0,
            "level": "intermediate", "goal": "fat_loss", "days_per_week": 4,
            "minutes_per_session": 50, "equipment": ["dumbbell", "cable"],
        }
        plan = generate_plan(raw, self.lib)
        self.assertEqual(plan["profile"]["days_per_week"], 4)
        self.assertEqual(plan["training"]["frequency_plan"]["days_per_week"], 4)


if __name__ == "__main__":
    unittest.main()
