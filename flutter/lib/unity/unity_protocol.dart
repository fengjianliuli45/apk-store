import 'dart:convert';

const unityProtocolVersion = '1.0';

enum UnityCommandType {
  loadSession('load_session'),
  setStage('set_stage'),
  pause('pause'),
  resume('resume'),
  disposeSession('dispose_session');

  const UnityCommandType(this.wireName);
  final String wireName;
}

class UnityCommandEnvelope {
  const UnityCommandEnvelope({
    required this.eventId,
    required this.sessionId,
    required this.occurredAtUtc,
    required this.sequence,
    required this.type,
    required this.payload,
    this.protocolVersion = unityProtocolVersion,
  });

  final String eventId;
  final String sessionId;
  final DateTime occurredAtUtc;
  final int sequence;
  final UnityCommandType type;
  final Map<String, Object?> payload;
  final String protocolVersion;

  Map<String, Object?> toJson() => {
    'event_id': eventId,
    'session_id': sessionId,
    'occurred_at_utc': occurredAtUtc.toUtc().toIso8601String(),
    'protocol_version': protocolVersion,
    'sequence': sequence,
    'type': type.wireName,
    'payload': payload,
  };

  String encode() => jsonEncode(toJson());
}

class UnityRuntimeEvent {
  const UnityRuntimeEvent({
    required this.type,
    required this.eventId,
    required this.occurredAtUtc,
    this.sessionId = '',
    this.protocolVersion = unityProtocolVersion,
    this.payload = const {},
  });

  final String type;
  final String eventId;
  final String sessionId;
  final DateTime occurredAtUtc;
  final String protocolVersion;
  final Map<String, Object?> payload;

  factory UnityRuntimeEvent.decode(String encoded) {
    final json = jsonDecode(encoded) as Map<String, dynamic>;
    return UnityRuntimeEvent(
      type: json['type'] as String,
      eventId: json['event_id'] as String,
      sessionId: json['session_id'] as String? ?? '',
      occurredAtUtc: DateTime.parse(json['occurred_at_utc'] as String).toUtc(),
      protocolVersion:
          json['protocol_version'] as String? ?? unityProtocolVersion,
      payload: Map<String, Object?>.from(
        json['payload'] as Map? ?? const <String, Object?>{},
      ),
    );
  }
}
