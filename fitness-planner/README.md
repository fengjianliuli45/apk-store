# fitness-planner（Python 权威源）

本目录是 [fengjianliuli45/fitness-planner](https://github.com/fengjianliuli45/fitness-planner) 引擎在 apk-store 的镜像，供对照与回归。

App 运行时用的是 `flutter/lib/planner/`（Dart 移植）。**改算法时先改本目录 Python，再同步 Dart。**

## 2026-08-23 容量修复

- `session_builder`：按真实周日程肌群频次回算组数 + 单次肌群上限 + 课时预算
- `progression_planner`：每 4 周减载（容量 60%）

## 2026-08-30 起始重量 / 1RM（任务 ②）

- 新增 `engine/load_planner.py`：把「65-80% 1RM」转成具体重量。
  - onboarding 混合采集：`strength_baseline = {squat|bench|hinge|row: {weight_kg, reps} 或 {one_rm_kg}}`。
    有器械填一组估测 → Epley 反推 1RM；做不了/不确定/徒手 → 留空，首周按 RPE 找重量。
  - 每个动作标「基准 + 系数」（`_PATTERN_BASIS` + `_EXERCISE_COEF`，哑铃按每只手）：
    建议重量 = 基准 1RM × 系数 × 目标 %1RM，取整 2.5kg。
  - `ExerciseEntry.load` 从「65-80% 1RM」变「52.5 kg（65-80% 1RM）」/「27.5 kg/只（…）」/
    「首周按 RPE 找重量」/「自重（按次数 / 难度递进）」；新增数值字段 `load_kg`。
- `profile.strength_baseline` + `profile.one_rm_estimates`（Epley 结果）进 JSON。
- `stage_goal.baseline_lifts`：挑计划里前几个复合动作作为「标准化测试动作」，
  带首周基线负荷，供阶段达成对比。
- 徒手用户的渐进（加次数 → 换更难变式）是单独子任务，本次未做。
- 计划 JSON `1.5 → 1.6`。

## 2026-08-30 自适应训练量 + 按恢复排日历（交付 2b）

- **训练量目标自适应**（`analyze_volume`）：目标不再是固定表，而是「用户这个时长/天数
  排得满的量」，夹在 [MEV, MAV] 之间。只要每个肌群 ≥ MEV（`MEV_WEEKLY`），计划就
  科学完整（一定长肌肉）→ `volume_coverage_pct` 通常 100。另给 `vs_optimal_pct`
  （相当于最优训练量 MAV 的百分比），是「还能更好，加时间往上推」的提示。
- `_distribute_weekly`：周目标小的时候宁可少练几次、每次 ≥2 组（`5/3 → [3,2,0]`），
  不排「1 组」的无效暴露。
- **频率决策**改为优化 `vs_optimal_pct`：给定时长，挑「最少的、能到最优」的天数；
  没有能到最优的选最接近的。`min_session_minutes` 仍以「每个肌群 ≥ MEV」为门槛
  （= 保证训练量完成的最短课时）。
- 新增 `engine/schedule_planner.py`：`split_selector` 只定训练日**类型序列**，
  schedule_planner 按肌群恢复窗口（`RECOVERY_MIN_GAP`：大肌群绝不连续两天）
  枚举所有摆法，挑间隔最均匀、周末最轻的。删掉 `full_body_4` 模板；新手锁 3 天。
- `recovery_planner`：完全休息天数按水平（新手 2 / 中高级 1），但让位给减脂的有氧日
  和增肌欠量的泵感课日。
- 计划 JSON `1.4 → 1.5`：`training` 下 `weekly_volume_target`（自适应）/
  `weekly_volume_optimal`（MAV）/ `vs_optimal_pct`；`frequency_plan` 增 `vs_optimal_pct`。

## 2026-08-30 休息日轻日 / 补练（交付 2）

- 新增 `engine/recovery_planner.py`：把日程里的 rest 日填成有内容的「轻日」，
  原则是**不抢主课的恢复**：
  - 减脂 → 补低强度有氧（Zone2）：减脂靠热量缺口，有氧直接补。
  - 增肌 / 增肌减脂 且主课覆盖 < 96% 且非新手 → 补 1 天「快恢复肌群泵感课」
    （二头/三头/小腿/核心，20 分钟，24 小时恢复，不影响第二天大动作）。
  - 新手 → rest 日只给主动恢复（拉伸 + 走路）。
  - rest 日 ≥ 2 或硬练 ≥ 5 天 → 保留 1 天完全休息。
  - 其余 rest 日 → 主动恢复。每天都有内容 → 服务「每天开 App / 连续天数 / 宠物」。
- 计划 JSON `1.3 → 1.4`：`training.recovery_days`（`kind` = rest/mobility/cardio/pump，
  `duration_min` / `title` / `focus` / `items`）。`schedule` 仍是 7 天（rest 保持 rest），
  App 按 `day` 把两者对起来渲染。
- 泵感课不计入 `volume_coverage_pct`（覆盖率只反映主课）；泵感课的 `focus` 文案
  会说明它在补哪部分缺口。
- 7 天训练 = 硬练（3–6 天）+ 轻日填满剩余天，不做 7 天硬练同肌群。

## 2026-08-30 引擎决定训练频率（任务 ①.5）

- `days_per_week` 不再是必填输入。用户只填「每次能练多久」，频率是结果：
  `frequency_planner.plan_frequency()` 在该水平允许的天数范围内（新手 3–4、
  中级 3–5、高级 3–6），挑**最少的、覆盖率 ≥ 92% 的天数**。
- 低于「最低训练时长」→ 自动上调时长（科学优先：先保证周训练量）。
  最低时长按 (水平, 目标, 器械) 用真实引擎搜索得出，例：增肌 新手 ~50–65 / 中级 ~65–70 分钟。
- `WEEKLY_VOLUME` 按目标缩放（`weekly_volume_for(level, goal)`）：
  增肌 1.0 / 增肌减脂 0.9 / 减脂 0.85 / 力量 0.85。高级基准容量下调一档，
  高级单次上限 10→12，力量 `sets_range` (4,5)→(3,5)。
- 新增 `split_selector` 的 `full_body_4` 模板：新手 4 天仍走全身。
- 新增 `engine/pipeline.generate_plan(raw, library)` 一站式编排入口，
  内含 `frequency_planner.resolve`。测试与 Flutter `PlannerGateway` 对齐此顺序。
- 计划 JSON `1.2 → 1.3`：`training.frequency_plan`（天数 / 上调后的时长 /
  最低时长 / 覆盖率 / 说明）。`profile.days_per_week` 可为 null（未解析时）。

## 2026-08-30 容量↔课时一致性（任务 ①：科学健身优先）

- `session_builder` 重写容量与排课：
  - 单组耗时改真实估计（复合 55s + 处方休息×1.4，孤立 35s + 处方休息，另按大肌群数扣热身时间）。`duration_min` 现在是诚实值。
  - 周目标按「实际训练频率」整除铺到每次暴露，前重后轻，各次封顶到单次上限（`MAX_SETS_PER_MUSCLE_SESSION` 调整为 6 / 9 / 10）。
  - 两遍排课：先每个主肌群保底 1 个动作，再补深度，最后补次要肌群。`upper` 日把二头/三头降为次要肌群（`SECONDARY_MUSCLES_BY_TYPE`），复合动作间接带到。
  - 每个 `ExerciseEntry` 记 `target_muscle`，容量统计不再被复合动作多肌群标签灌水。
- `session_builder.analyze_volume()`（新）：对比周目标 vs 实际排出容量，输出 `coverage_pct` + 差额提示 + B 方案软提示（可选、不拦截）。
- `split_selector`：3 天训练一律全身分肢（各水平），比 3 天 PPL（每肌群 1 次/周）显著更能兑现周容量。
- 计划 JSON 升级为 `1.2`：`training` 下新增 `weekly_volume_delivered` / `volume_coverage_pct` / `volume_notes` / `capacity_recommendation`。Dart `PlannerGateway` 同步（Python↔Dart 逐画像输出已对拍一致）。
- 训练量不达标的「补训 / 延长训练周期」联动属确定性规则，接入闭环时在 `stage_assessor` / check-in 落地（任务 A）。

## 2026-08-25 第一阶段适应期

- `stage_goal_planner`：把现有 4 周复评周期转成可验证的首阶段目标，默认要求 80% 场次、至少 3 个有效周和可比较测量。
- `stage_assessor`：以执行、数据质量、能力/身体趋势和安全四项规则判定 `achieved` 或延长 2 周。
- `response_profiler`：为后续宠物谱系积累训练响应；少于 2 个周期时，代谢、增肌和减脂响应强制保持 `unknown`。
- 计划 JSON 升级为 `1.1`，新增 `stage_goal`；Flutter `PlannerGateway` 同步生成相同结构。

阶段达成属于确定性规则层。后续垂直领域大模型可以负责问答、解释、语音陪伴和候选建议，但不能直接改写阶段结果；任何模型建议都必须转成可审计规则或由用户确认后再进入计划。

首发采用低阻力采集策略：训练表现数据由训练流程自动产生；体重、腰围、照片、体脂率和设备数据均为可选。阶段评估支持仅凭合格的执行数据与可复测训练表现达成，不得把身体测量作为隐性必填条件；数据不足时延长观察，不把用户标记为失败。
