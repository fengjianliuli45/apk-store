import 'package:flutter/material.dart';

/// Tokens sampled from the Figma file (Stopwatch App - Rest Pod HUD Master
/// Screens, node 193:65 "screen-social-feed") and carried over from the
/// original Compose implementation.
class AppColors {
  AppColors._();

  static const brandGreen = Color(0xFFBAFF00);
  static const ink = Color(0xFF0D1112);
  static const textMuted = Color(0x8F0D1112); // rgba(13,17,18,0.56)

  static const gradientTop = Color(0xFFE5F0F0);
  static const gradientMid = Color(0xFFC7D4CF);
  static const gradientBottom = Color(0xFFEDE8D9);

  static const cardioBlue = Color(0xFFC1EAF5);
  static const likeRed = Color(0xFFE5484D);

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientTop, gradientMid, gradientBottom],
    stops: [0.0, 0.5, 1.0],
  );
}
