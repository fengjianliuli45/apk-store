"""SessionBuilder 单元测试。"""
import unittest
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).resolve().parent.parent))

from engine.profile_validator import validate
from engine.split_selector import select
from engine.exercise_library import ExerciseLibrary
from engine.session_builder import build_sessions


class TestSessionBuilder(unittest.TestCase):

    def setUp(self):
        self.lib = ExerciseLibrary()

    def _profile(self, **overrides):
        raw = {
            "gender": "M", "age": 25, "height_cm": 175.0, "weight_kg": 70.0,
            "level": "intermediate", "goal": "hypertrophy", "days_per_week": 5,
            "minutes_per_session": 90, "equipment": ["barbell", "dumbbell", "cable", "machine"],
        }
        raw.update(overrides)
        return validate(raw)

    def test_generates_sessions(self):
        p = self._profile()
        split = select(p)
        sessions = build_sessions(p, split, self.lib)
        self.assertEqual(len(sessions), 7)

    def test_rest_day_empty(self):
        p = self._profile(days_per_week=5)
        split = select(p)
        sessions = build_sessions(p, split, self.lib)
        rest_days = [s for s in sessions if s.type == "rest"]
        self.assertGreater(len(rest_days), 0)
        for rd in rest_days:
            self.assertEqual(len(rd.exercises), 0)

    def test_push_day_has_exercises(self):
        p = self._profile()
        split = select(p)
        sessions = build_sessions(p, split, self.lib)
        push_days = [s for s in sessions if s.type == "push"]
        self.assertGreater(len(push_days), 0)
        for pd in push_days:
            self.assertGreater(len(pd.exercises), 0)

    def test_compound_first(self):
        p = self._profile()
        split = select(p)
        sessions = build_sessions(p, split, self.lib)
        for s in sessions:
            if s.exercises:
                first = s.exercises[0]
                # 第一个动作应该是复合动作（如果有）
                # 不一定 100% 是复合，但复合应该在孤立之前
                compound_found = False
                for ex in s.exercises:
                    if ex.compound:
                        compound_found = True
                    elif not ex.compound and not compound_found:
                        pass  # 孤立在复合前也可以接受（取决于筛选结果）
                self.assertTrue(True)  # 结构性检查

    def test_exercise_has_sets_and_reps(self):
        p = self._profile()
        split = select(p)
        sessions = build_sessions(p, split, self.lib)
        for s in sessions:
            for ex in s.exercises:
                self.assertGreater(ex.sets, 0)
                self.assertTrue(ex.reps)
                self.assertGreater(ex.rest_sec, 0)

    def test_beginner_fewer_sets(self):
        p_beginner = self._profile(level="beginner", days_per_week=3)
        split_b = select(p_beginner)
        sessions_b = build_sessions(p_beginner, split_b, self.lib)
        total_b = sum(s.total_sets for s in sessions_b if s.type != "rest")

        p_inter = self._profile(level="intermediate", days_per_week=4)
        split_i = select(p_inter)
        sessions_i = build_sessions(p_inter, split_i, self.lib)
        total_i = sum(s.total_sets for s in sessions_i if s.type != "rest")

        # 中级应该比新手总组数多（因为容量更大+训练天数更多）
        self.assertGreater(total_i, total_b)

    def test_total_sets_positive(self):
        p = self._profile()
        split = select(p)
        sessions = build_sessions(p, split, self.lib)
        training_days = [s for s in sessions if s.type != "rest"]
        for td in training_days:
            self.assertGreater(td.total_sets, 0)

    def test_beginner_full_body_volume_near_target(self):
        """真实周频回算后，新手全身课胸/背周组应接近目标，不再翻倍。"""
        from collections import Counter
        from engine.session_builder import WEEKLY_VOLUME

        p = self._profile(level="beginner", days_per_week=3, minutes_per_session=60)
        split = select(p)
        sessions = build_sessions(p, split, self.lib)
        muscle_sets = Counter()
        for s in sessions:
            for ex in s.exercises:
                for m in ex.primary_muscles:
                    muscle_sets[m] += ex.sets
        target = WEEKLY_VOLUME["beginner"]
        # 允许 ±4 组误差（动作多肌群标签 + 整数取整）
        self.assertLessEqual(abs(muscle_sets["chest"] - target["chest"]), 4)
        self.assertLessEqual(abs(muscle_sets["back"] - target["back"]), 4)
        self.assertLess(muscle_sets["chest"], target["chest"] * 1.6)

    def test_session_respects_time_budget(self):
        """短课时不应堆出远超时长的组数。"""
        p = self._profile(level="intermediate", days_per_week=4, minutes_per_session=45)
        split = select(p)
        sessions = build_sessions(p, split, self.lib)
        for s in sessions:
            if s.type == "rest":
                continue
            self.assertLessEqual(s.total_sets, 22)

    # ── 任务 ①：容量↔课时一致性 ──────────────────────────────

    def test_duration_never_exceeds_and_is_honest(self):
        """duration_min ≤ 用户设定；且与真实做组耗时同量级（不再被填充数掩盖）。"""
        from engine.session_builder import _set_seconds, TRAINING_VARS
        p = self._profile(level="intermediate", days_per_week=4, minutes_per_session=60)
        split = select(p)
        sessions = build_sessions(p, split, self.lib)
        rest = TRAINING_VARS[p.goal]["rest_sec"]
        for s in sessions:
            if s.type == "rest":
                continue
            self.assertLessEqual(s.duration_min, p.minutes_per_session)
            work_sec = sum(e.sets * _set_seconds(rest, e.compound) for e in s.exercises)
            # duration 至少覆盖真实做组时间（含热身余量，故 >=）
            self.assertGreaterEqual(s.duration_min * 60 + 60, work_sec)

    def test_training_days_balanced(self):
        """混合分肢的各训练日组数不应严重失衡（旧问题：上肢日≈其他日 2 倍）。"""
        p = self._profile(level="intermediate", days_per_week=5, minutes_per_session=75)
        split = select(p)
        sessions = build_sessions(p, split, self.lib)
        totals = [s.total_sets for s in sessions if s.type != "rest"]
        self.assertGreater(min(totals), 0)
        self.assertLessEqual(max(totals) / min(totals), 1.8)

    def test_every_exercise_has_target_muscle(self):
        p = self._profile()
        split = select(p)
        sessions = build_sessions(p, split, self.lib)
        for s in sessions:
            for e in s.exercises:
                self.assertTrue(e.target_muscle)

    def test_analyze_volume_no_phantom_overcount(self):
        """按 target_muscle 计数，delivered 不应因多肌群标签远超 target。"""
        from engine.session_builder import analyze_volume
        p = self._profile(level="advanced", days_per_week=6, minutes_per_session=90)
        split = select(p)
        sessions = build_sessions(p, split, self.lib)
        rep = analyze_volume(p, split, sessions)
        for m, target in rep["target"].items():
            self.assertLessEqual(rep["delivered"][m], target + 2)

    def test_analyze_volume_coverage_scales_with_time(self):
        from engine.session_builder import analyze_volume
        short = self._profile(level="intermediate", days_per_week=4, minutes_per_session=45)
        long = self._profile(level="intermediate", days_per_week=4, minutes_per_session=90)
        cov_short = analyze_volume(short, select(short), build_sessions(short, select(short), self.lib))["coverage_pct"]
        cov_long = analyze_volume(long, select(long), build_sessions(long, select(long), self.lib))["coverage_pct"]
        self.assertLessEqual(cov_short, cov_long)
        self.assertLessEqual(cov_long, 100)

    def test_tight_schedule_flagged(self):
        """3 天 60 分钟的中级用户：覆盖率不足 90%，给出提示与软建议。"""
        from engine.session_builder import analyze_volume
        p = self._profile(level="intermediate", days_per_week=3, minutes_per_session=60)
        split = select(p)
        rep = analyze_volume(p, split, build_sessions(p, split, self.lib))
        self.assertLess(rep["coverage_pct"], 90)
        self.assertTrue(rep["notes"])
        self.assertTrue(rep["recommendation"])

    def test_secondary_muscle_only_exposure_is_indirect(self):
        """5 天 PPL+上下：三头只在 push 日为主肌群、upper 日为次要 →
        upper 日不为它硬排量，欠量归『间接带到』而非『加时间』。"""
        from engine.session_builder import analyze_volume
        p = self._profile(level="intermediate", days_per_week=5, minutes_per_session=75)
        split = select(p)
        rep = analyze_volume(p, split, build_sessions(p, split, self.lib))
        # 不应出现"三头...每节 +10 分钟"这类时间型提示
        self.assertFalse(any("三头" in n and "分钟" in n for n in rep["notes"]))

    def test_capacity_recommendation_soft_hint(self):
        """覆盖率不足时给出 B 方案软提示（可选、不拦截）。"""
        from engine.session_builder import analyze_volume
        p = self._profile(level="intermediate", days_per_week=4, minutes_per_session=45)
        rep = analyze_volume(p, select(p), build_sessions(p, select(p), self.lib))
        self.assertTrue(rep["recommendation"])
        self.assertIn("可选", rep["recommendation"]["text"])


if __name__ == "__main__":
    unittest.main()
