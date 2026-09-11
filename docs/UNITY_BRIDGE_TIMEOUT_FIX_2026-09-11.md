# Unity 桥接与启动超时修复（2026-09-11）

## 问题与证据

真机 1.0.4+5 中，Unity 仍按字面量调用 `com.restpod.hud.UnityRuntimeBridge.emitEvent`，但发布 DEX 未稳定保留对应入口；`StopwatchUnityActivity.onRuntimeReady` 也缺失。启动约 20 秒超时后，宿主调用 `UnityPlayer.unload()`，随后在 `libunity` 的 `JNI_OnUnload` 中发生 `SIGSEGV`。

## 修改

- `UnityRuntimeBridge` 及跨语言静态方法添加 `@Keep`、`@JvmStatic`，并增加明确 R8 `-keep` 规则。
- `StopwatchUnityActivity` 及反射调用的 `onRuntimeReady`、`requestReturnToFlutter` 同样保留原名和静态入口。
- 启动超时仍上报 `render_fatal`，但仅用 `FLAG_ACTIVITY_REORDER_TO_FRONT` 恢复 Flutter；不再在 Unity 尚未 ready 时调用 `unload()` 或 `destroy()`。
- 版本递增为 1.0.5+6。

## 验证

- Release APK 构建成功，包信息为 `versionName=1.0.5`、`versionCode=6`。
- SHA-256：`6D2A33E4496A9A2358FF8AFF14B846F1566238C6A37FD2B88261E10A8966980C`。
- DEX 中保留 `com.restpod.hud.UnityRuntimeBridge.emitEvent(String)`，访问标志为 `PUBLIC STATIC FINAL`。
- DEX 中保留 `StopwatchUnityActivity.onRuntimeReady()` 和 `requestReturnToFlutter()` 的 `PUBLIC STATIC FINAL` 入口。
- Flutter 136 项测试通过。
- API 35 x86_64 模拟器覆盖安装并冷启动成功，进程存活，首页可访问；crash buffer 与日志中无 `FATAL EXCEPTION`、`SIGSEGV` 或 Room 初始化错误。

## 回滚与剩余验收

修改前文件备份位于 `.codex-backups/unity-bridge-timeout-20260911/`。模拟器不能完成 ARM64 Unity 原生渲染验收；发布后需在荣耀 ARM64 真机依次验证：首次进入收到 `unity_ready`、动作与事件闭环、主动返回、20 秒异常超时返回，以及上述路径均不产生 `SIGSEGV`。

## 发布

- APK：`https://mainleaf.top/apk/stopwatch-1.0.5-6.apk`
- 更新清单：`https://mainleaf.top/apk/latest.json`
- 文件大小：58,917,502 bytes。
- 服务器 SHA-256 与本地一致；公网清单、APK 与下载页均返回 HTTP 200。
- 旧版 APK 保留；切换前的清单和页面备份为服务器 `latest.before-1.0.5-6.json.bak`、`index.before-1.0.5-6.html.bak`。
