import 'dart:async';

import 'package:flutter/material.dart';

import '../state/workout_session_controller.dart';
import '../unity/unity_runtime_bridge.dart';
import '../unity/unity_session_coordinator.dart';

/// Owns a disposable, unpersisted preview queue; never uses the live workout.
class ExercisePreviewScreen extends StatefulWidget {
  const ExercisePreviewScreen({super.key, required this.exercise});
  final SetPlan exercise;

  @override
  State<ExercisePreviewScreen> createState() => _ExercisePreviewScreenState();
}

class _ExercisePreviewScreenState extends State<ExercisePreviewScreen> {
  late final WorkoutSessionController _preview;
  late final UnitySessionCoordinator _coordinator;
  StreamSubscription<UnityHostState>? _subscription;
  UnityHostState _state = UnityHostState.checking;

  @override
  void initState() {
    super.initState();
    _preview = WorkoutSessionController()..plans = [widget.exercise];
    _coordinator = UnitySessionCoordinator(
      session: _preview,
      bridge: MethodChannelUnityRuntimeBridge(),
      previewOnly: true,
      onExitRequested: () {
        if (mounted) Navigator.of(context).maybePop();
      },
    );
    _subscription = _coordinator.states.listen((state) {
      if (mounted) setState(() => _state = state);
    });
    unawaited(_coordinator.start());
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_coordinator.dispose());
    _preview.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('动作演示 · 不计入训练')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          widget.exercise.name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Text(switch (_state) {
          UnityHostState.checking || UnityHostState.loading => '正在打开 3D 教练…',
          UnityHostState.ready => '仅供查看动作；不会开始训练、计时或保存记录。',
          UnityHostState.unavailable => '此设备或安装包暂不支持 Unity 3D 演示。可先查看下方动作要点。',
          UnityHostState.failed => '3D 教练启动失败。请返回后重试；不会影响训练记录。',
        }),
        const SizedBox(height: 24),
        for (final cue in widget.exercise.formCues)
          Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(cue)),
        if (widget.exercise.formCues.isEmpty) const Text('此动作暂未提供文字要点。'),
      ],
    ),
  );
}
