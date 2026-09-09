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

  Future<void> _completeSetWithEvidence() async {
    final current = session.plans[session.currentSet - 1];
    final evidence = await showModalBottomSheet<SetCompletionEvidence>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => _SetCompletionEvidenceSheet(
        initialReps: session.completedReps > 0
            ? session.completedReps
            : session.targetReps,
        initialWeightKg: current.loadKg,
        loadHint: current.load,
        showRecovery: session.currentSet == session.totalSets,
      ),
    );
    if (mounted && evidence != null) session.completeSet(evidence);
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
                        UnityHostState.unavailable => '3D 模块当前不可用',
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
                          ? '当前设备无法运行内置 3D 模块。\n可继续使用 Flutter 训练界面。'
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
                        _PodButton(
                          label: '完成这组',
                          onTap: () => unawaited(_completeSetWithEvidence()),
                        )
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

class _SetCompletionEvidenceSheet extends StatefulWidget {
  const _SetCompletionEvidenceSheet({
    required this.initialReps,
    required this.initialWeightKg,
    required this.loadHint,
    required this.showRecovery,
  });

  final int initialReps;
  final double? initialWeightKg;
  final String loadHint;
  final bool showRecovery;

  @override
  State<_SetCompletionEvidenceSheet> createState() =>
      _SetCompletionEvidenceSheetState();
}

class _SetCompletionEvidenceSheetState
    extends State<_SetCompletionEvidenceSheet> {
  late final TextEditingController _repsController;
  late final TextEditingController _weightController;
  final TextEditingController _painAreaController = TextEditingController();
  final TextEditingController _recoveryController = TextEditingController();
  int? _rir;
  var _painFlag = false;

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController(text: '${widget.initialReps}');
    _weightController = TextEditingController(
      text: widget.initialWeightKg?.toStringAsFixed(1) ?? '',
    );
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    _painAreaController.dispose();
    _recoveryController.dispose();
    super.dispose();
  }

  void _save() {
    final painArea = _painAreaController.text.trim();
    Navigator.of(context).pop(
      SetCompletionEvidence(
        actualReps: int.tryParse(_repsController.text),
        weightKg: double.tryParse(_weightController.text),
        rir: _rir,
        painFlag: _painFlag,
        painArea: painArea.isEmpty ? null : painArea,
        recoveryScore: double.tryParse(_recoveryController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '记录本组',
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '实际次数'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: '重量 kg（可选）',
                      hintText: widget.loadHint,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int?>(
              initialValue: _rir,
              decoration: const InputDecoration(labelText: '剩余次数 RIR（可选）'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('不记录')),
                for (var value = 0; value <= 5; value++)
                  DropdownMenuItem<int?>(value: value, child: Text('$value')),
              ],
              onChanged: (value) => setState(() => _rir = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('本组出现疼痛'),
              value: _painFlag,
              onChanged: (value) => setState(() => _painFlag = value),
            ),
            if (_painFlag)
              TextField(
                controller: _painAreaController,
                decoration: const InputDecoration(labelText: '疼痛部位（可选）'),
              ),
            if (widget.showRecovery) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _recoveryController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: '今日恢复评分 1–5（可选）'),
              ),
            ],
            const SizedBox(height: 20),
            _PodButton(label: '保存并完成本组', onTap: _save),
          ],
        ),
      ),
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
