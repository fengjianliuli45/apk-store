import 'dart:async';

import '../state/workout_session_controller.dart';
import 'unity_protocol.dart';
import 'unity_runtime_bridge.dart';

enum UnityHostState { checking, unavailable, loading, ready, failed }

class UnitySessionCoordinator {
  static const _userControlEvents = <String>{
    'start_training',
    'register_rep',
    'complete_set',
    'toggle_pause',
    'skip_rest',
    'skip_preparation',
    'skip_set',
    'extend_rest',
    'end_session',
    'return_home',
    'host_back',
    'host_interrupted',
  };

  UnitySessionCoordinator({
    required this.session,
    required this.bridge,
    this.onExitRequested,
    this.previewOnly = false,
    this.guidedTraining = true,
    String? sessionId,
  }) : sessionId =
           sessionId ?? 'workout-${DateTime.now().millisecondsSinceEpoch}';

  final WorkoutSessionController session;
  final UnityRuntimeBridge bridge;
  final void Function()? onExitRequested;
  final String sessionId;
  final bool previewOnly;
  final bool guidedTraining;

  final StreamController<UnityHostState> _states =
      StreamController<UnityHostState>.broadcast();
  StreamSubscription<UnityRuntimeEvent>? _eventSubscription;
  UnityHostState state = UnityHostState.checking;
  int _sequence = 0;
  String? _lastSnapshot;
  final Set<String> _processedRuntimeEvents = <String>{};
  bool _runtimeReleaseRequested = false;
  bool _disposed = false;
  bool _preparing = false;
  bool _preparationPaused = false;
  WorkoutPhase? _previousPhase;
  Timer? _completionTimer;
  bool _exitSent = false;

  void _exit() {
    if (_exitSent || _disposed) return;
    _exitSent = true;
    _completionTimer?.cancel();
    onExitRequested?.call();
  }

  Stream<UnityHostState> get states => _states.stream;

  Future<void> start() async {
    if (_disposed) return;
    try {
      _setState(UnityHostState.checking);
      if (!await bridge.isAvailable()) {
        _setState(UnityHostState.unavailable);
        return;
      }
      if (_disposed) return;

      _setState(UnityHostState.loading);
      _eventSubscription = bridge.events.listen(
        _handleEvent,
        onError: (_) => _setState(UnityHostState.failed),
      );
      if (!await bridge.prepare()) {
        _setState(UnityHostState.failed);
        return;
      }
      if (_disposed) {
        await bridge.disposeSession(sessionId);
        return;
      }

      session.addListener(_sendSnapshotIfChanged);
      if (!previewOnly) session.awaitCoachPreparation = true;
      if (!previewOnly) session.guidedPlayback = guidedTraining;
      _previousPhase = session.phase;
      await _sendSnapshot(UnityCommandType.loadSession);
    } catch (_) {
      _setState(UnityHostState.failed);
    }
  }

