import 'package:flutter/material.dart';

enum PostTag { strength, cardio }

class SocialPost {
  SocialPost({
    required this.authorName,
    required this.initials,
    required this.avatarColor,
    required this.time,
    required this.tag,
    required this.title,
    required this.meta,
    this.likes = 0,
    this.liked = false,
    this.comments = 0,
  });

  final String authorName;
  final String initials;
  final Color avatarColor;
  final String time;
  final PostTag tag;
  final String title;
  final String meta;

  int likes;
  bool liked;
  int comments;
}
