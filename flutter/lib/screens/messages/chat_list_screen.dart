import 'package:flutter/material.dart';

import '../../state/chat_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/back_bar.dart';
import '../../widgets/gradient_background.dart';
import 'chat_thread_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key, required this.chat});

  final ChatController chat;

  String _formatTime(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: chat,
      builder: (context, _) {
        return GradientBackground(
          child: Column(
            children: [
              const BackBar(title: '消息'),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: chat.conversations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final conversation = chat.conversations[index];
                    final last = conversation.lastMessage;
                    return GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ChatThreadScreen(chat: chat, conversation: conversation)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: conversation.avatarColor, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Text(conversation.initials, style: const TextStyle(fontFamily: AppFonts.inter, fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.ink)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(conversation.name, style: AppTextStyles.cardName),
                                  const SizedBox(height: 2),
                                  Text(
                                    last?.text ?? '还没有消息',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.cardMeta,
                                  ),
                                ],
                              ),
                            ),
                            if (last != null)
                              Text(_formatTime(last.timestampMs), style: AppTextStyles.cardTime),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