  void _handleEvent(UnityRuntimeEvent event) {
    if (_disposed) return;
    if (event.protocolVersion != unityProtocolVersion) return;
    if (event.sessionId.isNotEmpty &&
        event.sessionId != sessionId &&
        !_userControlEvents.contains(event.type)) {
      return;
    }
    if (event.eventId.isNotEmpty &&
        !_processedRuntimeEvents.add(event.eventId)) {
      return;
    }

    // Demonstration never starts a workout, timer, draft or completion record.
    if (previewOnly &&
        event.type != 'unity_ready' &&
        event.type != 'coach_ready' &&
        event.type != 'render_fatal') {
      if (const {
        'host_back',
        'return_home',
        'end_session',
      }.contains(event.type)) {
        onExitRequested?.call();
      }
      return;
    }
    switch (event.type) {
      case 'unity_ready':
      case 'coach_ready':
        _setState(UnityHostState.ready);
        _sendSnapshotIfChanged(force: true);
      case 'render_fatal':
        session.pauseForInterruption('unity_render_fatal');
        _setState(UnityHostState.failed);
      case 'start_training':
        if (session.phase == WorkoutPhase.ready && !_preparing) {
          _preparing = true;
          _preparationPaused = false;
          _sendSnapshotIfChanged(force: true);
        }
      case 'preparation_complete':
        if (_preparing &&
            !_preparationPaused &&
            session.phase == WorkoutPhase.ready) {
          _preparing = false;
          session.startSet();
        }
      case 'register_rep':
        if (!session.guidedPlayback) session.registerRep();
      case 'complete_set':
        if (session.guidedPlayback) break;
        session.completeSet(
          SetCompletionEvidence(
            actualReps: _intValue(event.payload, 'actualReps', 'actual_reps'),
            weightKg: _doubleValue(event.payload, 'weightKg', 'weight_kg'),
            rir: _intValue(event.payload, 'rir'),
            rpe: _doubleValue(event.payload, 'rpe'),
            painFlag: _boolValue(event.payload, 'painFlag', 'pain_flag'),
            painArea: _stringValue(event.payload, 'painArea', 'pain_area'),
            recoveryScore: _doubleValue(
              event.payload,
              'recoveryScore',
              'recovery_score',
            ),
          ),
        );
      case 'toggle_pause':
        if (_preparing) {
          _preparationPaused = !_preparationPaused;
          _sendSnapshotIfChanged(force: true);
        } else {
          session.togglePause();
        }
      case 'skip_rest':
        session.skipRest();
      case 'skip_preparation':
        if (session.phase == WorkoutPhase.ready) {
          _preparing = false;
          _preparationPaused = false;
          session.startSet();
        }
      case 'skip_set':
        session.skipCurrentSet();
      case 'rest_complete':
        session.startNextSetNow();
      case 'extend_rest':
        final seconds = event.payload['seconds'];
        session.addRestSeconds(seconds is num ? seconds.toInt() : 30);
      case 'end_session':
        session.stopWorkout(
          painFlag: _boolValue(event.payload, 'painFlag', 'pain_flag'),
          recoveryScore: _doubleValue(
            event.payload,
            'recoveryScore',
            'recovery_score',
          ),
        );
        _exit();
      case 'return_home':
        _exit();
      case 'host_interrupted':
        if (_preparing) {
          _preparationPaused = true;
          _sendSnapshotIfChanged(force: true);
        }
        session.pauseForInterruption('host_interruption');
      case 'host_back':
        session.pauseForInterruption('host_back');
        _exit();
    }
  }

  Future<void> _sendSnapshotIfChanged({bool force = false}) async {
    if (state != UnityHostState.loading && state != UnityHostState.ready) {
      return;
    }
    if (!previewOnly &&
        (_previousPhase == WorkoutPhase.rest ||
            _previousPhase == WorkoutPhase.active) &&
        session.phase == WorkoutPhase.ready) {
      _preparing = true;
      _preparationPaused = false;
    }
    _previousPhase = session.phase;
    if (session.justFinished && !previewOnly) {
      _preparing = false;
      _completionTimer ??= Timer(const Duration(seconds: 2), _exit);
    }
    final snapshot = _snapshot();
    final fingerprint = snapshot.entries
        .map((e) => '${e.key}=${e.value}')
        .join('|');
    if (!force && fingerprint == _lastSnapshot) return;
    _lastSnapshot = fingerprint;
    try {
      await _sendSnapshot(UnityCommandType.setStage, snapshot: snapshot);
    } catch (_) {
      _setState(UnityHostState.failed);
    }
  }

  Future<void> _sendSnapshot(
    UnityCommandType type, {
    Map<String, Object?>? snapshot,
  }) {
    final sequence = ++_sequence;
    final now = DateTime.now().toUtc();
    return bridge.send(
      UnityCommandEnvelope(
        eventId: '$sessionId-$sequence-${now.microsecondsSinceEpoch}',
        sessionId: sessionId,
        occurredAtUtc: now,
        sequence: sequence,
        type: type,
        payload: snapshot ?? _snapshot(),
      ),
    );
  }

