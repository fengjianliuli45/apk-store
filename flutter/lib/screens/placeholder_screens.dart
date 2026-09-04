import 'dart:async';

import 'package:flutter/material.dart';

import '../state/workout_session_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../unity/unity_runtime_bridge.dart';
import '../unity/unity_session_coordinator.dart';
import '../widgets/back_bar.dart';
import '../widgets/gradient_background.dart';

/// Flutter-side host for the full-screen Unity as a Library training module.
/// Until the exported Android/iOS library is installed, this screen keeps a
/// functional fallback so the Flutter state machine remains testable.
class UnityCoachPlaceholderScreen extends StatefulWidget {
  const UnityCoachPlaceholderScreen({super.key, required this.session});

  final WorkoutSessionController session;

  @override
  State<UnityCoachPlaceholderScreen> createState() =>
      _UnityCoachPlaceholderScreenState();
}

class _UnityCoachPlaceholderScreenState
    extends State<UnityCoachPlaceholderScreen> {
  late final UnitySessionCoordinator _coordinator;
  StreamSubscription<UnityHostState>? _stateSubscription;
  UnityHostState _hostState = UnityHostState.checking;
  bool _exitScheduled = false;

  WorkoutSessionController get session => widget.session;

  @override
  void initState() {
    super.initState();
    _coordinator = UnitySessionCoordinator(
      session: session,
      bridge: MethodChannelUnityRuntimeBridge(),
      onExitRequested: _returnHome,
    );
    _stateSubscription = _coordinator.states.listen((state) {
      if (mounted) setState(() => _hostState = state);
    });
    unawaited(_coordinator.start());
  }

  void _returnHome() {
    if (_exitScheduled) return;
    _exitScheduled = true;
    unawaited(_coordinator.releaseRuntime());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    unawaited(_stateSubscription?.cancel());
    unawaited(_coordinator.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        return GradientBackground(
          child: Column(
            children: [
              BackBar(title: '训练舱'),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        color: AppColors.brandGreen,
                        shape: BoxShape.circle,
                      ),
                      child:
                          _hostState == UnityHostState.checking ||
                              _hostState == UnityHostState.loading
                          ? const Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(
                                color: AppColors.ink,
                                strokeWidth: 3,
                              ),
                            )
                          : const Icon(
                              Icons.view_in_ar,
                              color: AppColors.ink,
                              size: 40,
                            ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      switch (_hostState) {
                        UnityHostState.checking => '正在检查 3D 模块',
                        UnityHostState.loading => '正在准备 3D 教练',
                        UnityHostState.ready => '3D 教练已连接',
                        UnityHostState.failed => '3D 教练启动失败',
                        UnityHostState.unavailable => '3D 模块待导出',
                      },
                      style: const TextStyle(
                        fontFamily: AppFonts.inter,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _hostState == UnityHostState.unavailable
                          ? '当前安装包尚未包含 Unity Library。\n可继续使用 Flutter 训练状态机进行联调。'
                          : _hostState == UnityHostState.failed
                          ? '训练草稿已保留，可以返回后重试。'
                          : 'Stopwatch 正在同步训练状态与 3D 教练。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 13,
                        height: 1.6,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Text(
                            session.isRestDay
                                ? (session.sessionTitle.isEmpty
                                      ? '休息日'
                                      : session.sessionTitle)
                                : session.justFinished
                                ? '本课完成'
                                : '${session.exerciseName} · 第 ${session.currentSet}/${session.totalSets} 组',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: AppFonts.inter,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            session.isRestDay ? '按计划恢复' : session.timerText,
                            style: AppTextStyles.timer.copyWith(fontSize: 28),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session.isRestDay ? '今日无训练组' : session.phaseLabel,
                            style: const TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!session.isRestDay && !session.justFinished) ...[
                      const SizedBox(height: 16),
                      if (session.phase == WorkoutPhase.active)
                        _PodButton(label: '完成这组', onTap: session.completeSet)
                      else if (session.phase == WorkoutPhase.rest)
                        _PodButton(
                          label: '进入下一组',
                          onTap: session.startNextSetNow,
                        )
                      else if (session.phase == WorkoutPhase.ready)
                        _PodButton(label: '开始本组', onTap: session.startSet),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: GestureDetector(
                  onTap: () {
                    if (!session.justFinished) session.stopWorkout();
                    _returnHome();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      session.justFinished ? '返回首页' : '结束并保存',
                      style: const TextStyle(
                        fontFamily: AppFonts.inter,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PodButton extends StatelessWidget {
  const _PodButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.brandGreen,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: AppFonts.inter,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}
