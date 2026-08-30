"""闭环测试：progress_tracker + check_in_engine + run_check_in。"""
import unittest
import sys
import datetime
sys.path.insert(0, str(__import__('pathlib').Path(__file__).resolve().parent.parent))

from engine.pipeline import generate_plan, run_check_in
from engine.progress_tracker import epley_e1rm, aggregate_evidence


def _plan():
    return generate_plan({
        "gender": "M", "age": 28, "height_cm": 178.0, "weight_kg": 80.0,
        "level": "intermediate", "goal": "hypertrophy", "minutes_per_session": 75,
        "equipment": ["barbell", "dumbbell", "cable", "machine"],
        "strength_baseline": {
            "squat": {"weight_kg": 100, "reps": 5}, "bench": {"weight_kg": 70, "reps": 8},
            "hinge": {"weight_kg": 120, "reps": 5}, "row": {"weight_kg": 60, "reps": 10},
        },
    })


def _log(plan, weeks=4, progress=0.06, adherence=1.0, pain_last=False):
    sched = [s for s in plan["training"]["schedule"] if s["type"] != "rest"]
    out = []
    start = datetime.date(2026, 9, 1)
    for w in range(weeks):
        for di, s in enumerate(sched):
            if adherence < 1.0 and ((w * len(sched) + di) % 3 == 0):
                continue
            dt = start + datetime.timedelta(days=w * 7 + di * 2)
            exs = []
            for e in s["exercises"]:
                kg = (e["load_kg"] * (1 + progress * w / weeks)) if e["load_kg"] else None
                exs.append({
                    "exercise_id": e["exercise_id"], "planned_sets": e["sets"],
                    "sets": [{"reps": 12, "weight_kg": round(kg, 1) if kg else None, "rir": 1}
                             for _ in range(e["sets"])],
                })
            out.append({
                "date": dt.isoformat(), "plan_day": s["day"], "session_type": s["type"],
                "planned_sets": s["total_sets"], "exercises": exs, "aborted": False,
                "pain_flag": pain_last and w == weeks - 1 and di >= len(sched) - 1,
            })
    return out


class TestClosedLoop(unittest.TestCase):

    def test_epley_rir(self):
        self.assertEqual(epley_e1rm(100, 5, 0), 116.7)
        self.assertEqual(epley_e1rm(100, 3, 2), epley_e1rm(100, 5, 0))
        self.assertIsNone(epley_e1rm(100, 5, 5))   # RIR>3 不可信

    def test_evidence_aggregation(self):
        p = _plan()
        ev = aggregate_evidence(p, _log(p, 4, 0.06), [])
        self.assertGreaterEqual(ev.completed_sessions, 12)
        self.assertGreaterEqual(ev.active_weeks, 3)
        self.assertGreaterEqual(ev.comparable_measurements, 2)
        self.assertGreaterEqual(ev.performance_improvement_pct, 2.5)

    def test_advance_when_progressed(self):
        p = _plan()
        out = run_check_in(p, _log(p, 4, 0.06), [], 0)
        r = out["review"]
        self.assertEqual(r["verdict"], "advance")
        self.assertEqual(r["volume_change"], "up_one_step")
        self.assertTrue(r["load_changes"])
        self.assertEqual(r["unlock_reward"], "pet_hatchling")
        self.assertIsNotNone(out["next_plan"])
        # 下一个计划容量更高
        self.assertEqual(out["next_plan"]["profile"].get("volume_cycle_offset"), 1)

    def test_extend_when_missed_sessions(self):
        p = _plan()
        out = run_check_in(p, _log(p, 2, 0.03), [], 0)
        self.assertEqual(out["review"]["verdict"], "extend")
        self.assertGreater(out["review"]["makeup_sessions"], 0)

    def test_deload_when_stalled(self):
        p = _plan()
        out = run_check_in(p, _log(p, 4, 0.0), [], 0)
        self.assertEqual(out["review"]["verdict"], "deload_then_retry")
        self.assertEqual(out["review"]["volume_change"], "down_10pct")

    def test_address_safety_on_recent_pain(self):
        p = _plan()
        out = run_check_in(p, _log(p, 4, 0.06, pain_last=True), [], 0)
        self.assertEqual(out["review"]["verdict"], "address_safety")
        self.assertIsNone(out["next_plan"])

    def test_next_raw_1rm_scales_with_main_lift(self):
        p = _plan()
        out = run_check_in(p, _log(p, 4, 0.06), [], 0)
        sb = out["review"]["next_raw"].get("strength_baseline", {})
        base_bench = p["profile"]["one_rm_estimates"]["bench"]["kg"]
        self.assertGreater(sb["bench"]["one_rm_kg"], base_bench)
        self.assertLess(sb["bench"]["one_rm_kg"], base_bench * 1.1)  # 合理增幅


if __name__ == "__main__":
    unittest.main()
