import 'package:flutter/material.dart';

import '../models/social_post.dart';
import '../state/social_feed_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';

/// Full comment thread for a single post: list + inline composer, backed by
/// [SocialFeedController] so counts stay in sync with the feed card.
class PostCommentsScreen extends StatefulWidget {
  const PostCommentsScreen({
    super.key,
    required this.controller,
    required this.post,
  });

  final SocialFeedController controller;
  final SocialPost post;

  @override
  State<PostCommentsScreen> createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends State<PostCommentsScreen> {
  final _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _send() {
    if (_inputController.text.trim().isEmpty) return;
    setState(() {
      widget.controller.addComment(widget.post, _inputController.text);
      _inputController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final comments = widget.post.comments;
    return GradientBackground(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: AppColors.ink, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Text('${widget.post.authorName} 的评论', style: AppTextStyles.screenTitle),
              ],
            ),
          ),
          Expanded(
            child: comments.isEmpty
                ? Center(
                    child: Text(
                      '还没有评论，说点什么吧',
                      style: TextStyle(fontFamily: AppFonts.inter, color: AppColors.textMuted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: comments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(comment.authorName, style: AppTextStyles.cardName),
                                Text(comment.time, style: AppTextStyles.cardTime),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              comment.text,
                              style: const TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 14,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
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
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: '说点什么',
                        border: InputBorder.none,
                      ),
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
                    decoration: const BoxDecoration(
                      color: AppColors.brandGreen,
                      shape: BoxShape.circle,
                    ),
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
