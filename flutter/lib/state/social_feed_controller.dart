import 'package:flutter/material.dart';

import '../models/social_post.dart';
import '../theme/app_colors.dart';

/// Single in-memory source of truth for the social feed so likes/comments
/// and locally-composed posts survive switching tabs. No backend — this is
/// a local-only shell.
class SocialFeedController extends ChangeNotifier {
  final List<SocialPost> posts = [
    SocialPost(
      authorName: '林晨',
      initials: 'LC',
      avatarColor: AppColors.brandGreen,
      time: '今天 07:12',
      tag: PostTag.strength,
      title: '完成胸推日',
      meta: '4 组卧推 · 36 分钟',
      likes: 24,
      comments: [
        Comment(authorName: '陈可', text: '今天状态不错啊！', time: '07:20'),
        Comment(authorName: '阿宇', text: '卧推重量加了吗', time: '08:02'),
      ],
    ),
    SocialPost(
      authorName: '陈可',
      initials: 'CK',
      avatarColor: AppColors.cardioBlue,
      time: '昨天 21:40',
      tag: PostTag.cardio,
      title: '夜跑收工',
      meta: '5.2 km · 28:16',
      likes: 18,
      comments: [
        Comment(authorName: '林晨', text: '配速稳，带带我', time: '21:55'),
      ],
    ),
  ];

  void toggleLike(SocialPost post) {
    post.liked = !post.liked;
    post.likes += post.liked ? 1 : -1;
    notifyListeners();
  }

  void addComment(SocialPost post, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    post.comments.add(Comment(authorName: '我', text: trimmed, time: '刚刚'));
    notifyListeners();
  }

  void publish({
    required String title,
    required String meta,
    required PostTag tag,
  }) {
    posts.insert(
      0,
      SocialPost(
        authorName: '我',
        initials: '我',
        avatarColor: AppColors.brandGreen,
        time: '刚刚',
        tag: tag,
        title: title,
        meta: meta.trim().isEmpty ? '刚刚完成' : meta,
        likes: 0,
      ),
    );
    notifyListeners();
  }
}
