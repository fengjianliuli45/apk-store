# apk-store

Stopwatch 休息舱 HUD 的私有备份仓库。

- `app-release.apk`：Flutter Android 端可安装的 release 包（仍用 debug 签名，见下）
- `flutter/`：双端（Android + iOS）源码，Flutter + Dart
- `archive/android-compose/`：旧版 Kotlin + Jetpack Compose 原生工程，仅作参考保留，不再维护
- `docs/figma-ref/`：Figma 设计稿截图对照
- `docs/Stopwatch-app-design-blueprint-v2.md`：现行产品 / 交互 / 架构规范（视觉以 Figma 为准）

## Flutter（当前主线）

应用 ID / Bundle ID 统一为 `com.restpod.hud`。当前已接入：本地手机号 + OTP 登录、目标调研 + 身体数据问卷 → `PlannerGateway` 生成真实训练/营养计划（`lib/planner/` 是 [fitness-planner](https://github.com/fengjianliuli45/fitness-planner) 引擎的 Dart 移植，逐字段核对过与 Python 版一致，离线跑在设备上）、个性化欢迎动画、首页真计时训练舱、社交圈真评论、饮食打卡（相机/条码+历史+食谱）、训练与计划日历 tab（读生成的计划，无计划时回退固定示例）、本地消息会话、附近的人地图、设置页、语音条；Unity 训练舱仍是占位，规划见 `docs/FEATURE_PLAN.md`。

### Android

```bash
cd flutter
flutter build apk --release --split-per-abi
```

产物在 `flutter/build/app/outputs/flutter-apk/`。以前这里提交的是 debug 包，但 `video_player` 接入后 debug 包三个 ABI 变体都涨到了 100MB+（Flutter debug 引擎本就大，未做任何瘦身），超过 GitHub 100MB 单文件限制推不上去；release 包会做 R8 收缩 + 图标资源树摇，arm64 版本只有 ~28MB。`android/app/build.gradle.kts` 里 release 的 `signingConfig` 还是指向 debug keystore（没配真正的发布签名），所以 release 包和以前的 debug 包一样可以直接装到测试机，不用额外签名。仓库根目录的 `app-release.apk` 是 `app-arm64-v8a-release.apk`（覆盖绝大多数真机）的副本。

### iOS

需要 macOS + Xcode，本仓库开发环境（Linux）不具备编译条件，`flutter/ios` 已随源码一起提交。在 Mac 上：

```bash
open flutter/ios/Runner.xcworkspace
```

或者：

```bash
cd flutter
flutter build ios
```

### Unity

Unity 训练舱 / 3D 教练场景不在本仓库内，由本机 Unity 工程独立开发与接入。Flutter 端「开始训练」目前跳转到一个占位页，说明接入方式，不重做 Unity 画面。

## 旧 Kotlin Compose 工程

`archive/android-compose/` 保留了迁移前的原生 Compose 实现，可用 `./gradlew assembleDebug`（在该目录下）继续独立构建，但不再是本仓库的开发主线。
