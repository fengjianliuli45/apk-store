import 'package:flutter/material.dart';

class ChatMessage {
  ChatMessage({required this.text, required this.fromMe, required this.timestampMs});

  final String text;
  final bool fromMe;
  final int timestampMs;

  Map<String, dynamic> toJson() => {'text': text, 'fromMe': fromMe, 'timestampMs': timestampMs};

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text'] as String,
        fromMe: json['fromMe'] as bool,
        timestampMs: json['timestampMs'] as int,
      );
}

class Conversation {
  Conversation({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.messages,
  });

  final String id;
  final String name;
  final String initials;
  final Color avatarColor;
  final List<ChatMessage> messages;

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;
}
