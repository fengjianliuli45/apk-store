# Stopwatch Flutter 客户端

> 状态：L2 现行实施说明
> 产品与架构依据：[`../docs/INDEX.md`](../docs/INDEX.md) 与 [`../docs/PRODUCT_BASELINE_2026-08-25.md`](../docs/PRODUCT_BASELINE_2026-08-25.md)。

`flutter/` 是当前正式客户端主线，应用 ID / Bundle ID 为 `com.restpod.hud`。客户端负责登录、问卷、训练计划、训练状态、饮食、社区、数据与本地持久化；Unity 负责教练呈现和结构化输入，不能自行判定训练或阶段完成。

3D 运行时采用 Flutter 主壳 + Unity as a Library 全屏训练；页面内轻量预览可按需使用 GLB，不把 Unity 作为普通小尺寸 Flutter Widget。启动、生命周期、Bridge 和验收方案见 [`../docs/EMBEDDED_3D_RUNTIME_SOLUTION_2026-08-27.md`](../docs/EMBEDDED_3D_RUNTIME_SOLUTION_2026-08-27.md)。

Android 工程已预留可选的 `android/unityLibrary` 模块。Unity 许可证可用后，从 Unity 执行 `Stopwatch > Export Android Unity Library`，再运行：

```powershell
..\tools\sync_unity_android_library.ps1 -ExportPath <Unity工程>\Builds\AndroidExport
```

生成的 `android/unityLibrary/` 是本机构建产物，不提交仓库；未生成时 Flutter 仍以无 Unity 的降级模式构建。

## 启动

```powershell
flutter pub get
flutter run
```

## 验证

```powershell
flutter test
flutter analyze
```

阶段目标与达成逻辑可单独验证：

```powershell
flutter test test/stage_goal_test.dart
```

## 关键目录

- `lib/planner/`：Python `fitness-planner/` 的 Dart 同步实现与 UI 网关。
- `lib/`：应用页面、训练状态与业务逻辑。
- `assets/`：客户端内置资源。
- `test/`：Flutter 测试。
- `android/`、`ios/`：双平台工程配置。

## 交接注意

- 首页和底部导航当前处于“阶段视觉基调已确定、细节讨论暂停”状态，不要把网页原型直接覆盖进正式客户端。
- Unity 教练资产尚未完成首发可用性核查。
- Python/Dart 规划逻辑修改必须保持字段和测试同步。
