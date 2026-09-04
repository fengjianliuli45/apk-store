import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rest_pod_hud/state/workout_session_controller.dart';
import 'package:rest_pod_hud/unity/unity_protocol.dart';

void main() {
  test('Unity command envelope contains required ordering fields', () {
    final command = UnityCommandEnvelope(
      eventId: 'event-1',
      sessionId: 'session-1',
      occurredAtUtc: DateTime.utc(2026, 8, 27, 8, 0),
      sequence: 7,
      type: UnityCommandType.setStage,
      payload: const {'mode': 'training', 'exerciseId': 'bodyweight_squat'},
    );

    final json = jsonDecode(command.encode()) as Map<String, dynamic>;
    expect(json['protocol_version'], unityProtocolVersion);
    expect(json['event_id'], 'event-1');
    expect(json['session_id'], 'session-1');
    expect(json['sequence'], 7);
    expect(json['type'], 'set_stage');
    expect(json['occurred_at_utc'], '2026-08-27T08:00:00.000Z');
    expect((json['payload'] as Map)['exerciseId'], 'bodyweight_squat');
  });

  test('Unity runtime event decoder preserves protocol metadata', () {
    final event = UnityRuntimeEvent.decode(
      jsonEncode({
        'event_id': 'unity-1',
        'session_id': 'session-1',
        'occurred_at_utc': '2026-08-27T08:00:01.000Z',
        'protocol_version': '1.0',
        'type': 'unity_ready',
        'payload': {'scene': 'SquatTraining'},
      }),
    );

    expect(event.type, 'unity_ready');
    expect(event.sessionId, 'session-1');
    expect(event.payload['scene'], 'SquatTraining');
  });

  test('fallback workout exposes stable Unity exercise ids', () {
    final session = WorkoutSessionController()..startSession();
    expect(session.exerciseId, 'bodyweight_squat');
    expect(session.nextExerciseId, 'bodyweight_squat');

    session.startSet();
    session.completeSet();
    session.startNextSetNow();
    session.completeSet();
    session.startNextSetNow();
    expect(session.exerciseId, 'push_up');
    session.dispose();
  });
}
