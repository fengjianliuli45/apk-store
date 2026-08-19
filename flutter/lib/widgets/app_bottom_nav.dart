import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The 5-slot bottom bar that belongs to the social module only (screen
/// screen-social-feed, node 193:65): 训练 / 计划 / [center] / 社交 / 我的.
/// The center item is a fixed lime circle (matches Figma) whose action is
/// supplied by the caller — inside the social shell it pops back out to the
/// Home stopwatch screen. `currentIndex` only takes 0, 1, 3 or 4; the center
/// slot has no tab of its own.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.onCenterTap,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onCenterTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavTab(
                icon: Icons.fitness_center,
                label: '训练',
                selected: currentIndex == 0,
                onTap: () => onSelect(0),
              ),
              _NavTab(
                icon: Icons.calendar_today,
                label: '计划',
                selected: currentIndex == 1,
                onTap: () => onSelect(1),
              ),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: onCenterTap,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: AppColors.brandGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.school,
                        color: AppColors.ink,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              _NavTab(
                icon: Icons.groups,
                label: '社交',
                selected: currentIndex == 3,
                onTap: () => onSelect(3),
              ),
              _NavTab(
                icon: Icons.person,
                label: '我的',
                selected: currentIndex == 4,
                onTap: () => onSelect(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.ink : AppColors.textMuted;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 3),
            Text(
              label,
              style: (selected
                      ? AppTextStyles.navLabelSelected
                      : AppTextStyles.navLabel)
                  .copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
