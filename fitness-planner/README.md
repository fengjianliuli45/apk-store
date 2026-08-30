# fitness-planner（Python 权威源）

本目录是 [fengjianliuli45/fitness-planner](https://github.com/fengjianliuli45/fitness-planner) 引擎在 apk-store 的镜像，供对照与回归。

App 运行时用的是 `flutter/lib/planner/`（Dart 移植）。**改算法时先改本目录 Python，再同步 Dart。**

## 2026-08-23 容量修复

- `session_builder`：按真实周日程肌群频次回算组数 + 单次肌群上限 + 课时预算
- `progression_planner`：每 4 周减载（容量 60%）

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
