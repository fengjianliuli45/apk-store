# 动作闭环 V1 实施说明（2026-09-10）

## 目标与基准

本轮以仓库 `main@9af3e2c` 中的规划引擎 1.8 和 154 条动作目录为权威基准，解决“计划有处方、训练只记总组数、复评拿不到真实证据”的断链。实施分支为 `feat/exercise-closed-loop-v1`，可直接回到该基准提交撤销本轮修改。

## 已完成

- Python 权威动作目录与 Flutter 内置目录保持逐项一致：154 个动作、15 种动作模式、ID 唯一。
- 清理 `variations` 和 `alternatives_if_injured` 中 15 个无对应动作的悬空引用，并增加自动完整性测试，防止两个目录再次漂移。
- 训练队列不再丢弃引擎处方；每组保留原始次数区间、文字负荷、建议公斤数、目标 RPE、节奏、备注、动作提示、目标肌群和动作内组号。
- 本地训练数据库升级为 schema v4，逐组保存实际次数、实际重量、RIR、实际 RPE、疼痛标记/部位、有效时长以及对应计划处方；会话保存训练类型、计划日、整体疼痛和恢复评分。
- 中断恢复会同时恢复完整处方与已完成组证据，不把已完成内容降级成聚合统计。
- Flutter 降级训练页在“完成这组”时提供低阻力记录层：实际次数、重量、RIR、疼痛和末组恢复评分均可选填。
- Unity Bridge 的 `complete_set` / `end_session` 同时接受 camelCase 与 snake_case 证据字段；Flutter 发往 Unity 的快照增加计划负荷、目标 RPE、节奏和动作提示。
- 本机独立 Unity 工程已增加“完成本组”证据层；最后一次计数会先进入确认层，避免自动完成绕过记录。空重量、RIR、RPE 和恢复使用 `-1` 作为仅限传输层的未知哨兵，Flutter 会丢弃而不是误存为 0。
- 已用 Unity 6000.5.4f1 图形 Editor 重新导出 Activity 入口 Android Library，同步到 Flutter Android 工程，并成功构建只含 `arm64-v8a` 的集成 Debug APK。APK 内已核实包含 `libunity.so`、`libil2cpp.so`、`libmain.so` 和 `libsqlite3.so`。
- `WorkoutLogEntry` 增加结构化动作/组记录并保持旧日志向后兼容。规划复评优先消费真实动作 ID 和逐组证据；只有旧记录继续使用 `aggregate_log`，且不会伪造重量或 RIR。
- 四种确定性复评结果 `advance`、`extend`、`deload_then_retry`、`address_safety` 已改为通过 App 的结构化训练日志模型进入引擎测试。

## 数据边界

Unity 完成本组事件建议发送：

```json
{
  "actual_reps": 10,
  "weight_kg": 62.5,
  "rir": 2,
  "rpe": 8,
  "pain_flag": false,
  "pain_area": null,
  "recovery_score": 4
}
```

未填写的可选字段保持缺失，不使用 `0` 代替未知值。疼痛是安全信号；出现疼痛时即使其他表现良好，复评也必须进入 `address_safety`，不得自动生成下一阶段计划。

## 尚未完成

1. 本机 Unity 工程 `D:\Codex_pro\Stopwatch\repo-main\stopwatch-main\unity\StopwatchUnity` 已接入逐组证据控件并通过实际导入、C# 编译、Android Library 重导出和 Flutter APK 集成构建；Unity 源码按仓库既定边界不在 Git 中。剩余项是 ARM64 真机目视/交互验收。修改前备份位于 `D:\Codex_pro\Stopwatch\.codex-backups\unity-evidence-before-20260910`。
2. 计划版本离线 outbox 已持久化并在启动后按序自动重试，每条写请求带稳定 `Idempotency-Key`；真实后端 API 地址、认证令牌与跨设备冲突策略仍未联合验收。
3. ARM64 荣耀真机仍需执行逐组输入、进程恢复、完整复评和 30 分钟稳定性矩阵；x86_64 模拟器不能验收 ARM64-only Unity Library。
4. Unity `trial version` 水印、iOS Unity as a Library、女性教练/配音/宠物资产仍属于发布阻塞，未被本轮代码变更覆盖。

## 验收命令

本轮结果：Flutter 全量 113 项测试通过，`flutter analyze --no-pub` 无问题；Python 权威引擎 187 项测试通过；Unity Runtime/Editor 两个 C# 工程均为 0 错误（6 个既有序列化警告），图形 Editor 实际导入和 Android Library 导出成功；`git diff --check` 通过。Unity 批处理模式因 Personal 许可证缺少 `com.unity.editor.headless` entitlement 返回 198，已改用带界面的 Editor 执行导出，不影响产物。集成 APK 为 `flutter/build/app/outputs/flutter-apk/app-debug.apk`，大小 `95,125,394` bytes，SHA-256 `40A2891064A73D82BD6ADEB82C4F9BF3A35236E59BA33C8E587527D3B2896074`。

```powershell
cd flutter
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
```

动作目录的独立保护测试：

```powershell
flutter test --no-pub test/exercise_catalog_integrity_test.dart
```
