import 'dart:async';

import 'package:flutter/services.dart';

import 'unity_protocol.dart';

abstract interface class UnityRuntimeBridge {
  Stream<UnityRuntimeEvent> get events;

  Future<bool> isAvailable();
  Future<bool> prepare();
  Future<void> send(UnityCommandEnvelope command);
  Future<void> disposeSession(String sessionId);
}

class MethodChannelUnityRuntimeBridge implements UnityRuntimeBridge {
  MethodChannelUnityRuntimeBridge({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  }) : _methodChannel =
           methodChannel ?? const MethodChannel('com.restpod.hud/unity'),
       _eventChannel =
           eventChannel ?? const EventChannel('com.restpod.hud/unity_events');

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Stream<UnityRuntimeEvent>? _events;

  @override
  Stream<UnityRuntimeEvent> get events => _events ??= _eventChannel
      .receiveBroadcastStream()
      .where((event) => event is String)
      .cast<String>()
      .map(UnityRuntimeEvent.decode)
      .asBroadcastStream();

  @override
  Future<bool> isAvailable() async {
    try {
      return await _methodChannel.invokeMethod<bool>('isAvailable') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<bool> prepare() async {
    try {
      return await _methodChannel.invokeMethod<bool>('prepare') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> send(UnityCommandEnvelope command) async {
    await _methodChannel.invokeMethod<void>('send', command.encode());
  }

  @override
  Future<void> disposeSession(String sessionId) async {
    try {
      await _methodChannel.invokeMethod<void>('dispose', sessionId);
    } on MissingPluginException {
      // The Flutter-only build intentionally has no Unity runtime.
    }
  }
}
