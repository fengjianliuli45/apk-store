# 固定镜头演示安全区修订

为解决地面动作手部被底部操作卡片遮挡的问题，正面与侧面摄像机共用的正交尺寸从 2.05 调整至 2.3，固定观察点高度从 0.55 调整至 0.2。摄像机位置不变，初始化后无追随、插值或移动。代价是模型整体略小，换取手脚完整显示与稳定构图。

## 验证

- 独立 Unity 构建成功，28 项节奏、36 项流程契约通过。
- 21 项运行回归通过，含固定双机硬切、四动作接地、自动换组和跳过；结果 outputs/framing-audit-20260911/result.txt。
- 实际 Camera+Canvas 离屏渲染已检查：540×960 下教学站姿、俯卧撑正面与平板支撑侧面均未被顶部提示或底部卡片遮挡。截图目录 outputs/framing-ui-20260911；审查脚本增加俯卧撑和平板支撑侧面证据。
- 不代表全动作库、不同屏幕比例、Android 刘海安全区或真机触控全部验收。动作专业姿态另行验收，不能仅以无遮挡或不穿地判断合格。

## 交接

- 正式源码：repo-main/stopwatch-main/unity/StopwatchUnity/Assets/Scripts/CoachPresentationController.cs、CoachRectificationAudit.cs。
- 回滚：.codex-backups/framing-20260911。桌面产物：outputs/coach-framing-20260911/StopwatchCoach.exe。
- 本轮未修改 Flutter、训练处方和动作动画；未更新 Android 库或手机 APK，未推送远端。
- 下一步核对静态保持时长与非数值节奏的引擎执行契约，再导出配套 Android 库进行真机完整训练验收，并覆盖不同屏幕比例。
