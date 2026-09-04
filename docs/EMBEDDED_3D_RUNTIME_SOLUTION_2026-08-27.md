# App 内嵌 3D 运行方案（2026-08-27）

> 层级：L2 现行实施说明
> 状态：已确认，进入实施
> 适用范围：Android、iOS、Flutter 主应用、Unity 训练模块、轻量 3D 预览
> 替代关系：替代 `FEATURE_PLAN.md` 中将 Unity 作为普通 Flutter 页面内嵌 Widget 的旧建议；不改变 `PRODUCT_BASELINE_2026-08-25.md` 的业务权威边界。

## 1. 决定

Stopwatch 采用混合 3D 架构：

1. **Flutter 是应用主壳和业务事实源**，负责启动、导航、计划、训练状态机、计时、组次、暂停、停止、完成判定、持久化和结果页。
2. **Unity as a Library 是全屏训练呈现模块**，负责男性/女性教练渲染、Humanoid 动画、镜头、灯光、接地、动作演示和空间 HUD；不作为 Flutter 页面中的小尺寸卡片渲染器。
3. **轻量 GLB 预览按需采用 `<model-viewer>`**，只用于训练准备页、动作详情或资产预览中的旋转、缩放和单动作播放；不得承担正式训练状态机。
4. **普通列表和低端机优先使用海报图或短视频**，不为每个缩略图启动实时 3D。
5. P0 先完成 Unity 全屏训练闭环；GLB 页面内预览不是 P0 阻塞项。

## 2. 选择依据

