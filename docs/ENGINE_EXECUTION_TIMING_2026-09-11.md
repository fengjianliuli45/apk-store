# 引擎执行时长契约与 Android 交接

## 结论

此前引擎仅输出 `reps`、`tempo`、`rest_sec`：容量预算中的 55/35 秒不是逐组处方，App 对静态动作使用 30 秒、对“受控”使用 6 秒均属于执行层兜底。本轮把这两类时间提升为 Python 与 Dart 规划引擎共同输出的结构化契约。

## 新契约

- `hold_seconds`：静态动作每组保持时间。当前产品策略按训练水平输出新手 20 秒、中级 30 秒、高级 45 秒，同时把可读处方写成 `20秒/30秒/45秒`，tempo 为“静态保持”。首批静态 ID：plank、side_plank、hollow_hold、superman_hold、isometric_wall_curl。
- `rep_duration_seconds`：动态动作每次完整周期。数字 tempo 取四段之和；非数字“受控”由引擎明确输出 6 秒。该 6 秒延续旧执行行为，现在来源变为引擎而非 Unity 猜测。
- Flutter JSON 解析、周计划覆盖复制、SetPlan、暂停恢复序列化全部携带字段。执行层优先用结构化字段；旧计划缺字段时仍兼容原有秒数字符串、数字 tempo，以及最后的 30/6 秒兜底。
- 每日最低可用训练时间仍只用于计划容量和动作组数安排，不作为完成度或单组倒计时。

20/30/45 秒与 6 秒是当前产品执行策略，不宣称为原引擎已经给出的医学或行业唯一标准。未来变更策略只需调整引擎常量，Unity 不再各自猜测。

## 验证

- Python 规划引擎：189 项测试通过，并实际生成包含 `hold_seconds=30` 的中级计划。
- Flutter：完整 136 项测试通过；新增结构化字段覆盖旧兜底的测试。相关文件 Dart 分析无错误，只有 session_builder.dart 原有的 1 条花括号 info。
- Unity Android Library 从通过无边界场景、固定构图和 21 项运行断言的独立工程导出，日志 `outputs/unity-android-timing-export-20260911.log`。
- Release APK：`outputs/android-engine-timing-20260911/stopwatch-arm64-unity-timing.apk`，46.8 MB，SHA-256 `011F2BD57B4B6D10BD95C11EF07D8E4A9F4F653C722A2424F5E83BDF22086AE2`。已检查包内 ARM64 Flutter/Unity/IL2CPP/Main 原生库和 Unity Data。

## 回滚与限制

- Android 旧生成库完整备份：`.codex-backups/engine-timing-android-20260911`。固定镜头和无边界场景的源码备份见前序文档。
- 源码修改集中在 Python session_builder、Dart session_builder/models/plan_adapter、WorkoutSessionController 及对应测试；产物目录包含 SourcePatch 副本。
- 项目指定的 Oracle 命令在本机不存在，本轮以双引擎源码、序列化路径与测试交叉核验。
- APK 未安装到真机、未上传服务器、未推送远端。它是 ARM64 真机候选，不适用于 x86_64 Unity 模拟器验收。

## 下一步

在 ARM64 真机覆盖：数字 tempo、受控 tempo、20/30/45 秒静态保持、暂停恢复、跳过、跨动作下一组目标、整课完成返回首页，以及至少 30 分钟稳定性和温升/内存观察。通过后才能替换服务器 APK 并更新应用内升级清单。
