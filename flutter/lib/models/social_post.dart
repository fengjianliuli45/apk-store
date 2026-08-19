import 'package:flutter/material.dart';

enum PostTag { strength, cardio }

class Comment {
  Comment({
    required this.authorName,
    required this.text,
    required this.time,
  });

  final String authorName;
  final String text;
  final String time;
}

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
    List<Comment>? comments,
  }) : comments = comments ?? [];

  final String authorName;
  final String initials;
  final Color avatarColor;
  final String time;
  final PostTag tag;
  final String title;
  final String meta;

  int likes;
  bool liked;
  final List<Comment> comments;
}
