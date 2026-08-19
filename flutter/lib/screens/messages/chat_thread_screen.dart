import 'package:flutter/material.dart';

import '../../models/chat.dart';
import '../../state/chat_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/back_bar.dart';
import '../../widgets/gradient_background.dart';

/// Single-thread bubble UI, structured like a typical MIT-licensed Flutter
/// chat sample (list + trailing composer) — local storage only, see
/// ChatController.
class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({super.key, required this.chat, required this.conversation});

  final ChatController chat;
  final Conversation conversation;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_inputController.text.trim().isEmpty) return;
    await widget.chat.sendMessage(widget.conversation, _inputController.text);
    _inputController.clear();
    setState(() {});
  }

  String _formatTime(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.conversation.messages;
    return GradientBackground(
      child: Column(
        children: [
          BackBar(title: widget.conversation.name),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[messages.length - 1 - index];
                return Align(
                  alignment: message.fromMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: message.fromMe ? AppColors.brandGreen : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(message.fromMe ? 18 : 4),
                        bottomRight: Radius.circular(message.fromMe ? 4 : 18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(message.text, style: const TextStyle(fontFamily: AppFonts.inter, color: AppColors.ink)),
                        const SizedBox(height: 4),
                        Text(_formatTime(message.timestampMs), style: AppTextStyles.cardTime),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(hintText: '发消息', border: InputBorder.none),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(color: AppColors.brandGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.send, color: AppColors.ink, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
