import 'dart:async';

import 'package:flutter/foundation.dart';

/// Session phases. Idle/Ready/Active/Rest mirror the Compose
/// `WorkoutSessionViewModel` state machine from archive/android-compose —
/// Flutter only drives the timer + Home UI; the pod's own Ready/Active/Rest
/// screens live in the Unity scene (see UnityCoachPlaceholderScreen). Once a
/// real Unity build is wired in, `UnityWidgetController.postMessage` should
/// call these same methods (startSet/completeSet/addRestSeconds/skipRest/
/// abortWorkout) so Flutter stays the single source of truth for timing.
enum WorkoutPhase { idle, ready, active, rest }

class SetPlan {
  const SetPlan(this.name, this.targetReps);
  final String name;
  final int targetReps;
}

class WorkoutSessionController extends ChangeNotifier {
  static const totalSets = 4;
  static const restDefaultMs = 30000;
  static const _tickInterval = Duration(milliseconds: 50);
  static const _lastFiveMs = 5000;
  static const _repIntervalMs = 2000;

  static const plans = [
    SetPlan('深蹲', 12),
    SetPlan('深蹲', 12),
    SetPlan('俯卧撑', 12),
    SetPlan('俯卧撑', 12),
  ];

  WorkoutPhase phase = WorkoutPhase.idle;
  int currentSet = 1;
  int completedReps = 0;
  int setElapsedMs = 0;
  bool isPaused = false;
  int restRemainingMs = restDefaultMs;
  int restDurationMs = restDefaultMs;
  bool isLastFiveSeconds = false;

  Timer? _ticker;
  final Stopwatch _stopwatch = Stopwatch();
  int _lastElapsedMs = 0;

  String get exerciseName => plans[currentSet - 1].name;

  String get nextExerciseName =>
      currentSet < plans.length ? plans[currentSet].name : exerciseName;

  int get targetReps => plans[currentSet - 1].targetReps;

  bool get isRunning => phase == WorkoutPhase.active || phase == WorkoutPhase.rest;

  /// mm:ss.cc — set-elapsed while active, rest countdown while resting.
  String get timerText {
    final ms = phase == WorkoutPhase.rest ? restRemainingMs : setElapsedMs;
    final centis = ms ~/ 10;
    final minutes = centis ~/ 6000;
    final seconds = (centis % 6000) ~/ 100;
    final cs = centis % 100;
    return '${_pad(minutes)}:${_pad(seconds)}.${_pad(cs)}';
  }

  double get ringProgress {
    if (phase == WorkoutPhase.rest) {
      final total = restDurationMs.clamp(1, 1 << 31);
      return (restRemainingMs / total).clamp(0.0, 1.0);
    }
    if (phase == WorkoutPhase.active) {
      return (completedReps / targetReps).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  String get phaseLabel => switch (phase) {
        WorkoutPhase.idle => 'READY',
        WorkoutPhase.ready => 'READY',
        WorkoutPhase.active => 'ACTIVE',
        WorkoutPhase.rest => 'REST',
      };

  void startSession() {
    _applySet(1, WorkoutPhase.ready);
  }

  void startSet() {
    phase = WorkoutPhase.active;
    setElapsedMs = 0;
    completedReps = 0;
    isPaused = false;
    _startTicker();
    notifyListeners();
  }

  void togglePause() {
    if (phase != WorkoutPhase.active) return;
    isPaused = !isPaused;
    notifyListeners();
  }

  void completeSet() {
    if (phase != WorkoutPhase.active) return;
    if (currentSet >= totalSets) {
      _reset();
    } else {
      _beginRest();
    }
  }

  void addRestSeconds([int seconds = 30]) {
    if (phase != WorkoutPhase.rest) return;
    final extra = seconds * 1000;
    restRemainingMs += extra;
    restDurationMs += extra;
    isLastFiveSeconds = restRemainingMs <= _lastFiveMs;
    notifyListeners();
  }

  void skipRest() {
    if (phase != WorkoutPhase.rest) return;
    restRemainingMs = _lastFiveMs;
    isLastFiveSeconds = true;
    notifyListeners();
  }

  void startNextSetNow() {
    if (phase != WorkoutPhase.rest) return;
    _advance(autoStart: true);
  }

  /// Long-press-to-end from the Compose original.
  void abortWorkout() => _reset();

  void _beginRest() {
    phase = WorkoutPhase.rest;
    restRemainingMs = restDefaultMs;
    restDurationMs = restDefaultMs;
    isLastFiveSeconds = false;
    isPaused = false;
    _startTicker();
    notifyListeners();
  }

  void _advance({required bool autoStart}) {
    final next = currentSet + 1;
    if (next > totalSets) {
      _reset();
      return;
    }
    _applySet(next, autoStart ? WorkoutPhase.active : WorkoutPhase.ready);
    if (autoStart) {
      _startTicker();
    } else {
      _ticker?.cancel();
    }
  }

  void _applySet(int setNumber, WorkoutPhase newPhase) {
    currentSet = setNumber;
    phase = newPhase;
    completedReps = 0;
    setElapsedMs = 0;
    isPaused = false;
    restRemainingMs = restDefaultMs;
    restDurationMs = restDefaultMs;
    isLastFiveSeconds = false;
    notifyListeners();
  }

  void _reset() {
    _ticker?.cancel();
    _ticker = null;
    _stopwatch
      ..stop()
      ..reset();
    phase = WorkoutPhase.idle;
    currentSet = 1;
    completedReps = 0;
    setElapsedMs = 0;
    isPaused = false;
    restRemainingMs = restDefaultMs;
    restDurationMs = restDefaultMs;
    isLastFiveSeconds = false;
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _stopwatch
      ..reset()
      ..start();
    _lastElapsedMs = 0;
    _ticker = Timer.periodic(_tickInterval, (_) => _onTick());
  }

  void _onTick() {
    final now = _stopwatch.elapsedMilliseconds;
    final dt = now - _lastElapsedMs;
    _lastElapsedMs = now;

    if (phase == WorkoutPhase.active) {
      if (isPaused) return;
      setElapsedMs += dt;
      final autoReps = (setElapsedMs ~/ _repIntervalMs).clamp(0, targetReps);
      if (autoReps > completedReps) completedReps = autoReps;
      notifyListeners();
    } else if (phase == WorkoutPhase.rest) {
      final remaining = (restRemainingMs - dt).clamp(0, 1 << 31);
      restRemainingMs = remaining;
      isLastFiveSeconds = remaining <= _lastFiveMs;
      if (remaining <= 0) {
        _advance(autoStart: true);
        return;
      }
      notifyListeners();
    }
  }

  static String _pad(int value) => value.toString().padLeft(2, '0');

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