- Unity 官方支持把 Unity Runtime 集成进 Android/iOS 宿主应用，并提供加载、激活与卸载生命周期；移动端标准方案目前只支持全屏渲染，卸载后仍可能保留约 80–180 MB 内存。因此正式训练采用独立全屏模块，不设计成 Flutter 卡片内的 Unity 小窗口。参见 [Unity as a Library 官方说明](https://docs.unity.cn/Manual/UnityasaLibrary.html)。
- Flutter Platform Views 可以承载 Android/iOS 原生视图，但不同合成方式存在性能、同步、变换和无障碍取舍；它适合轻量原生/WebView 预览，不作为 P0 Unity 训练画面的核心拼接方式。参见 [Flutter Android Platform Views](https://docs.flutter.dev/platform-integration/android/platform-views) 与 [Flutter iOS Platform Views](https://docs.flutter.dev/platform-integration/ios/platform-views)。
- `<model-viewer>` 支持 glTF/GLB 的镜头控制、指定动画、循环、速度控制和播放结束事件，适合轻量动作预览。参见 [`<model-viewer>` 动画](https://modelviewer.dev/examples/animation/)与[镜头控制](https://modelviewer.dev/examples/staging-and-camera-control.html)。
- Google Filament 支持 Android/iOS、PBR、glTF 及蒙皮/关节动画，但采用它需要重写现有 Unity 场景、Humanoid、动作目录、接地、镜头和训练呈现链路，当前不采用。参见 [Google Filament](https://github.com/google/filament)。

## 3. 运行结构

```text
Flutter App
├── 启动与登录
├── 首页 / 计划 / 数据 / 社区
├── 训练状态机与本地数据库
├── 海报 / 视频缩略图
├── 可选 GLB 轻量预览
└── Training Host
      ├── 品牌加载层
      ├── Flutter ↔ Unity JSON Bridge
      └── Unity as a Library（全屏）
            ├── 3D 教练与动作
            ├── 镜头、灯光、地面和接触阴影
            ├── 空间 HUD
            └── 渲染事件与结构化输入
```

## 4. 启动与返回流程

1. App 冷启动只启动 Flutter，显示 Stopwatch 品牌启动页；不得因 Unity 初始化延迟首个 Flutter 页面。
2. 训练准备页显示教练海报；如设备满足条件且预览功能已实现，可按需加载 GLB。
3. 用户点击“开始训练”后，Flutter 创建训练会话并持久化初始状态。
4. Flutter 显示全屏 Stopwatch 训练加载层，再初始化或激活 Unity Runtime。
5. Unity 完成首场景和教练准备后发送 `unity_ready`；Flutter 收到后才移除加载层。
6. 训练期间 Flutter 状态机发出动作、阶段、时间和控制命令，Unity 只呈现对应状态。
7. Unity 的点击、射线或渲染异常以结构化事件回传 Flutter；不得自行修改业务完成状态。
8. 完成或提前结束后，Flutter 先保存结果，再关闭 Unity 视图并打开 Flutter 总结页。
9. 正常设备可保留 Unity Runtime 以便当次会话快速返回；收到系统内存压力、进入长时间后台或用户结束训练后允许卸载。

## 5. 启动画面与 Logo

- Flutter Android/iOS 启动阶段统一显示 Stopwatch 品牌，不显示空白默认页。
- Unity 训练模块不显示独立 Unity Splash，也不显示 Unity Logo；使用 Flutter 的全屏品牌加载层覆盖引擎准备期。
- Unity 工程与导出器已关闭 Splash/Logo；Unity 6 生成的 Android Library Manifest 仍出现 `unity.splash-enable=True`，现已由条件 Host Manifest 覆盖为 `False`，仍需在真机复验无 Unity Logo/闪白。
- Unity 6 的 Player Settings 支持关闭启动画面或 Unity Logo，参见 [Unity 6 Splash Image 设置](https://docs.unity3d.com/cn/current/Manual/class-PlayerSettingsSplashScreen.html)。最终可用选项仍须以实际 Unity 许可证和构建结果为准。
- 禁止出现“Flutter 白屏 → Unity Logo → Stopwatch 训练页”的三段式跳变。

## 6. Flutter 与 Unity 边界

| 能力 | 权威端 | 说明 |
| --- | --- | --- |
| 会话 ID、计划和动作顺序 | Flutter | Unity 只接收快照和增量命令。 |
| 计时、组次、暂停、跳过、结束 | Flutter | 与冻结决策一致。 |
| 训练完成判定与结果保存 | Flutter | Unity 不得自行宣告完成。 |
| 教练模型、动画、镜头、灯光 | Unity | 使用现有 Humanoid 与 Motion Catalog。 |
| 接地与动作展示模式 | Unity | 站立/地面模式由 Flutter 命令选择，Unity 执行。 |
| 业务按钮与无障碍 | Flutter 优先 | P0 若在 Unity 内已有控制，必须通过 Bridge 调用 Flutter 命令，不得形成第二套状态。 |
| 轻量模型预览 | Flutter + WebView | 只读 GLB、动作名和展示参数，不接管训练。 |

## 7. Bridge 最小协议

沿用冻结基线：每条事件必须包含 `event_id`、`session_id`、UTC 时间和协议版本。P0 至少支持：

### Flutter → Unity

- `load_session`
- `set_stage`
- `set_exercise`
- `set_timer`
- `pause`
- `resume`
- `set_recovery`
- `show_next_exercise`
- `dispose_session`

### Unity → Flutter

- `unity_ready`
- `coach_ready`
- `user_control`
- `render_warning`
- `render_fatal`

所有命令必须幂等或带单调序号；重复、乱序和过期消息不得改变当前训练事实。

## 8. 资产策略

### Unity 正式训练

- 保留 FBX/Unity Humanoid 工作流。
- P0 使用已审计的 `StopwatchMaleCoach_MixamoRigged_v2.fbx`。
- 深蹲和俯卧撑继续由 Motion Catalog 绑定。
- 女性教练按 `MALE_COACH_ASSET_AUDIT_2026-08-27.md` 第 5 节准入，不复制动作资产。

### 页面内轻量预览

- 从权威角色和动作源导出独立 `.glb`，不得把 Unity Library 内部 FBX 路径暴露给 Flutter。
- 每个 GLB 只打包预览所需网格、蒙皮、材质和动画；纹理优先采用移动端压缩格式。
- 必须提供海报图、加载失败回退和“减少动态效果”模式。
- GLB 与 Unity FBX 使用同一个 `exercise_id`，但分别维护文件指纹和版本号。

## 9. 性能与生命周期预算

- App 启动：不初始化 Unity。
- Unity 预热：最早只能在用户进入训练准备页后开始；低内存设备默认不预热。
- 训练加载层：必须可取消，并在超时后返回 Flutter，不允许黑屏卡死。
- 同一进程只维护一个 Unity Runtime 实例。
- 页面内同时只允许一个活动 3D 预览；列表滚动时使用海报图。
- Android/iOS 分别记录冷启动、Unity 首次进入、再次进入、峰值内存、后台恢复和退出后的残留内存。

具体阈值在首轮真机基线测试后冻结，不能用桌面编辑器数据代替移动端指标。

## 10. 降级与故障处理

| 故障 | 用户体验 | 系统行为 |
| --- | --- | --- |
| Unity 初始化超时 | 显示“3D 教练暂时无法启动”并允许重试/返回 | 保留训练草稿，不进入 Active。 |
| 模型或动作缺失 | 显示海报或明确占位，不播放错误动作 | 上报 `render_warning`。 |
| Unity 崩溃/致命错误 | 返回 Flutter 训练恢复页 | Flutter 依据已持久化状态恢复或安全结束。 |
| GLB 预览失败 | 保留海报图 | 不影响进入 Unity 正式训练。 |
| 低内存 | 关闭预热和 GLB 自动播放 | 训练结束后卸载 Unity。 |

## 11. 实施阶段

### 当前实施状态（2026-08-27）

- 已完成 Flutter 侧 `UnityCommandEnvelope`、协议版本、事件 ID、会话 ID、UTC 时间和单调序号。
- 已完成 Flutter `UnitySessionCoordinator`，将训练阶段、动作 ID、组次、次数、剩余休息时间和暂停状态同步为快照；相同秒级快照不会重复发送。
- 已完成 Android Method Channel / Event Channel 与全屏 Host；未安装 Unity Library 时不编译 Unity 源码且继续返回降级状态，Flutter 训练状态机仍可独立联调。
- 已完成 Unity `HandleEnvelope`、乱序/重复命令过滤和 `unity_ready`/`render_warning` 回传。
- 已新增 Unity Android Library 批量导出脚本，并将 Splash 与 Unity Logo 配置关闭。
- 已为 Flutter Gradle 工程预留可选 `android/unityLibrary` 模块及本地同步脚本。
- Unity Personal 许可证已由 `6000.5.4f1` Editor 接受；修复导出器缺失的 `UnityEditor.Build` 引用、补充 `com.unity.modules.androidjni`，并将 Android 入口固定为 `AndroidApplicationEntry.Activity` 以兼容 `UnityPlayer.UnitySendMessage`。
- Activity 入口版 Android Library 已成功导出并同步到本机 `flutter/android/unityLibrary`；Build Report 为 Success，生成物约 426.7 MB，已确认 `UnityPlayerActivity`、`UnityPlayer`、ARM64 `libunity.so` 与 Gradle 模块标记存在。
- 已在工作区安装与项目 revision 完全一致的 Flutter `3.47.0` / Dart `3.13.0`；Flutter 27 项测试全部通过，本次修改文件定向静态分析无问题。
- Unity Runtime 与 Editor 程序集均通过 `dotnet build`，0 错误；仅保留 6 个与序列化字段有关的既有 CS0649 警告。
- Gradle Plugin Portal 阻塞已解除：根因是共享 Gradle 配置残留未监听的 `127.0.0.1:10808` 代理。移除失效代理后，官方插件解析、Flutter 构建插件编译和 Android 依赖下载均成功；项目 Wrapper 保持标准官方 URL。
- Android Debug APK 完整构建成功，含真实 Unity IL2CPP ARM64 产物。最终 APK 为 132.82 MiB，SHA-256 `CBECBDC9C436907D9FE640D9BF3F1C735A52C84191243B085478BDE8F8ABFC84`，V2 调试签名有效，仅包含 `arm64-v8a`。
- Android 全屏 Host Activity 已实现：`prepare()` 以 `REORDER_TO_FRONT` 激活单实例 Activity，冷启动命令等到 `unity_ready` 后发送，系统返回保留 Runtime，训练页面销毁时请求 `UnityPlayer.unload()`，卸载回调返回 Flutter 并结束 Host Activity。
- Host Activity 源码和 Unity Manifest 仅在检测到 `:unityLibrary` 时加入主 source set；纯 Flutter构建继续使用原 Manifest。合并产物已验证只有 `MainActivity` 一个 Launcher，生成的 `UnityPlayerActivity` 已移除，`unity.splash-enable=False`、`extractNativeLibs=true`、`minSdk=26`，并移除了 Unity 带入的 `appCategory=game`。
- 2026-08-29 实测补充：`Stopwatch_API_35` x86_64 Google 镜像可通过 ARM 转译层安装并启动 ARM64-only APK。Flutter 冷启动和 Unity 首次渲染成功，男性教练模型可见，未观察到 Unity Logo。但 Unity 画面出现 `trial version` 水印，计次/长按结束未生效，系统 Back 无响应，休息日被错当成训练，总结页有 6.6 px 底部溢出，结束后二次进入时模拟器最终退出。Unity 日志另有 `AssetPackManager` 类缺失。
- **当前主阻塞**：先消除 `trial version` 水印，修复 Unity↔Flutter 输入、Back 和卸载/二次进入链路，然后重建 APK。模拟器的 ARM 转译与 SwiftShader 结果不能代替 ARM64 真机；重建后必须在 Android 8.0+/ARM64 真机验收二次进入、无 Logo/闪白、后台恢复、低内存、Humanoid 动作、接地和材质。
- 本轮修改前文件保存在 `.codex-backups/unity-host-before-20260827/`，运行其中 `rollback.ps1` 可一键恢复。

### Phase A：P0 全屏训练

1. Android 导出 Unity as a Library 并接入 Flutter 宿主。**Activity 入口版 Library 已导出、同步、接入条件 Host 并通过 ARM64 Debug APK 完整构建；等待真机生命周期验证。**
2. 实现最小 Bridge 和 `unity_ready` 握手。**协议、两端桥接和 ready 前指令排队已完成，等待真机运行联调。**
3. 连接现有深蹲、休息、俯卧撑和完成流程。
4. 关闭 Unity Splash/Logo，加入 Stopwatch 加载层。**配置和 Flutter 加载/降级状态已完成，等待真机构建复验。**
5. 完成 Android 真机冷启动、返回、旋转锁定、后台恢复和低内存测试。

### Phase B：iOS 对齐

1. 在 macOS 使用同一 Unity 版本导出 iOS Library。
2. 接入 Flutter iOS 宿主并复用同一 JSON 协议。
3. 验证 iOS 在 Unity 完全退出后同一 App 会话不能重新加载的生命周期限制，产品流程不得调用完全退出后再返回训练。

### Phase C：轻量预览

1. 导出一个男性教练单动作 GLB 试点。
2. 在训练准备页以 WebView + `<model-viewer>` 接入。
3. 与海报方案比较首帧、内存、交互和稳定性；不达标则保留海报/视频，不影响主线。

## 12. P0 验收标准

- Flutter 冷启动不加载 Unity，首屏不出现 Unity Logo。
- 点击开始后只出现 Stopwatch 品牌加载层；Unity 第一帧后无闪白、无重复 Logo。
- `unity_ready` 超时可安全返回，训练草稿不丢失。
- 深蹲、休息、最后 5 秒、俯卧撑和完成可连续跑通。
- 暂停、继续、跳过休息、增加 30 秒和长按结束均由 Flutter 状态机判定。
- Unity 返回后 Flutter 总结数据与本地会话一致。
- 第二次进入训练不产生第二个 Unity Runtime。
- 后台恢复、来电中断、系统返回键和低内存场景均有明确结果。
- 关闭 Unity 视图后不存在声音、计时或输入继续运行。
- Android 真机通过后再启动 iOS 接入，不以编辑器播放结果代替。

## 13. 暂不实施

- 不用 Unity 在首页或列表中渲染小型 3D 卡片。
- 不迁移到 Filament。
- 不同时引入多个 Flutter-Unity 社区插件进行试错。
- 不在 P0 增加 AR、多人、姿态识别或完整动作库。
- 不因本方案恢复首页与导航栏视觉讨论。
