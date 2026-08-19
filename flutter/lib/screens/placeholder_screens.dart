import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/gradient_background.dart';

/// Pushed when the user taps "开始训练". The real training-pod experience
/// is a native Unity 3D scene built and wired up by a separate host project
/// — it is intentionally NOT reimplemented here. This screen only marks the
/// hookup point.
class UnityCoachPlaceholderScreen extends StatelessWidget {
  const UnityCoachPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Column(
        children: [
          _BackBar(title: '训练舱'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.brandGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.view_in_ar,
                    color: AppColors.ink,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Unity 训练舱接入点',
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '3D 教练与训练舱场景由本机 Unity 工程独立接入，\n此处仅作为 Flutter 侧的占位跳转页。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 13,
                    height: 1.6,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class CameraPlaceholderScreen extends StatelessWidget {
  const CameraPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Column(
        children: [
          _BackBar(title: '饮食打卡'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.brandGreen, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.ink,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '相机功能开发中',
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '拍照识别与饮食打卡即将上线',
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

/// Simple tab-body placeholder shared by the 训练 and 计划 root tabs, which
/// are out of scope for this pass — only home / 社交圈 / 我的 are fully built.
class TabPlaceholderScreen extends StatelessWidget {
  const TabPlaceholderScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tabIndex,
    required this.onSelectTab,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final int tabIndex;
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Text(title, style: AppTextStyles.screenTitle),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 40, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppBottomNav(currentIndex: tabIndex, onSelect: onSelectTab),
        ],
      ),
    );
  }
}

class _BackBar extends StatelessWidget {
  const _BackBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          Text(title, style: AppTextStyles.screenTitle),
        ],
      ),
    );
  }
}
