"""SchedulePlanner 测试：按肌群恢复窗口排日历。"""
import unittest
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).resolve().parent.parent))

from engine.profile_validator import validate
from engine.split_selector import select
from engine.schedule_planner import reschedule, RECOVERY_MIN_GAP
from engine.session_builder import SESSION_MUSCLES

BIG = ("quads", "hamstrings", "back", "chest")


def _muscle_days(schedule):
    md = {}
    for i, d in enumerate(schedule):
        if d["type"] == "rest":
            continue
        for m in SESSION_MUSCLES.get(d["type"], []):
            md.setdefault(m, []).append(i)
    return md


class TestSchedulePlanner(unittest.TestCase):

    def _sched(self, days, level="intermediate", goal="hypertrophy"):
        p = validate({
            "gender": "M", "age": 28, "height_cm": 175.0, "weight_kg": 75.0,
            "level": level, "goal": goal, "days_per_week": days,
            "minutes_per_session": 60, "equipment": ["barbell", "dumbbell", "cable", "machine"],
        })
        return reschedule(p, select(p)).weekly_schedule

    def _assert_recovery_ok(self, schedule):
        for m, dd in _muscle_days(schedule).items():
            if len(dd) < 2:
                continue
            dd = sorted(dd)
            gaps = [b - a for a, b in zip(dd, dd[1:])] + [dd[0] + 7 - dd[-1]]
            self.assertGreaterEqual(
                min(gaps), RECOVERY_MIN_GAP.get(m, 2),
                f"{m} 间隔 {gaps} 小于最小 {RECOVERY_MIN_GAP.get(m, 2)}",
            )

    def test_full_body_3_spaced(self):
        s = self._sched(3, level="beginner")
        train = [i for i, d in enumerate(s) if d["type"] != "rest"]
        self.assertEqual(len(train), 3)
        self._assert_recovery_ok(s)
        # 大肌群绝不连续两天
        self.assertGreaterEqual(min(b - a for a, b in zip(train, train[1:])), 2)

    def test_upper_lower_4_spaced(self):
        s = self._sched(4)
        self._assert_recovery_ok(s)

    def test_ppl_5_spaced(self):
        s = self._sched(5)
        self._assert_recovery_ok(s)

    def test_ppl_ppl_6_spaced(self):
        s = self._sched(6, level="advanced")
        self._assert_recovery_ok(s)

    def test_seven_days_all(self):
        s = self._sched(6, level="advanced")
        self.assertEqual(len(s), 7)
        self.assertEqual([d["day"] for d in s][0], "周一")


if __name__ == "__main__":
    unittest.main()
