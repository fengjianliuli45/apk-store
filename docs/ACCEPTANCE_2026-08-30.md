# Stopwatch Android P0 验收记录（2026-08-30）

> 结论：Android P0 训练闭环在 Android 15 / API 35 模拟器上通过功能验收；发布验收仍被 Unity 水印、ARM64 真机和 iOS 等外部事项阻塞。资产授权已于 2026-08-30 澄清，不再作为另购授权硬阻塞。

## 1. 验收环境与产物

- 模拟器：`Stopwatch_API_35`，Android 15 / API 35，1080×2400，x86_64 Google 系统镜像。
- Unity：`6000.5.4f1`，Activity 入口 Android Library，IL2CPP，`arm64-v8a`。
- Flutter：`3.47.0`；Dart：`3.13.0`。
- APK：`flutter/build/app/outputs/flutter-apk/app-debug.apk`。
- APK 大小：`167,064,391` bytes。
- APK SHA-256：`EB7ABF8F14878266FAE15D9EFA7C6354AF46FF52F65BEB7C80A871089C2496B0`。
- 修改前回滚点：`.codex-backups/p0-acceptance-before-20260829/`。
- 本机截图、日志和数据库副本：`.codex_tmp/acceptance-20260829/`。该目录不进入 Git。

模拟器通过 ARM 转译运行 ARM64-only APK，因此功能结果有效，但不能替代 ARM64 真机的性能、驱动和兼容性结论。

## 2. 已通过项目

| 项目 | 结果 | 核对依据 |
| --- | --- | --- |
| Flutter 冷启动 | 通过 | 首屏进入 Flutter；没有观察到 Unity Logo。 |
| 登录与欢迎页一次性状态 | 通过 | 重启后 `auth_logged_in=true`，相同目标不重播欢迎动画。 |
| 休息日语义 | 通过 | 休息日首页不再创建虚假 `1组×1次` 训练。 |
| Unity 首次进入 | 通过 | 男性教练、准备态和开始按钮正常渲染。 |
| 手动计次 | 通过 | “点击计次”只按用户输入增加，不由动画自动增加。 |
| 暂停与继续 | 通过 | 训练/休息暂停时计时冻结；继续前显示 3 秒倒计时。 |
| 休息控制 | 通过 | 最后 5 秒状态、增加 30 秒、跳过休息均由 Flutter 状态机处理。 |
| 系统返回与后台中断 | 通过 | 返回 Flutter 后保留可恢复草稿；再次进入显示暂停态。 |
| 进程死亡恢复 | 通过 | 强制停止后恢复当前组、完整计划队列和精确当前组计时。 |
| 跨休息日恢复 | 通过 | 即使当天变为休息日，既有训练仍按持久化队列恢复。 |
| Unity 暖复用 | 通过 | 返回后再次进入不创建第二个 Runtime，也不再触发共享进程 `SIGKILL`。 |
| 暖 Runtime 新会话 | 通过 | 新 `session_id` 的 `load_session` 重置命令序号窗口；预览和训练态立即刷新。 |
| 完整训练完成 | 通过 | 10/10 组、120 次完成后自动回首页 `READY`，没有“再次训练”。 |
| 中途结束保存 | 通过 | 长按结束回首页；数据库会话为 `stopped`，当前组保存为 `incomplete`。 |
| 本地数据库 | 通过 | schema v3；保存当前组毫秒计时和完整 `plan_json` 队列。 |
| 运行稳定性 | 通过 | 最终运行日志未发现 `FATAL EXCEPTION`、Fatal signal、`SIG: 9`、SQLite 或类加载异常。 |

主要截图：

- `completion-home.png`：完整训练完成后自动回首页。
- `v3-process-home.png`、`v3-process-unity.png`：进程死亡恢复。
- `rest-extended2.png`、`rest-skipped.png`：休息控制。
- `paused-a.png`、`paused-b.png`：暂停计时冻结。
- `partial-stopped-home.png`：中途结束返回首页。
- `warm-new-preview.png`、`warm-new-active.png`：暖 Runtime 新会话序号修复。
- `final-home.png`：最终模拟器停留状态。

## 3. 数据库验收结果

完整训练会话：

- `status=completed`
- `current_set=10`
- `current_rep=12`
- `completed_sets=10`
- `total_sets=10`
- 10 条已完成组记录，合计 120 次
- `plan_json` 非空
- `workout_has_resumable_v1=false`

中途结束会话：

- `status=stopped`
- 1 条 `incomplete` 组记录
- `session_stopped` 事件 1 条
- `workout_has_resumable_v1=false`

## 4. 自动化验证

- `flutter test`：34/34 通过。
- `flutter analyze`：`No issues found!`
- Unity Android Library：Editor Build Report `Success`。
- Flutter Android Debug APK：Gradle/IL2CPP 构建成功。

构建时仅有 `mobile_scanner`、`speech_to_text` 尚未迁移 Flutter Built-in Kotlin 的未来兼容性警告，不影响当前构建。

## 5. 本轮关键修复

- Flutter 成为训练阶段、组次、计时、暂停、完成和持久化的唯一事实源。
- SQLite 升级到 v3，保存当前组精确计时和完整计划队列。
- 普通返回时保留 Unity Runtime，避免 `UnityPlayer.unload()` 杀死 Flutter 共用进程。
- 暖启动延迟重新发出 `unity_ready`，待 Unity 渲染线程恢复后再刷新快照。
- Flutter 接受当前可见控制产生的旧 Unity 会话事件，让新会话能接管暖 Runtime。
- Unity 仅允许不同 `session_id` 的 `load_session` 开启新的序号窗口；其他旧会话命令仍被拒绝。
- 最后一组完成后直接保存并回首页；中途长按结束保存不完整组。

## 6. 尚未通过的发布阻塞

1. Unity 画面右下角仍有 `trial version` 水印。工程已关闭 Splash/Logo，导出使用 `BuildOptions.None`，不能通过遮挡或修改二进制规避。需要账号/许可证归属核验、Unity 支持，或评估团结引擎个人认证路线。
2. 尚未在原生 ARM64 荣耀真机执行完整矩阵；必须验证渲染驱动、前后台、来电、低内存、性能、发热和长时间稳定性。
3. iOS Unity as a Library 尚未接入；需 macOS、Xcode 和 iOS 真机。
4. 男性模型为用户 Neural4D 自生成，动作来自 Mixamo 免费库。Mixamo 官方允许免版税嵌入商业游戏成品，无需另购授权。Neural4D 商用取决于生成时是否为付费档。建议把订阅/生成记录与条款快照归档到 `docs/licenses/`，不再因「缺少商业授权」限制内部或商店发布。
5. 女性教练资产、配音/动作、宠物孵化和跨设备同步仍未交付。

## 7. 下一步

按发布风险排序：

1. 用户先处理 Unity 水印所需的账号/身份/支持渠道。资产侧只需确认 Neural4D 付费档并保存生成记录，不必另买 Mixamo 或模型商业授权。
2. 在已完成 ADB RSA 授权的 ARM64 荣耀真机安装本页 APK，执行冷启动、两次进入、后台/来电、低内存、完整训练和 30 分钟稳定性矩阵。
3. 真机通过后，在 macOS 开始 iOS Unity Library 接入。
4. 由产品负责人提供女性教练、配音和宠物首版资产/方向，再进入对应实现。
