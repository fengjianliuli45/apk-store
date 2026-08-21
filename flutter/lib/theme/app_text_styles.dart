import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Font families bundled as OFL assets so text renders exactly as specified
/// by Figma instead of falling back to system fonts.
class AppFonts {
  AppFonts._();

  static const inter = 'Inter';
  static const jetBrainsMono = 'JetBrainsMono';
  static const chakraPetch = 'ChakraPetch';
}

class AppTextStyles {
  AppTextStyles._();

  static const wordmark = TextStyle(
    fontFamily: AppFonts.chakraPetch,
    fontWeight: FontWeight.bold,
    letterSpacing: 1,
    fontSize: 16,
    color: AppColors.ink,
  );

  static const ready = TextStyle(
    fontFamily: AppFonts.jetBrainsMono,
    fontWeight: FontWeight.bold,
    fontSize: 10,
    letterSpacing: 0.5,
    color: AppColors.ink,
  );

  static const timer = TextStyle(
    fontFamily: AppFonts.jetBrainsMono,
    fontWeight: FontWeight.bold,
    fontSize: 48,
    color: AppColors.ink,
  );

  static const screenTitle = TextStyle(
    fontFamily: AppFonts.inter,
    fontWeight: FontWeight.w600,
    fontSize: 20,
    color: AppColors.ink,
  );

  static const socialPill = TextStyle(
    fontFamily: AppFonts.jetBrainsMono,
    fontSize: 10,
    letterSpacing: 1,
    color: AppColors.textMuted,
  );

  static const cardName = TextStyle(
    fontFamily: AppFonts.inter,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    color: AppColors.ink,
  );

  static const cardTime = TextStyle(
    fontFamily: AppFonts.jetBrainsMono,
    fontSize: 12,
    color: AppColors.textMuted,
  );

  static const cardTitle = TextStyle(
    fontFamily: AppFonts.inter,
    fontWeight: FontWeight.bold,
    fontSize: 17,
    color: AppColors.ink,
  );

  static const cardMeta = TextStyle(
    fontFamily: AppFonts.jetBrainsMono,
    fontSize: 13,
    color: AppColors.textMuted,
  );

  static const cardStat = TextStyle(
    fontFamily: AppFonts.jetBrainsMono,
    fontSize: 13,
    color: AppColors.textMuted,
  );

  static const tagLabel = TextStyle(
    fontFamily: AppFonts.inter,
    fontWeight: FontWeight.bold,
    fontSize: 10,
    letterSpacing: 0.5,
    color: AppColors.ink,
  );

  static const navLabel = TextStyle(
    fontFamily: AppFonts.inter,
    fontWeight: FontWeight.w500,
    fontSize: 11,
    color: AppColors.ink,
  );

  static const navLabelSelected = TextStyle(
    fontFamily: AppFonts.inter,
    fontWeight: FontWeight.bold,
    fontSize: 11,
    color: AppColors.ink,
  );
}
