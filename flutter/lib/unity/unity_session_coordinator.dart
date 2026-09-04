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
    String? sessionId,
  }) : sessionId =
           sessionId ?? 'workout-${DateTime.now().millisecondsSinceEpoch}';

  final WorkoutSessionController session;
  final UnityRuntimeBridge bridge;
  final void Function()? onExitRequested;
  final String sessionId;

  final StreamController<UnityHostState> _states =
      StreamController<UnityHostState>.broadcast();
  StreamSubscription<UnityRuntimeEvent>? _eventSubscription;
  UnityHostState state = UnityHostState.checking;
  int _sequence = 0;
  String? _lastSnapshot;
  final Set<String> _processedRuntimeEvents = <String>{};
  bool _runtimeReleaseRequested = false;

  Stream<UnityHostState> get states => _states.stream;

  Future<void> start() async {
    try {
      _setState(UnityHostState.checking);
      if (!await bridge.isAvailable()) {
        _setState(UnityHostState.unavailable);
        return;
      }

      _setState(UnityHostState.loading);
      _eventSubscription = bridge.events.listen(
        _handleEvent,
        onError: (_) => _setState(UnityHostState.failed),
      );
      if (!await bridge.prepare()) {
        _setState(UnityHostState.failed);
        return;
      }

      session.addListener(_sendSnapshotIfChanged);
      await _sendSnapshot(UnityCommandType.loadSession);
    } catch (_) {
      _setState(UnityHostState.failed);
    }
  }

  void _handleEvent(UnityRuntimeEvent event) {
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

    switch (event.type) {
      case 'unity_ready':
      case 'coach_ready':
        _setState(UnityHostState.ready);
        _sendSnapshotIfChanged(force: true);
      case 'render_fatal':
        session.pauseForInterruption('unity_render_fatal');
        _setState(UnityHostState.failed);
      case 'start_training':
        if (session.phase == WorkoutPhase.ready) session.startSet();
      case 'register_rep':
        session.registerRep();
        if (session.justFinished) onExitRequested?.call();
      case 'complete_set':
        session.completeSet();
        if (session.justFinished) onExitRequested?.call();
      case 'toggle_pause':
        session.togglePause();
      case 'skip_rest':
        session.skipRest();
      case 'rest_complete':
        session.startNextSetNow();
      case 'extend_rest':
        final seconds = event.payload['seconds'];
        session.addRestSeconds(seconds is num ? seconds.toInt() : 30);
      case 'end_session':
        session.stopWorkout();
        onExitRequested?.call();
      case 'return_home':
        onExitRequested?.call();
      case 'host_interrupted':
        session.pauseForInterruption('host_interruption');
      case 'host_back':
        session.pauseForInterruption('host_back');
        onExitRequested?.call();
    }
  }

  Future<void> _sendSnapshotIfChanged({bool force = false}) async {
    if (state != UnityHostState.loading && state != UnityHostState.ready) {
      return;
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
    final mode = switch (session.phase) {
      WorkoutPhase.rest => 'rest',
      WorkoutPhase.ready || WorkoutPhase.idle => 'preview',
      WorkoutPhase.active => 'training',
    };
    return {
      'mode': mode,
      'exerciseId': session.exerciseId,
      'exerciseLabel': session.exerciseName,
      'nextExerciseId': session.nextExerciseId,
      'nextExerciseLabel': session.nextExerciseName,
      'set': session.currentSet,
      'totalSets': session.totalSets,
      'rep': session.completedReps,
      'targetReps': session.targetReps,
      'elapsedSeconds': session.setElapsedMs / 1000,
      'remainingSeconds': session.phase == WorkoutPhase.rest
          ? session.restRemainingMs ~/ 1000
          : 0,
      'paused': session.isPaused,
      'resumeCountdownSeconds': session.resumeCountdownSeconds,
    };
  }

  void _setState(UnityHostState next) {
    state = next;
    if (!_states.isClosed) _states.add(next);
  }

  Future<void> releaseRuntime() async {
    if (_runtimeReleaseRequested) return;
    _runtimeReleaseRequested = true;
    await bridge.disposeSession(sessionId);
  }

  Future<void> dispose() async {
    session.removeListener(_sendSnapshotIfChanged);
    await _eventSubscription?.cancel();
    await releaseRuntime();
    await _states.close();
  }
}
