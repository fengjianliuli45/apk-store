import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/gradient_background.dart';
import 'placeholder_screens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onSelectTab,
  });

  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('STOPWATCH', style: AppTextStyles.wordmark),
                      Text('READY', style: AppTextStyles.ready),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Column(
              children: [
                const Text('00:00.00', style: AppTextStyles.timer),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const UnityCoachPlaceholderScreen(),
                    ),
                  ),
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: const BoxDecoration(
                      color: AppColors.brandGreen,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '开始训练',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          '点击进入准备',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 11,
                            color: AppColors.ink.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Text(
                  '有什么可以帮你的？',
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CameraPlaceholderScreen(),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.camera_alt,
                      color: AppColors.ink,
                      size: 24,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => onSelectTab(4),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.brandGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppBottomNav(currentIndex: AppBottomNav.homeIndex, onSelect: onSelectTab),
        ],
      ),
    );
  }
}
