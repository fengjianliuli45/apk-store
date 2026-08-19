# apk-store

Stopwatch 休息舱 HUD 的私有备份仓库。

- `app-debug.apk`：Flutter Android 端可安装的 debug 包
- `flutter/`：双端（Android + iOS）源码，Flutter + Dart
- `archive/android-compose/`：旧版 Kotlin + Jetpack Compose 原生工程，仅作参考保留，不再维护
- `docs/figma-ref/`：Figma 设计稿截图对照
- `docs/Stopwatch-app-design-blueprint-v2.md`：现行产品 / 交互 / 架构规范（视觉以 Figma 为准）

## Flutter（当前主线）

应用 ID / Bundle ID 统一为 `com.restpod.hud`。当前已接入：本地手机号 + OTP 登录、目标调研 + 身体数据问卷 → `PlannerGateway` 生成真实训练/营养计划（`lib/planner/` 是 [fitness-planner](https://github.com/fengjianliuli45/fitness-planner) 引擎的 Dart 移植，逐字段核对过与 Python 版一致，离线跑在设备上）、个性化欢迎动画、首页真计时训练舱、社交圈真评论、饮食打卡（相机/条码+历史+食谱）、训练与计划日历 tab（读生成的计划，无计划时回退固定示例）、本地消息会话、附近的人地图、设置页、语音条；Unity 训练舱仍是占位，规划见 `docs/FEATURE_PLAN.md`。

### Android

```bash
cd flutter
flutter build apk --debug --split-per-abi
```

产物在 `flutter/build/app/outputs/flutter-apk/`。默认的 `flutter build apk --debug`（不加 `--split-per-abi`）会打出包含全部 ABI 的 fat APK，Flutter debug 引擎体积很大，通常会超过 GitHub 100MB 单文件限制；仓库根目录的 `app-debug.apk` 用的是其中的 `app-arm64-v8a-debug.apk`（覆盖绝大多数真机），作为它的副本提交。

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
