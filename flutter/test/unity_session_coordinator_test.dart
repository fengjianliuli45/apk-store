import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/state/workout_session_controller.dart';
import 'package:rest_pod_hud/state/workout_log_controller.dart';
import 'package:rest_pod_hud/unity/unity_protocol.dart';
import 'package:rest_pod_hud/unity/unity_runtime_bridge.dart';
import 'package:rest_pod_hud/unity/unity_session_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('rest snapshot uses next exercise set and hold target', () async {
    final session = WorkoutSessionController()
      ..plans = const [
        SetPlan('push_up', '俯卧撑', 12, plannedSets: 1),
        SetPlan('plank', '平板支撑', 30, repsPrescription: '30秒', plannedSets: 3),
      ]
      ..startSession()
      ..startSet();
    final bridge = _FakeUnityRuntimeBridge();
    final coordinator = UnitySessionCoordinator(
      session: session,
      bridge: bridge,
      sessionId: 'next-target',
    );
    await coordinator.start();
    session.completeSet();
    await _flushEvents();
    expect(bridge.commands.last.payload['nextExerciseId'], 'plank');
    expect(bridge.commands.last.payload['nextSetSummary'], '第 1 / 3 组 · 30 秒');
    session.skipRest();
    await _flushEvents();
    expect(bridge.commands.last.payload['nextSetSummary'], '');
    await coordinator.dispose();
    session.dispose();
  });
  test(
    'stage skip controls route to host without granting completed sets',
    () async {
      final session = WorkoutSessionController()
        ..plans = const [
          SetPlan('push_up', '俯卧撑', 8),
          SetPlan('push_up', '俯卧撑', 8),
        ]
        ..startSession();
      final bridge = _FakeUnityRuntimeBridge();
      final coordinator = UnitySessionCoordinator(
        session: session,
        bridge: bridge,
        sessionId: 'skip',
      );
      await coordinator.start();
      bridge.emit(_event('s1', 'skip_preparation', sessionId: 'skip'));
      await _flushEvents();
      expect(session.phase, WorkoutPhase.active);
      bridge.emit(_event('s2', 'skip_set', sessionId: 'skip'));
      await _flushEvents();
      expect(session.currentSet, 2);
      expect(session.completedSets, 0);
      expect(bridge.commands.last.payload['coachPreparing'], true);
      bridge.emit(_event('s2', 'skip_set', sessionId: 'skip'));
      await _flushEvents();
      expect(session.currentSet, 2);
      await coordinator.dispose();
      session.dispose();
    },
  );

  test(
    'teaching pauses on interruption and next set waits without recording work',
    () async {
      final session = WorkoutSessionController()
        ..plans = const [
          SetPlan('bodyweight_squat', '深蹲', 1, restMs: 10000),
          SetPlan('push_up', '俯卧撑', 1),
        ]
        ..startSession();
      final bridge = _FakeUnityRuntimeBridge();
      final coordinator = UnitySessionCoordinator(
        session: session,
        bridge: bridge,
        sessionId: 'flow',
      );
      await coordinator.start();
      bridge.emit(_event('start', 'start_training', sessionId: 'flow'));
      bridge.emit(_event('interrupt', 'host_interrupted', sessionId: 'flow'));
      bridge.emit(_event('early', 'preparation_complete', sessionId: 'flow'));
      await _flushEvents();
      expect(session.phase, WorkoutPhase.ready);
      expect(session.setElapsedMs, 0);
      expect(bridge.commands.last.payload['coachPreparationPaused'], true);
      bridge.emit(_event('resume', 'toggle_pause', sessionId: 'flow'));
      bridge.emit(
        _event('old', 'preparation_complete', sessionId: 'old-session'),
      );
      await _flushEvents();
      expect(session.phase, WorkoutPhase.ready);
      bridge.emit(
        _event('prepared', 'preparation_complete', sessionId: 'flow'),
      );
      await _flushEvents();
      expect(session.phase, WorkoutPhase.active);
      session.completeSet();
      session.startNextSetNow();
      await _flushEvents();
      expect(session.currentSet, 2);
      expect(session.phase, WorkoutPhase.ready);
      expect(session.setElapsedMs, 0);
      expect(session.completedReps, 0);
      expect(bridge.commands.last.payload['coachPreparing'], true);
      bridge.emit(
        _event('prepared-next', 'preparation_complete', sessionId: 'flow'),
      );
      await _flushEvents();
      expect(session.phase, WorkoutPhase.active);
      await coordinator.dispose();
      expect(session.awaitCoachPreparation, false);
      session.dispose();
    },
  );

  test('tempo and estimated work survive Unity snapshots and pause', () async {
    final session = WorkoutSessionController()
      ..plans = const [
        SetPlan('bodyweight_squat', '深蹲', 12, tempo: '3-1-2-0', restMs: 90000),
      ]
      ..startSession();
    final bridge = _FakeUnityRuntimeBridge();
    final coordinator = UnitySessionCoordinator(
      session: session,
      bridge: bridge,
      sessionId: 'tempo',
    );
    await coordinator.start();
    expect(bridge.commands.last.payload['tempo'], '3-1-2-0');
    expect(bridge.commands.last.payload['estimatedWorkSeconds'], 72);
    session.startSet();
    await _flushEvents();
    session.togglePause();
    await _flushEvents();
    expect(bridge.commands.last.payload['paused'], true);
    expect(bridge.commands.last.payload['tempo'], '3-1-2-0');
    expect(bridge.commands.last.payload['elapsedSeconds'], isA<num>());
    expect(session.completedReps, 0);
    expect(session.completedSets, 0);
    await coordinator.dispose();
    session.dispose();
  });

  test(
    'preview ignores workout controls and never records a workout',
    () async {
      final log = WorkoutLogController();
      final session = WorkoutSessionController()..attachLog(log);
      final bridge = _FakeUnityRuntimeBridge();
      var exits = 0;
      final coordinator = UnitySessionCoordinator(
        session: session,
        bridge: bridge,
        previewOnly: true,
        sessionId: 'session-1',
        onExitRequested: () => exits++,
      );
      await coordinator.start();
      expect(bridge.commands.first.payload['mode'], 'preview');
      expect(bridge.commands.first.payload['previewOnly'], true);
      for (final type in [
        'start_training',
        'register_rep',
        'complete_set',
        'toggle_pause',
        'skip_rest',
        'rest_complete',
        'extend_rest',
      ]) {
        bridge.emit(_event(type, type));
      }
      await _flushEvents();
      expect(session.phase, WorkoutPhase.idle);
      expect(session.hasResumableSession, false);
      expect(session.completedSets, 0);
      expect(log.recent, isEmpty);
      bridge.emit(_event('back', 'host_back'));
      await _flushEvents();
      expect(exits, 1);
      await coordinator.dispose();
      session.dispose();
    },
  );

  test(
    'Unity intents mutate the Flutter-owned session and exit on completion',
    () async {
      final session = WorkoutSessionController()
        ..plans = const [
          SetPlan('bodyweight_squat', '徒手深蹲', 1, tempo: '0-0-1-0'),
        ]
        ..startSession();
      final bridge = _FakeUnityRuntimeBridge();
      var exits = 0;
      final coordinator = UnitySessionCoordinator(
        session: session,
        bridge: bridge,
        sessionId: 'session-1',
        onExitRequested: () => exits += 1,
      );

      await coordinator.start();
      bridge.emit(_event('ready-1', 'unity_ready'));
      await _flushEvents();
      expect(coordinator.state, UnityHostState.ready);

      bridge.emit(_event('start-1', 'start_training'));
      await _flushEvents();
      expect(session.phase, WorkoutPhase.ready);
      expect(bridge.commands.last.payload['coachPreparing'], true);
      expect(session.setElapsedMs, 0);
      bridge.emit(_event('prepared-1', 'preparation_complete'));
      await _flushEvents();
      expect(session.phase, WorkoutPhase.active);

      final completion = _event('rep-1', 'register_rep');
      bridge.emit(completion);
      bridge.emit(completion);
      await _flushEvents();

      expect(
        session.justFinished,
        isFalse,
        reason: 'manual taps cannot advance guided training',
      );
      await Future<void>.delayed(const Duration(milliseconds: 1150));
      expect(session.justFinished, isTrue);
      expect(bridge.commands.last.payload['mode'], 'completed');
      expect(exits, 0, reason: 'show completion before returning home');
      await Future<void>.delayed(const Duration(milliseconds: 2100));
      expect(exits, 1, reason: 'duplicate runtime events must be idempotent');
      await coordinator.dispose();
      session.dispose();
    },
  );

  test('rest controls and host back are delegated to Flutter', () async {
    final session =
        WorkoutSessionController(
            resumeCountdownStep: const Duration(milliseconds: 1),
          )
          ..plans = const [
            SetPlan('bodyweight_squat', '徒手深蹲', 1, restMs: 10000),
            SetPlan('push_up', '俯卧撑', 1),
          ]
          ..startSession()
          ..startSet()
          ..completeSet();
    final bridge = _FakeUnityRuntimeBridge();
    var exits = 0;
    final coordinator = UnitySessionCoordinator(
      session: session,
      bridge: bridge,
      sessionId: 'session-2',
      onExitRequested: () => exits += 1,
    );
    await coordinator.start();

    bridge.emit(_event('pause-1', 'toggle_pause', sessionId: 'session-2'));
    await _flushEvents();
    expect(session.isPaused, isTrue);
    final before = session.restRemainingMs;

    bridge.emit(
      _event(
        'extend-ignored',
        'extend_rest',
        sessionId: 'session-2',
        payload: const {'seconds': 30},
      ),
    );
    await _flushEvents();
    expect(session.restRemainingMs, before);

    bridge.emit(_event('pause-2', 'toggle_pause', sessionId: 'session-2'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    bridge.emit(
      _event(
        'extend-1',
        'extend_rest',
        sessionId: 'session-2',
        payload: const {'seconds': 30},
      ),
    );
    bridge.emit(_event('back-1', 'host_back', sessionId: 'session-2'));
    await _flushEvents();

    expect(session.isPaused, isTrue);
    expect(session.restRemainingMs, greaterThanOrEqualTo(before + 29000));
    expect(exits, 1);
    await coordinator.dispose();
    session.dispose();
  });

  test('active snapshots carry elapsed time without inventing reps', () async {
    final session = WorkoutSessionController()
      ..plans = const [SetPlan('bodyweight_squat', '徒手深蹲', 12)]
      ..startSession();
    final bridge = _FakeUnityRuntimeBridge();
    final coordinator = UnitySessionCoordinator(
      session: session,
      bridge: bridge,
      sessionId: 'session-3',
    );

    await coordinator.start();
    bridge.emit(_event('ready-3', 'unity_ready', sessionId: 'session-3'));
    bridge.emit(_event('start-3', 'start_training', sessionId: 'session-3'));
    bridge.emit(
      _event('prepared-3', 'preparation_complete', sessionId: 'session-3'),
    );
    await Future<void>.delayed(const Duration(milliseconds: 120));

    final latest = bridge.commands.lastWhere(
      (command) => command.type == UnityCommandType.setStage,
    );
    expect(latest.payload['elapsedSeconds'] as num, greaterThan(0));
    expect(latest.payload['rep'], 0);

    await coordinator.dispose();
    session.dispose();
  });

  test('first warm-runtime control can take over a stale session id', () async {
    final session =
        WorkoutSessionController(
            resumeCountdownStep: const Duration(milliseconds: 1),
          )
          ..plans = const [SetPlan('bodyweight_squat', '徒手深蹲', 12)]
          ..startSession()
          ..startSet()
          ..togglePause();
    final bridge = _FakeUnityRuntimeBridge();
    final coordinator = UnitySessionCoordinator(
      session: session,
      bridge: bridge,
      sessionId: 'new-session',
    );
    await coordinator.start();

    bridge.emit(
      _event('warm-resume', 'toggle_pause', sessionId: 'old-session'),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(session.isPaused, isFalse);
    expect(
      bridge.commands.last.payload['paused'],
      isFalse,
      reason: 'the accepted control must immediately refresh Unity state',
    );
    await coordinator.dispose();
    session.dispose();
  });

  test(
    'Unity complete_set payload becomes structured planner evidence',
    () async {
      final log = WorkoutLogController();
      await log.load();
      final session = WorkoutSessionController()
        ..attachLog(log)
        ..plans = const [SetPlan('barbell_bench_press', '杠铃卧推', 10)]
        ..startSession();
      final bridge = _FakeUnityRuntimeBridge();
      final coordinator = UnitySessionCoordinator(
        session: session,
        bridge: bridge,
        sessionId: 'evidence-session',
        guidedTraining: false,
      );
      await coordinator.start();

      bridge.emit(
        _event(
          'start-evidence',
          'start_training',
          sessionId: 'evidence-session',
        ),
      );
      bridge.emit(
        _event(
          'prepared-evidence',
          'preparation_complete',
          sessionId: 'evidence-session',
        ),
      );
      bridge.emit(
        _event(
          'complete-evidence',
          'complete_set',
          sessionId: 'evidence-session',
          payload: const {
            'actual_reps': 9,
            'weight_kg': 62.5,
            'rir': 1,
            'rpe': 9,
            'pain_flag': true,
            'pain_area': '右肩',
            'recovery_score': 3,
          },
        ),
      );
      await _flushEvents();

      final recorded = log.recent.single;
      final set = recorded.exercises.single.sets.single;
      expect(set.reps, 9);
      expect(set.weightKg, 62.5);
      expect(set.rir, 1);
      expect(set.rpe, 9);
      expect(set.painArea, '右肩');
      expect(recorded.recoveryScore, 3);

      await coordinator.dispose();
      session.dispose();
    },
  );

  test(
    'Unity missing-value sentinels stay unknown instead of becoming zero',
    () async {
      final log = WorkoutLogController();
      await log.load();
      final session = WorkoutSessionController()
        ..attachLog(log)
        ..plans = const [SetPlan('push_up', '俯卧撑', 12)]
        ..startSession();
      final bridge = _FakeUnityRuntimeBridge();
      final coordinator = UnitySessionCoordinator(
        session: session,
        bridge: bridge,
        sessionId: 'sentinel-session',
        guidedTraining: false,
      );
      await coordinator.start();
      bridge.emit(
        _event(
          'start-sentinel',
          'start_training',
          sessionId: 'sentinel-session',
        ),
      );
      bridge.emit(
        _event(
          'prepared-sentinel',
          'preparation_complete',
          sessionId: 'sentinel-session',
        ),
      );
      bridge.emit(
        _event(
          'complete-sentinel',
          'complete_set',
          sessionId: 'sentinel-session',
          payload: const {
            'actual_reps': 12,
            'weight_kg': -1,
            'rir': -1,
            'rpe': -1,
            'recovery_score': -1,
          },
        ),
      );
      await _flushEvents();

      final recorded = log.recent.single;
      final set = recorded.exercises.single.sets.single;
      expect(set.weightKg, isNull);
      expect(set.rir, isNull);
      expect(set.rpe, isNull);
      expect(recorded.recoveryScore, isNull);

      await coordinator.dispose();
      session.dispose();
    },
  );
}

UnityRuntimeEvent _event(
  String eventId,
  String type, {
  String sessionId = 'session-1',
  Map<String, Object?> payload = const {},
}) {
  return UnityRuntimeEvent(
    type: type,
    eventId: eventId,
    sessionId: sessionId,
    occurredAtUtc: DateTime.utc(2026, 8, 29),
    payload: payload,
  );
}

Future<void> _flushEvents() => Future<void>.delayed(Duration.zero);

class _FakeUnityRuntimeBridge implements UnityRuntimeBridge {
  final StreamController<UnityRuntimeEvent> _events =
      StreamController<UnityRuntimeEvent>.broadcast();
  final List<UnityCommandEnvelope> commands = [];

  void emit(UnityRuntimeEvent event) => _events.add(event);

  @override
  Stream<UnityRuntimeEvent> get events => _events.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> prepare() async => true;

  @override
  Future<void> send(UnityCommandEnvelope command) async {
    commands.add(command);
  }

  @override
  Future<void> disposeSession(String sessionId) async {}
}
