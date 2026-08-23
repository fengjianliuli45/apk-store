# fitness-planner（Python 权威源）

本目录是 [fengjianliuli45/fitness-planner](https://github.com/fengjianliuli45/fitness-planner) 引擎在 apk-store 的镜像，供对照与回归。

App 运行时用的是 `flutter/lib/planner/`（Dart 移植）。**改算法时先改本目录 Python，再同步 Dart。**

## 2026-08-23 容量修复

- `session_builder`：按真实周日程肌群频次回算组数 + 单次肌群上限 + 课时预算
- `progression_planner`：每 4 周减载（容量 60%）
