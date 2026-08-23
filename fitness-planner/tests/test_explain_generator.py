"""ExplainGenerator 单元测试。"""
import unittest
import sys
sys.path.insert(0, str(__import__('pathlib').Path(__file__).resolve().parent.parent))

from engine.profile_validator import validate
from engine.tdee_calculator import calculate
from engine.macro_allocator import allocate
from engine.split_selector import select
from engine.progression_planner import plan
from engine.explain_generator import explain


class TestExplainGenerator(unittest.TestCase):

    def _build_pipeline(self, **overrides):
        raw = {
            "gender": "M", "age": 25, "height_cm": 175.0, "weight_kg": 70.0,
            "level": "intermediate", "goal": "hypertrophy", "days_per_week": 5,
            "minutes_per_session": 90, "equipment": ["barbell", "dumbbell"],
            "meals_per_day": 5,
        }
        raw.update(overrides)
        p = validate(raw)
        tdee = calculate(p)
        macros = allocate(p, tdee)
        split = select(p)
        prog = plan(p)
        return p, tdee, macros, split, prog

    # ── 冒烟测试 ──────────────────────────────────────────

    def test_smoke_does_not_crash(self):
        """完整管线调用 explain 不报错。"""
        p, tdee, macros, split, prog = self._build_pipeline()
        text = explain(p, tdee, macros, split, prog)
        self.assertIsInstance(text, str)
        self.assertGreater(len(text), 100)

    def test_smoke_beginner(self):
        """新手级别不崩溃。"""
        p, tdee, macros, split, prog = self._build_pipeline(level="beginner", days_per_week=3)
        text = explain(p, tdee, macros, split, prog)
        self.assertIsInstance(text, str)

    def test_smoke_fat_loss(self):
        """减脂目标不崩溃。"""
        p, tdee, macros, split, prog = self._build_pipeline(goal="fat_loss")
        text = explain(p, tdee, macros, split, prog)
        self.assertIsInstance(text, str)

    def test_smoke_with_body_fat(self):
        """提供体脂率（Katch-McArdle 路径）不崩溃。"""
        p, tdee, macros, split, prog = self._build_pipeline(body_fat_pct=15.0)
        text = explain(p, tdee, macros, split, prog)
        self.assertIsInstance(text, str)

    def test_smoke_female(self):
        """女性用户不崩溃。"""
        p, tdee, macros, split, prog = self._build_pipeline(gender="F", weight_kg=55.0)
        text = explain(p, tdee, macros, split, prog)
        self.assertIsInstance(text, str)

    # ── 关键中文内容 ──────────────────────────────────────

    def test_contains_chinese_keywords(self):
        """输出包含核心中文关键词。"""
        p, tdee, macros, split, prog = self._build_pipeline()
        text = explain(p, tdee, macros, split, prog)
        for keyword in ["健身", "热量", "蛋白质", "训练", "渐进"]:
            self.assertIn(keyword, text, f"输出中缺少关键词: {keyword}")

    def test_contains_bmr_tdee(self):
        """输出包含 BMR 和 TDEE 数值。"""
        p, tdee, macros, split, prog = self._build_pipeline()
        text = explain(p, tdee, macros, split, prog)
        self.assertIn("BMR", text)
        self.assertIn("TDEE", text)

    def test_contains_split_info(self):
        """输出包含训练分肢信息。"""
        p, tdee, macros, split, prog = self._build_pipeline()
        text = explain(p, tdee, macros, split, prog)
        self.assertIn(split.split_name, text)
        self.assertIn("周一", text)
        self.assertIn("周日", text)

    def test_contains_progression_info(self):
        """输出包含渐进超负荷信息。"""
        p, tdee, macros, split, prog = self._build_pipeline()
        text = explain(p, tdee, macros, split, prog)
        self.assertIn("双进阶", text)
        self.assertIn("渐进超负荷", text)

    def test_contains_evidence_pmids(self):
        """输出包含论文 PMID 引用。"""
        p, tdee, macros, split, prog = self._build_pipeline()
        text = explain(p, tdee, macros, split, prog)
        self.assertIn("PMID", text)
        self.assertIn("论文依据", text)

    # ── 边界输入 ──────────────────────────────────────────

    def test_edge_days_zero(self):
        """days_per_week=0 不崩溃。"""
        p, tdee, macros, split, prog = self._build_pipeline(days_per_week=0)
        text = explain(p, tdee, macros, split, prog)
        self.assertIsInstance(text, str)

    def test_edge_minimal_session(self):
        """minutes_per_session=0 不崩溃。"""
        p, tdee, macros, split, prog = self._build_pipeline(minutes_per_session=0)
        text = explain(p, tdee, macros, split, prog)
        self.assertIsInstance(text, str)

    def test_edge_strength_goal(self):
        """力量目标不崩溃。"""
        p, tdee, macros, split, prog = self._build_pipeline(goal="strength")
        text = explain(p, tdee, macros, split, prog)
        self.assertIsInstance(text, str)

    def test_edge_recomposition(self):
        """重组目标不崩溃。"""
        p, tdee, macros, split, prog = self._build_pipeline(goal="recomposition")
        text = explain(p, tdee, macros, split, prog)
        self.assertIsInstance(text, str)

    def test_output_has_separator_lines(self):
        """输出包含分隔线（结构完整性）。"""
        p, tdee, macros, split, prog = self._build_pipeline()
        text = explain(p, tdee, macros, split, prog)
        self.assertIn("=" * 60, text)


if __name__ == "__main__":
    unittest.main()
