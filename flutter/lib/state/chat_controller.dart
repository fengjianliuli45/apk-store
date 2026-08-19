import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat.dart';
import '../theme/app_colors.dart';

/// Local conversation list + thread storage. No realtime backend (see
/// FEATURE_PLAN.md — Stream Chat is explicitly out for now); messages are
/// persisted per-device via shared_preferences.
class ChatController extends ChangeNotifier {
  static const _prefsKey = 'chat_conversations_v1';

  final List<Conversation> conversations = [
    Conversation(
      id: 'linchen',
      name: '林晨',
      initials: 'LC',
      avatarColor: AppColors.brandGreen,
      messages: [
        ChatMessage(text: '明天一起练胸？', fromMe: false, timestampMs: DateTime.now().subtract(const Duration(hours: 5)).millisecondsSinceEpoch),
        ChatMessage(text: '好啊，几点', fromMe: true, timestampMs: DateTime.now().subtract(const Duration(hours: 4, minutes: 50)).millisecondsSinceEpoch),
      ],
    ),
    Conversation(
      id: 'chenke',
      name: '陈可',
      initials: 'CK',
      avatarColor: AppColors.cardioBlue,
      messages: [
        ChatMessage(text: '今天夜跑 5 公里，配速稳', fromMe: false, timestampMs: DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch),
      ],
    ),
  ];

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      final Map<String, dynamic> stored = jsonDecode(raw) as Map<String, dynamic>;
      for (final conversation in conversations) {
        final messagesJson = stored[conversation.id] as List<dynamic>?;
        if (messagesJson == null) continue;
        conversation.messages
          ..clear()
          ..addAll(messagesJson.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>)));
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {for (final c in conversations) c.id: c.messages.map((m) => m.toJson()).toList()};
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  Future<void> sendMessage(Conversation conversation, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    conversation.messages.add(ChatMessage(text: trimmed, fromMe: true, timestampMs: DateTime.now().millisecondsSinceEpoch));
    notifyListeners();
    await _persist();
  }
}
