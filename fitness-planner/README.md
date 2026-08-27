# fitness-planner（Python 权威源）

本目录是 [fengjianliuli45/fitness-planner](https://github.com/fengjianliuli45/fitness-planner) 引擎在 apk-store 的镜像，供对照与回归。

App 运行时用的是 `flutter/lib/planner/`（Dart 移植）。**改算法时先改本目录 Python，再同步 Dart。**

## 2026-08-23 容量修复

- `session_builder`：按真实周日程肌群频次回算组数 + 单次肌群上限 + 课时预算
- `progression_planner`：每 4 周减载（容量 60%）

## 2026-08-25 第一阶段适应期

- `stage_goal_planner`：把现有 4 周复评周期转成可验证的首阶段目标，默认要求 80% 场次、至少 3 个有效周和可比较测量。
- `stage_assessor`：以执行、数据质量、能力/身体趋势和安全四项规则判定 `achieved` 或延长 2 周。
- `response_profiler`：为后续宠物谱系积累训练响应；少于 2 个周期时，代谢、增肌和减脂响应强制保持 `unknown`。
- 计划 JSON 升级为 `1.1`，新增 `stage_goal`；Flutter `PlannerGateway` 同步生成相同结构。

阶段达成属于确定性规则层。后续垂直领域大模型可以负责问答、解释、语音陪伴和候选建议，但不能直接改写阶段结果；任何模型建议都必须转成可审计规则或由用户确认后再进入计划。

首发采用低阻力采集策略：训练表现数据由训练流程自动产生；体重、腰围、照片、体脂率和设备数据均为可选。阶段评估支持仅凭合格的执行数据与可复测训练表现达成，不得把身体测量作为隐性必填条件；数据不足时延长观察，不把用户标记为失败。