  Map<String, Object?> _snapshot() {
    final nextPlan = session.currentSet < session.plans.length
        ? session.plans[session.currentSet]
        : null;
    final mode = switch (session.phase) {
      WorkoutPhase.rest => 'rest',
      WorkoutPhase.ready || WorkoutPhase.idle => 'preview',
      WorkoutPhase.active => 'training',
    };
    return {
      'mode': session.justFinished && !previewOnly ? 'completed' : mode,
      'coachPreparing': _preparing,
      'coachPreparationPaused': _preparationPaused,
      'previewOnly': previewOnly,
      'guidedPlayback': session.guidedPlayback && !previewOnly,
      'holdExercise': session.isHold,
      'executionTempo':
          session.plans.isEmpty ||
              session.plans[session.currentSet - 1].estimatedWorkMs == null
          ? '3-0-3-0'
          : session.plans[session.currentSet - 1].tempo,
      'exerciseId': session.exerciseId,
      'exerciseLabel': session.exerciseName,
      'nextExerciseId': session.nextExerciseId,
      'nextExerciseLabel': session.nextExerciseName,
      'nextSetSummary': nextPlan == null
          ? ''
          : '第 ${nextPlan.exerciseSetIndex} / ${nextPlan.plannedSets} 组 · ${nextPlan.isHold ? '${nextPlan.holdSeconds} 秒' : '${nextPlan.targetReps} 次'}',
      'set': session.plans.isEmpty
          ? 1
          : session.plans[session.currentSet - 1].exerciseSetIndex,
      'totalSets': session.plans.isEmpty
          ? 0
          : session.plans[session.currentSet - 1].plannedSets,
      'rep': session.completedReps,
      'targetReps': session.targetReps,
      'repsPrescription': session.plans.isEmpty
          ? ''
          : session.plans[session.currentSet - 1].repsPrescription,
      'plannedLoad': session.plans.isEmpty
          ? ''
          : session.plans[session.currentSet - 1].load,
      'plannedWeightKg': session.plans.isEmpty
          ? null
          : session.plans[session.currentSet - 1].loadKg,
      'targetRpe': session.plans.isEmpty
          ? null
          : session.plans[session.currentSet - 1].rpe,
      'tempo': session.plans.isEmpty
          ? ''
          : session.plans[session.currentSet - 1].tempo,
      'formCues': session.plans.isEmpty
          ? const <String>[]
          : session.plans[session.currentSet - 1].formCues,
      'elapsedSeconds': session.setElapsedMs / 1000,
      'estimatedWorkSeconds': (session.estimatedWorkMs ?? 0) / 1000,
      'remainingWorkSeconds': (session.workRemainingMs ?? 0) / 1000,
      'remainingSeconds': session.phase == WorkoutPhase.rest
          ? session.restRemainingMs ~/ 1000
          : 0,
      'paused': session.isPaused,
      'resumeCountdownSeconds': session.resumeCountdownSeconds,
    };
  }

  static Object? _value(Map<String, Object?> values, List<String> keys) {
    for (final key in keys) {
      if (values.containsKey(key)) return values[key];
    }
    return null;
  }

  static int? _intValue(
    Map<String, Object?> values,
    String first, [
    String? second,
  ]) {
    final value = _value(values, [first, ?second]);
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _doubleValue(
    Map<String, Object?> values,
    String first, [
    String? second,
  ]) {
    final value = _value(values, [first, ?second]);
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static bool _boolValue(
    Map<String, Object?> values,
    String first, [
    String? second,
  ]) {
    final value = _value(values, [first, ?second]);
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value?.toString().toLowerCase() == 'true';
  }

  static String? _stringValue(
    Map<String, Object?> values,
    String first, [
    String? second,
  ]) {
    final value = _value(values, [first, ?second]);
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  void _setState(UnityHostState next) {
    if (next == UnityHostState.failed || next == UnityHostState.unavailable) {
      if (!previewOnly) session.awaitCoachPreparation = false;
      if (!previewOnly) session.guidedPlayback = false;
      _preparing = false;
    }
    state = next;
    if (!_states.isClosed) _states.add(next);
  }

  Future<void> releaseRuntime() async {
    if (_runtimeReleaseRequested) return;
    _runtimeReleaseRequested = true;
    await bridge.disposeSession(sessionId);
  }

  Future<void> dispose() async {
    _disposed = true;
    _completionTimer?.cancel();
    if (!previewOnly) session.awaitCoachPreparation = false;
    if (!previewOnly) session.guidedPlayback = false;
    session.removeListener(_sendSnapshotIfChanged);
    await _eventSubscription?.cancel();
    await releaseRuntime();
    await _states.close();
  }
}
