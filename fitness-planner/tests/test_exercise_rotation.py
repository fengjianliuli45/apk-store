"""任务 D：动作轮换 —— 锚定动作固定、辅助动作跨周期 / 同周内轮换。"""
import unittest
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).resolve().parent.parent))

from engine.profile_validator import validate
from engine.split_selector import select
from engine.schedule_planner import reschedule
from engine.exercise_library import ExerciseLibrary
from engine.session_builder import build_sessions
from engine.pipeline import generate_plan, run_check_in


def _sessions(off):
    raw = {
        "gender": "M", "age": 28, "height_cm": 178.0, "weight_kg": 80.0,
        "level": "intermediate", "goal": "hypertrophy", "days_per_week": 4,
        "minutes_per_session": 75, "equipment": ["barbell", "dumbbell", "cable", "machine"],
        "exercise_cycle_offset": off,
    }
    p = validate(raw)
    lib = ExerciseLibrary()
    split = reschedule(p, select(p))
    return build_sessions(p, split, lib)


def _anchors(sessions):
    """每节课每个肌群的第一个动作。"""
    out = {}
    for s in sessions:
        seen = set()
        for e in s.exercises:
            if e.target_muscle in seen:
                continue
            seen.add(e.target_muscle)
            out[(s.day, e.target_muscle)] = e.exercise_id
    return out


def _all_ids(sessions):
    return [[e.exercise_id for e in s.exercises] for s in sessions]


class TestExerciseRotation(unittest.TestCase):

    def test_anchors_fixed_accessories_rotate(self):
        s0, s1, s2 = _sessions(0), _sessions(1), _sessions(2)
        self.assertEqual(_anchors(s1), _anchors(s0))
        self.assertEqual(_anchors(s2), _anchors(s0))
        # 至少某一节课的动作序列变了
        self.assertNotEqual(_all_ids(s1), _all_ids(s0))

    def test_within_week_second_session_varies(self):
        # 某肌群一周练 2 次时，第 2 次的辅助动作应与第 1 次不同
        sessions = _sessions(0)
        by_muscle = {}
        for s in sessions:
            for e in s.exercises:
                by_muscle.setdefault(e.target_muscle, []).append((s.day, e.exercise_id))
        twice = {m: v for m, v in by_muscle.items()
                 if len({d for d, _ in v}) >= 2 and len(v) >= 3}
        self.assertTrue(twice, "测试前提：应有肌群一周练 ≥2 次且有辅助动作")
        for m, entries in twice.items():
            days = sorted({d for d, _ in entries})
            first_day, second_day = days[0], days[-1]
            first_ids = {i for d, i in entries if d == first_day}
            second_ids = {i for d, i in entries if d == second_day}
            self.assertNotEqual(first_ids, second_ids,
                                f"{m}: 两次训练动作完全相同，未轮换")

    def test_offset_clamped_and_in_output(self):
        p = generate_plan({
            "gender": "M", "age": 28, "height_cm": 178.0, "weight_kg": 80.0,
            "level": "intermediate", "goal": "hypertrophy", "minutes_per_session": 75,
            "equipment": ["barbell", "dumbbell"], "exercise_cycle_offset": 99,
        })
        self.assertEqual(p["profile"]["exercise_cycle_offset"], 12)  # 钳到 12

    def test_advance_bumps_offset_retry_does_not(self):
        plan = generate_plan({
            "gender": "M", "age": 28, "height_cm": 178.0, "weight_kg": 80.0,
            "level": "intermediate", "goal": "hypertrophy", "minutes_per_session": 75,
            "equipment": ["barbell", "dumbbell", "cable", "machine"],
            "strength_baseline": {
                "squat": {"weight_kg": 100, "reps": 5}, "bench": {"weight_kg": 70, "reps": 8},
                "hinge": {"weight_kg": 120, "reps": 5}, "row": {"weight_kg": 60, "reps": 10},
            },
        })
        self.assertEqual(plan["profile"]["exercise_cycle_offset"], 0)
        # 空日志 → 出勤不达标 → extend，不轮换
        out = run_check_in(plan, [], [], 0)
        self.assertEqual(out["review"]["next_raw"]["exercise_cycle_offset"], 0)


if __name__ == "__main__":
    unittest.main()
