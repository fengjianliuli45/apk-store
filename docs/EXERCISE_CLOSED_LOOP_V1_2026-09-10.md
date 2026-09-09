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
- 已用 Unity 6000.5.4f1 图形 Editor 重新导出 Activity 入口 Android Library 并同步到 Flutter Android 工程。最终 Debug APK 同时提供 ARM64/x86_64 Flutter 与 SQLite，Unity/IL2CPP/Main 仍为 ARM64-only；合并 Manifest 只有 Flutter `MainActivity` 一个 Launcher，`unity.splash-enable=false`。
- 修复 x86_64 模拟器同时声明 `x86_64,arm64-v8a` 时的 Unity 误启动：运行时现在只在设备主 ABI 为 `arm64-v8a` 时开放 Unity Host，并由 3 项 Kotlin 单元测试锁定。不可用提示改为设备兼容性文案，不再错误声称安装包缺少 Unity Library。
- 修复逐组证据层关闭时的控制器生命周期错误：输入控制器改由底部层 StatefulWidget 持有，直到退场动画完成后才释放，避免聚焦输入框后按系统返回触发 Flutter `_dependents.isEmpty` 红屏。返回取消与保存完成两条路径均已在最终 APK 上复验。
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
3. API 35 / x86_64 模拟器已通过 Flutter 冷启动、ABI 降级、逐组证据层、休息/下一组和结束返回首页验收；ARM64 荣耀真机仍需执行真实 Unity 画面下的逐组输入、进程恢复、完整复评和 30 分钟稳定性矩阵。
4. Unity `trial version` 水印、iOS Unity as a Library、女性教练/配音/宠物资产仍属于发布阻塞，未被本轮代码变更覆盖。

## 验收命令

本轮结果：Flutter 全量 114 项测试通过，`flutter analyze --no-pub` 无问题；Android ABI 兼容性 3 项 Kotlin 测试通过；Python 权威引擎 187 项测试通过；Unity Runtime/Editor 两个 C# 工程均为 0 错误（6 个既有序列化警告），图形 Editor 实际导入和 Android Library 导出成功；`git diff --check` 通过。Unity 批处理模式因 Personal 许可证缺少 `com.unity.editor.headless` entitlement 返回 198，已改用带界面的 Editor 执行导出，不影响产物。最终通用 APK 为 `flutter/build/app/outputs/flutter-apk/app-debug.apk`，大小 `140,425,691` bytes，SHA-256 `4FAE39D0B595CA66F18C7CDFC823146295ACC93143ADCAC854FBD81FEEFCAFEA`。

构建前必须先执行一次 `flutter pub get`；若在缺少 `.flutter-plugins-dependencies` 时直接使用 `--no-pub`，Android 原生插件不会注册。模拟器基础验收截图保存在本机 `.codex_tmp/emulator-test-20260910/`；红屏复现及修复证据保存在 `.codex_tmp/emulator-crash-20260910/`，其中 `crash-current.png`、`built-fixed.png` 和 `save-fixed.png` 分别对应原始红屏、返回关闭修复和保存进入休息态。

```powershell
cd flutter
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
cd android
.\gradlew.bat :app:testDebugUnitTest '-Ptarget-platform=android-arm64,android-x64'
cd ..
flutter build apk --debug --target-platform android-arm64,android-x64 --no-pub
```

动作目录的独立保护测试：

```powershell
flutter test --no-pub test/exercise_catalog_integrity_test.dart
```
