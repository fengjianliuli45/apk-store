# Unity 电脑端基础运行检查（2026-09-10）

## 本机运行入口

- 工程：`D:/Codex_pro/Stopwatch/repo-main/stopwatch-main/unity/StopwatchUnity`，Unity 6000.5.4f1。
- 修正版 Windows 程序：`D:/Codex_pro/Stopwatch/outputs/coach-desktop-fixed-20260910/StopwatchCoach.exe`。
- 推荐双击同目录 `Start-Coach.cmd`，以 D3D11、540×960 窗口运行。整个程序目录必须一起保留，不能只复制 EXE。
- 这是实际 Unity Standalone，不是 Flutter 或 Android 模拟器的降级画面。独立版使用本地验证计划，不代表 Flutter↔Android 桥接已通过。

## 复现与修复

- 初始桌面截图复现：模型绝大部分位于画面底部，被操作卡片遮挡，中央大面积空白。
- `CoachPresentationController` 原本按启动/切换时的 Renderer bounds 设置镜头，未在动画及贴地之后重新定位。改为执行顺序 1400（贴地为1300），按当前 Humanoid 骨点包围盒更新取景，并为上下 HUD 预留中央展示区域。
- 原文件备份：`D:/Codex_pro/Stopwatch/.codex-backups/coach-desktop-before-20260910/CoachPresentationController.cs`。第一版桌面包保留于 `outputs/coach-desktop-20260910`；无需重置整个工程即可回滚相机文件。
- 增加 Editor 构建入口 `StopwatchDesktopBuild.Build`、仅 Windows 且显式参数启用的 `CoachDesktopSmoke`。本轮没有修改/发布 Android APK，也没有重导出 Unity Android Library。
- 新源码位于上述本地 Unity 工程，尚未纳入 apk-store 的 Unity 源资产交付；换机必须携带 Unity Assets/Packages/ProjectSettings，不能仅拿 Flutter 代码复现。

## 验证证据

- Windows Development Build 成功，已激活许可证可用于构建。
- 修正版实际运行：有效 Humanoid、准备、深蹲动画可用、暂停、恢复、休息、下一动作、俯卧撑动画可用、完成均通过脚本断言。
- 截图目录：`outputs/coach-desktop-fixed-20260910/smoke/`；结果 `result.txt` 为 PASS。已人工查看准备/深蹲/俯卧撑截图：全身进入中央可视区域。
- 自动验证直接驱动真实 TrainingSessionController，未覆盖所有按钮命中、长按证据表单及 Android 生命周期。
- 首次隐藏窗口测试截图失败，改为可见窗口 D3D11 后成功。不能因此认定所有 D3D12 渲染有问题。

## 未完成与下一步

- 真实 FBX 动作仅 2/38（深蹲、俯卧撑）；其他部分有程序化回退，不应冒充正式动画验收。
- 材质较暗，俯卧撑的接触点/完整周期与相机跟随平滑度仍需细查。
- 日志存在场景 missing-script 警告，未阻断这次流程，但需定位资源引用并清理。
- 原生 HUD 的提示、完成后入口、独立演示控件需要与现有 Flutter 设计对齐。
- 下一步在此桌面程序逐个检查动作全周期和交互，再整治模型材质/动作资产/原生 HUD；通过后再导出 Android，不以当前基础状态机 PASS 代替真机效果验收。
