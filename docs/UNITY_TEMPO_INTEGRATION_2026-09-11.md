# Unity 动作节奏接入（2026-09-11）

## 本轮结果

本机 Unity 源工程已消费 Flutter 的 tempo/elapsedSeconds，深蹲与俯卧撑按四阶段处方播放。数字 `3-1-2-0` 表示下放3秒、底部保持1秒、抬起2秒、顶部保持0秒，演示周期6秒；阶段内采用起止速度为零的时间映射。非数字“受控”继续使用原演示速度，不派生规定秒数，不自动记录次数。处方顺序参考[NASM tempo说明](https://www.nasm.org/resource-center/blog/training/tempo-training-using-lifting-tempo-to-drive-adaption)，具体数字来自本地引擎session_builder。

修改位于 `D:/Codex_pro/Stopwatch/repo-main/stopwatch-main/unity/StopwatchUnity`，不是安卓导出目录。Flutter工作树为 `D:/Codex_pro/Stopwatch/.remote-main`。未确认远端是否有更新；本轮未修改规划算法。

## 修改内容

- TrainingTempo：独立的数字节奏解析及相位映射，不负责组完成或写日志。
- StopwatchUnityBridge：接收并传递tempo，保留旧消息缺少tempo时的兼容行为。
- CoachMotionController：按外部训练时钟采样动作。仅对已有两个完整垂直动作clip启用自动高低位标定，其他动作保留原速，不能宣称全库同步。缓存处方解析，切换动作时进行一次120相位标定。
- SquatGuideController：相同动作/速度的重复请求不再销毁重建动画；Flutter周期快照不会反复把动作重置到开头。显式Restart仍能复位。
- TrainingSessionController：训练/暂停保持同一时间轴，恢复倒数期间冻结时间，休息退出训练节奏，完成停止训练播放；外部预计倒计时归零不自动完成。
- CoachTrainingCanvas：显示处方及当前动作阶段，移除准备页固定“4秒节奏”；预计倒计时上下两处统一向上取整。
- CoachDesktopSmoke和TempoContractChecks：新增实际骨骼暂停/恢复、重复快照、桥接与数值契约验证。Flutter只增加一个回归测试，未再改变生产会话规则。

## 验证证据

- Unity6000.5.4f1：28项节奏契约检查通过，最终桌面构建成功；日志 `outputs/coach-tempo-verified-build.log`。
- 实际场景20项断言通过：准备、动作、暂停、休息、完成、预计时间归零不完成、tempo桥接、重复快照不重建、底部保持、恢复倒数冻结、实际骨骼暂停不动/恢复移动、非数字处方及完成清理。日志 `outputs/coach-tempo-verified.log`。
- 最终可见窗口采用D3D11，10张截图位于 `outputs/coach-tempo-verified-20260911/`。已查看底部保持截图：界面“节奏3-1-2-0·底部保持”，上方01:09与下方69秒一致。
- Flutter `test --no-pub test/unity_session_coordinator_test.dart test/engine_execution_alignment_test.dart`：12项通过；新增测试文件静态分析无问题；git diff --check通过。
- 早期隐藏窗口标定range=0并失败，定位为Animator裁剪跳过求值，改为AlwaysAnimate后标定有效。旧隐藏截图接口报错导致总结果FAIL；最终可见窗口完整通过，没有把早期失败算作成功。
- Flutter SDK启动遇到目录所有权和工具日志权限，最终使用进程内safe.directory及已有依赖运行，无全局Git配置修改。工程约定Oracle未在PATH找到，未调用。

## 产物与回滚

- 桌面程序：`D:/Codex_pro/Stopwatch/outputs/coach-tempo-20260911/StopwatchCoach.exe`，必须连同整个输出目录使用。
- 可迁移源码：同目录SourcePatch/Scripts、SourcePatch/Editor，含对应meta；README记录使用范围。
- 修改前源码：`D:/Codex_pro/Stopwatch/.codex-backups/tempo-integration-20260911/`，含六个已有Unity脚本及Flutter测试。回滚时恢复这些已有脚本；新增TrainingTempo、TempoContractChecks可保留为未调用文件或在确认后移除。
- 所有旧实验构建、原始FBX和本轮之前的用户改动保留。没有推送、发布APK或更新服务器。

## 到真机前仍需完成

本轮在正式训练场景中验证节奏接口，场景仍使用原有两条FBX；之前已通过离地/平滑回归的专用健身Demo与接触修正仍在独立Lab中。不能把本轮截图当成新Demo已经合入，也不能把桌面协议测试称为Flutter–Android–Unity整链路通过。

下一步：将已验证的Demo及接触修正整合到训练场景，并在处方节奏下复核姿态/离地；再导出Android Unity Library、合入Flutter并生成ARM64真机测试包。移动端性能、窗口恢复及专业动作验收仍待完成。当前源场景还存在既有missing-script警告，需在Android导出前审查。
