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

    def _fatloss_plan(self):
        return generate_plan({
            "gender": "F", "age": 30, "height_cm": 166.0, "weight_kg": 62.0,
            "level": "intermediate", "goal": "fat_loss",
            "minutes_per_session": 55, "equipment": ["dumbbell", "barbell"],
        })

    def _body(self, kgs, start=datetime.date(2026, 9, 1)):
        return [{"date": str(start + datetime.timedelta(days=7 * i)), "weight_kg": kg}
                for i, kg in enumerate(kgs)]

    def test_diet_kcal_down_when_loss_too_slow(self):
        p = self._fatloss_plan()
        body = self._body([62.0, 61.95, 61.9, 61.88, 61.85])  # ~-0.05kg/周，太慢
        out = run_check_in(p, _log(p, 4, 0.03), body, 0)
        rv = out["review"]
        self.assertEqual(rv["kcal_change"], -150)
        self.assertEqual(rv["next_raw"]["kcal_adjust"], -150)
        # 下一份计划热量确实降了
        self.assertLess(out["next_plan"]["nutrition"]["macros"]["daily_targets"]["kcal"],
                        p["nutrition"]["macros"]["daily_targets"]["kcal"])

    def test_diet_kcal_up_when_loss_too_fast(self):
        p = self._fatloss_plan()
        body = self._body([62.0, 61.3, 60.6, 59.9, 59.2])  # ~-0.7kg/周 ≈ -1.1%/周，太快
        out = run_check_in(p, _log(p, 4, 0.03), body, 0)
        self.assertEqual(out["review"]["kcal_change"], 150)

    def test_diet_hold_when_in_band_or_no_data(self):
        p = self._fatloss_plan()
        self.assertEqual(run_check_in(p, _log(p, 4, 0.03), [], 0)["review"]["kcal_change"], 0)
        body = self._body([62.0, 61.6, 61.2, 60.8, 60.4])  # -0.4kg/周 ≈ -0.65%/周，带内
        self.assertEqual(run_check_in(p, _log(p, 4, 0.03), body, 0)["review"]["kcal_change"], 0)

    def test_diet_adjust_accumulates_and_clamps(self):
        from engine.check_in_engine import _next_raw
        plan = {"profile": {"goal": "fat_loss", "kcal_adjust": -450, "equipment": []}}
        raw = _next_raw(plan, [], "hold", kcal_delta=-150)
        self.assertEqual(raw["kcal_adjust"], -500)  # 钳在 -500

    def test_bodyweight_progression_in_check_in(self):
        """居家用户做满徒手动作次数 → check-in 产出 bodyweight_progress，下一份计划变难。"""
        import datetime
        p = generate_plan({
            "gender": "M", "age": 25, "height_cm": 175.0, "weight_kg": 70.0,
            "level": "beginner", "goal": "hypertrophy", "minutes_per_session": 60,
            "equipment": ["bodyweight", "band", "pull_up_bar"],
        })
        sched = [s for s in p["training"]["schedule"] if s["type"] != "rest"]
        log = []
        d = datetime.date(2026, 9, 1)
        for _ in range(4):
            for s in sched:
                log.append({
                    "date": str(d), "plan_day": 1, "session_type": s["type"],
                    "planned_sets": 12, "aborted": False,
                    "exercises": [
                        {"exercise_id": e["exercise_id"], "planned_sets": e["sets"],
                         "sets": [{"reps": 12, "rir": 1} for _ in range(e["sets"])]}
                        for e in s["exercises"]
                    ],
                })
                d += datetime.timedelta(days=2)
        out = run_check_in(p, log, [], 0)
        bc = out["review"]["bodyweight_changes"]
        self.assertTrue(bc)  # 至少一个 movement_pattern +1
        self.assertTrue(all(v >= 1 for v in bc.values()))
        np_prof = out["next_plan"]["profile"]["bodyweight_progress"]
        self.assertTrue(np_prof)
        # 下一份计划里对应的自重锚定动作确实换难了
        old_first = sched[0]["exercises"][0]["exercise_id"]
        new_first = [s for s in out["next_plan"]["training"]["schedule"]
                     if s["type"] != "rest"][0]["exercises"][0]["exercise_id"]
        self.assertNotEqual(old_first, new_first)

    def test_bodyweight_rep_progress_counts_as_advance(self):
        """徒手用户次数逐周涨 → 阶段评估看到 e1RM 提升 → advance（不是减载重试）。"""
        import datetime
        from engine.load_planner import bodyweight_e1rm
        from engine.exercise_library import ExerciseLibrary
        lib = ExerciseLibrary()
        # 70kg 做 15 个标准俯卧撑 ≈ 67kg 等效卧推 e1RM
        v = bodyweight_e1rm(70.0, lib.get_by_id("push_up"), 15)
        self.assertIsNotNone(v)
        self.assertGreater(v, 50)

        p = generate_plan({
            "gender": "M", "age": 25, "height_cm": 175.0, "weight_kg": 70.0,
            "level": "beginner", "goal": "hypertrophy", "minutes_per_session": 60,
            "equipment": ["bodyweight", "band", "pull_up_bar"],
        })
        sched = [s for s in p["training"]["schedule"] if s["type"] != "rest"]
        log = []
        d = datetime.date(2026, 9, 1)
        for w in range(4):
            for s in sched:
                reps = 8 + w * 2   # 8 → 14
                log.append({
                    "date": str(d), "plan_day": 1, "session_type": s["type"],
                    "planned_sets": 12, "aborted": False,
                    "exercises": [
                        {"exercise_id": e["exercise_id"], "planned_sets": e["sets"],
                         "sets": [{"reps": reps, "rir": 2} for _ in range(e["sets"])]}
                        for e in s["exercises"]
                    ],
                })
                d += datetime.timedelta(days=2)
        out = run_check_in(p, log, [], 0)
        self.assertEqual(out["review"]["verdict"], "advance")

    def test_bodyweight_regress_below_bottom(self):
        from engine.check_in_engine import _bodyweight_changes
        from engine.exercise_library import ExerciseLibrary
        plan = {"stage_goal": {"baseline_lifts": [
            {"exercise_id": "push_up", "start_load_kg": None}]}}
        per_ex = {"push_up": {"consecutive_below_bottom": 2, "last_all_top_range": False}}
        d = _bodyweight_changes(plan, per_ex, ExerciseLibrary())
        self.assertEqual(d.get("horizontal_push"), -1)

    def test_fatloss_mesocycle_has_diet_break(self):
        p = self._fatloss_plan()
        deload = p["training"]["mesocycle"]["weeks"][-1]
        self.assertTrue(deload["diet_break"])
        self.assertEqual(deload["diet_kcal_delta"], 400)
        # 非减脂目标不给 diet break
        h = generate_plan({
            "gender": "M", "age": 28, "height_cm": 178.0, "weight_kg": 80.0,
            "level": "intermediate", "goal": "hypertrophy", "minutes_per_session": 75,
            "equipment": ["barbell", "dumbbell"],
        })
        self.assertFalse(h["training"]["mesocycle"]["weeks"][-1]["diet_break"])


if __name__ == "__main__":
    unittest.main()
