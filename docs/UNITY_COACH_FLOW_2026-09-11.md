# Unity 教练演示流程与固定文字修订

用户确认：采用教学→准备→训练→休息→下一组→完成→首页的流程；教练上方文字不随身体动作移动。

## 本轮实现

| 阶段 | 教练与界面行为 | 训练记录 |
| --- | --- | --- |
| 载入/就绪 | Android 等待宿主计划，显示准备提示；就绪时播放恢复姿态，用户点击“开始教学” | 不开始组计时 |
| 首次动作教学 | 0.8 秒就位；正面、侧面各采样一个完整动画周期；固定屏幕显示阶段和引擎动作提示 | 不计用时、次数或完成证据 |
| 准备 | 3、2、1；保持起始姿态，镜头回正面 | 仍不开始计时 |
| 正式训练 | Unity 发 preparation_complete，Flutter 才 startSet；数字 tempo 沿用四阶段节奏；估计用时结束后停止继续示范 | 实际次数和完成由用户输入，倒计时不自动保存 |
| 暂停 | 教学暂停自身进度；正式训练沿用宿主暂停/3 秒恢复机制，保持动作相位 | 暂停期间不累计工作用时 |
| 完成本组 | 原有次数、重量、RIR、疼痛、恢复评分表单交由 Flutter 保存 | 保留证据校验与去重 |
| 休息 | 按引擎休息时长；固定屏幕倒计时与呼吸提示；最后 5 秒预演下一动作 | 沿用宿主休息时钟 |
| 下一组 | Flutter 进入 Ready，Unity 准备后再开始；同一课已教学的动作跳过重复教学，只保留就位与 3 秒准备；新动作重新教学 | 准备时间不混入训练组时长 |
| 完成 | 宿主发 completed，显示完成页 2 秒后返回首页；手动返回与自动返回只执行一次 | 不重复写完成记录 |

教学单次演示长度：数字 tempo 总时长，最低 4 秒；非数字处方使用 6 秒教学展示时长。这个 6 秒仅控制教学播放，不推断引擎工作时长。缺少可播放动作时跳过假演示，显示资源缺失提示并进入准备。

纯动作预览仍不允许控制训练或写记录。“切换视角”原空按钮已接上镜头方向；自动教学期间镜头由教学阶段控制。

## 文字与切换

- 原头顶 TextMesh 按每帧身体 bounds 定位，是晃动来源。停用该世界空间文本，恢复屏幕 Canvas 上的休息倒计时和提示，位于固定安全区坐标。
- 原屏幕休息计时器是透明 1×1 占位；本轮改成可见的大号数字、独立提示与休息标题。
- 模型切换使用约 0.45 秒屏幕过渡遮罩，位于文字/按钮下方且不拦截点击。它用于遮盖姿势突变；并非已制作站立到俯卧的真人式过渡动画。
- 正式暂停保留当前姿态，不强行跳回站姿，以便恢复相同相位。

## 修改位置

正式 Unity 源工程：`D:\Codex_pro\Stopwatch\repo-main\stopwatch-main\unity\StopwatchUnity`。

新增 `CoachPreparation.cs`、`CoachTransitionCurtain.cs`；修改训练控制、动作采样、镜头、固定界面、桥接与桌面检查。Flutter 修改位于 `.remote-main/flutter/lib/unity/unity_session_coordinator.dart`、`lib/state/workout_session_controller.dart`，以及对应测试。

桥接新增 `coachPreparing`、`coachPreparationPaused` 和 `preparation_complete`，并接收已有 `previewOnly`、`formCues`。本次 Unity 与 Flutter 必须一起部署，旧 Unity 库不会发送 preparation_complete，不能只更新 Flutter 后发布。普通 Flutter 降级训练默认不启用等待教学；宿主失效/释放时撤销该设置。

修复宿主 rest_complete 与时钟同时到零时可能重复 advance 的路径；下一组等待教学不影响非 Unity 路径默认行为。

## 验证

- Unity 桌面构建成功，退出码 0。
- 36 项契约检查通过（28 项原节奏检查 + 8 项教学顺序/暂停/倒数/重复组检查）。
- 可见 D3D11 桌面运行 28 项场景断言通过，包含实际正/侧示范、暂停、倒计时、换动作、休息文字可见与固定坐标，以及原节奏检查。
- Flutter 协调器与引擎对齐 13 项测试通过；降级训练、训练容量、消息协议 16 项通过，共 29 项。
- 修改的 3 个 Dart 文件静态分析无问题，Git diff --check 通过（仅既有换行提示）。
- 已查看最终休息截图，倒计时、提示、模型、底部下一组信息清晰可见。场景断言证明文字位置不随运动与镜头变化。

最终桌面产物：`D:\Codex_pro\Stopwatch\outputs\coach-flow-final-20260911\StopwatchCoach.exe`，运行需保留整个同目录构建文件。

证据：`D:\Codex_pro\Stopwatch\outputs\coach-flow-final-evidence-20260911`（13 张截图与 result.txt）。日志：`outputs/coach-flow-final-build.log`、`outputs/coach-flow-final-smoke.log`。

本机未找到项目指定的 Oracle CLI，未声称使用过 Oracle；以上结果来自本地代码检查和执行。

## 回滚与交接

修改前备份：`D:\Codex_pro\Stopwatch\.codex-backups\coach-flow-20260911`。其中 Scripts 是修改前的 Unity 脚本目录；根目录含修改前 Flutter 两个源码及测试、上一版 TempoContractChecks。仅恢复本轮涉及文件，避免覆盖后续工作。新增的两个 Unity 类及 meta 在回滚旧调用方后可保留为未引用文件。

最终构建内 `SourcePatch/Scripts`、`SourcePatch/Editor`、`SourcePatch/flutter` 包含本轮完整对应源码。注意 Unity 源工程不在 `.remote-main` Git 工作树里，只推送该仓库不会带走 Unity 源码；换机应额外传整个正式 Unity 工程或对同版本工程应用 SourcePatch。许可动画资产仍按既有授权约束单独交接，不应公开源资源。

## 下一步与尚未验收

本轮没有导出 Android 库、生成/上传 APK 或推送远端。手机现有安装不会体现这些修改。

下一步将独立 Lab 已验证的专用健身 Demo/接触和平滑修正接入正式场景，按本轮教学与处方节奏复核姿态，再导出 Unity Android 库、一起构建 Flutter APK，进行 ARM64 真机测试。当前正式场景仍使用原动作资源，未声称动作专业性已验收。缺失动作、自然站地转换动画和移动端性能仍需后续处理。
