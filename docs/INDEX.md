# Stopwatch 文档索引

> 状态：现行文档入口
> 更新日期：2026-09-02
> 规则：发生冲突时，按 L0 → L1 → L2 → L3 → L4 的顺序采用；同层级以更新日期和明确的替代声明为准。

## L0 冻结决策

- [`PRODUCT_BASELINE_2026-08-25.md`](PRODUCT_BASELINE_2026-08-25.md)：首发产品基线与 `FZ-01`～`FZ-06` 冻结登记。其他文档不得静默覆盖其中的业务语义。

## L1 最终产品与设计规范

- [`PRODUCT_DESIGN_SPEC_V1.md`](PRODUCT_DESIGN_SPEC_V1.md)：V1 工作草案；0.3 已加入 `main@6b4739b` 规划引擎、周期复评、计划版本和同步状态的 Flutter 实现与模拟器验收记录，其他逐屏设计完成后升级为正式版本。

## L2 现行实施说明

- [`../README.md`](../README.md)：仓库入口与当前主线概览。
- [`../fitness-planner/README.md`](../fitness-planner/README.md)：Python 规划引擎权威实现及 Flutter 同步边界。
- [`fitness-planner-data/README.md`](fitness-planner-data/README.md)：动作与 GIF 数据说明。
- [`../flutter/README.md`](../flutter/README.md)：Flutter 客户端启动、验证与目录说明。
- [`HANDOFF_2026-08-27.md`](HANDOFF_2026-08-27.md)：当前跨设备交接状态、验证结果和继续工作顺序。
- [`MALE_COACH_ASSET_AUDIT_2026-08-27.md`](MALE_COACH_ASSET_AUDIT_2026-08-27.md)：男性教练资产、P0 动作链路、发布阻塞项与女性教练补齐门槛。
- [`EMBEDDED_3D_RUNTIME_SOLUTION_2026-08-27.md`](EMBEDDED_3D_RUNTIME_SOLUTION_2026-08-27.md)：Flutter 主壳、Unity 全屏训练、GLB 轻量预览、启动生命周期和 Bridge 的现行实施方案。

## L3 待办与分支材料

- [`ISSUES.md`](ISSUES.md)：尚未处理问题的排期来源，不构成产品决策。
- `../Stopwatch后端架构与Docker部署方案.docx`：后端分支方案，尚未与 `FZ-04` 的同步契约逐项核对，不作为首发权威依据。
- `design-prototypes/training-home-effects/`：训练首页网页视觉原型和 QA 证据，仅供设计追溯。
- `Stopwatch-Unity-P0-Figma-Make-design-spec.md`、`Stopwatch-Full-App-Figma-Make-design-spec.md`、`specs/` 与 `inspirations/`：远端上传的设计/灵感资料；合并后逐份核对，未经确认不覆盖 L0/L1。

## L4 历史归档

- [`Stopwatch-app-design-blueprint-v2.md`](Stopwatch-app-design-blueprint-v2.md)：旧产品、交互与 Kotlin Multiplatform 架构蓝图。
- [`FEATURE_PLAN.md`](FEATURE_PLAN.md)：2026-08-19 早期实施计划；已完成与失效内容未持续更新，其中 Unity 普通 Flutter Widget 内嵌方案已由 `EMBEDDED_3D_RUNTIME_SOLUTION_2026-08-27.md` 替代。
- [`../fitness-planner/REVIEW.md`](../fitness-planner/REVIEW.md)：2026-08-02 引擎审查快照，测试数量和部分缺口已过时。

## 整理规则

1. 新文档必须在本索引登记层级、状态、适用范围和替代关系。
2. 研究记录、截图、灵感和分支方案默认属于 L3，未经确认不得成为产品基线。
3. 历史文件保留原路径，避免破坏代码和外部链接；最终设计稿定型并修复引用后，再统一迁入 `docs/archive/`。
4. 不删除含有决策历史的文档；物理归档前先确认仍被引用的位置。
5. L1/L2 文档如与 L0 冲突，必须修改自身或发起解冻，不得用“更新时间更晚”自动覆盖冻结项。
