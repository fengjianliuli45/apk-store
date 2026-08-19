import 'package:flutter/material.dart';

import '../models/social_post.dart';
import '../state/social_feed_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/gradient_background.dart';
import 'post_comments_screen.dart';

class SocialFeedScreen extends StatelessWidget {
  const SocialFeedScreen({
    super.key,
    required this.controller,
    required this.onSelectTab,
    required this.onBack,
  });

  final SocialFeedController controller;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Stack(
        children: [
          Column(
            children: [
              _SocialTopBar(onBack: onBack),
              Expanded(
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    final posts = controller.posts;
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: posts.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        if (index == posts.length) {
                          return const SizedBox(height: 84);
                        }
                        final post = posts[index];
                        return _SocialPostCard(
                          post: post,
                          onToggleLike: () => controller.toggleLike(post),
                          onComment: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PostCommentsScreen(controller: controller, post: post),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              AppBottomNav(currentIndex: 3, onSelect: onSelectTab),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 96,
            child: GestureDetector(
              onTap: () => _showComposeDialog(context),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.brandGreen, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: AppColors.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComposeDialog(BuildContext context) {
    final titleController = TextEditingController();
    final metaController = TextEditingController();
    var tag = PostTag.strength;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                '发布动态',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: '标题'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: metaController,
                    decoration: const InputDecoration(labelText: '训练数据'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        '类型:',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 8),
                      _TagChip(
                        label: 'STRENGTH',
                        color: AppColors.brandGreen,
                        selected: tag == PostTag.strength,
                        onTap: () => setState(() => tag = PostTag.strength),
                      ),
                      const SizedBox(width: 6),
                      _TagChip(
                        label: 'CARDIO',
                        color: AppColors.cardioBlue,
                        selected: tag == PostTag.cardio,
                        onTap: () => setState(() => tag = PostTag.cardio),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: titleController,
                  builder: (context, value, _) {
                    return TextButton(
                      onPressed: value.text.trim().isEmpty
                          ? null
                          : () {
                              controller.publish(
                                title: titleController.text.trim(),
                                meta: metaController.text,
                                tag: tag,
                              );
                              Navigator.of(dialogContext).pop();
                            },
                      child: const Text('发布'),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _SocialTopBar extends StatelessWidget {
  const _SocialTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
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
              const Text('社交圈', style: AppTextStyles.screenTitle),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('SOCIAL', style: AppTextStyles.socialPill),
          ),
        ],
      ),
    );
  }
}

class _SocialPostCard extends StatelessWidget {
  const _SocialPostCard({
    required this.post,
    required this.onToggleLike,
    required this.onComment,
  });

  final SocialPost post;
  final VoidCallback onToggleLike;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    final tagColor = post.tag == PostTag.strength ? AppColors.brandGreen : AppColors.cardioBlue;
    final tagLabel = post.tag == PostTag.strength ? 'STRENGTH' : 'CARDIO';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: post.avatarColor, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      post.initials,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName, style: AppTextStyles.cardName),
                      Text(post.time, style: AppTextStyles.cardTime),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: tagColor, borderRadius: BorderRadius.circular(10)),
                child: Text(tagLabel, style: AppTextStyles.tagLabel),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(post.title, style: AppTextStyles.cardTitle),
          const SizedBox(height: 4),
          Text(post.meta, style: AppTextStyles.cardMeta),
          const SizedBox(height: 14),
          Divider(color: AppColors.ink.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: onToggleLike,
                child: Row(
                  children: [
                    Icon(
                      post.liked ? Icons.favorite : Icons.favorite_border,
                      color: post.liked ? AppColors.likeRed : AppColors.textMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text('${post.likes}', style: AppTextStyles.cardStat),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: onComment,
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: AppColors.textMuted, size: 18),
                    const SizedBox(width: 6),
                    Text('${post.comments.length}', style: AppTextStyles.cardStat),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
