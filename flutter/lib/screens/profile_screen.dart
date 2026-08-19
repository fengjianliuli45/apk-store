import 'package:flutter/material.dart';

import '../state/chat_controller.dart';
import '../state/diet_log_controller.dart';
import '../state/settings_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import 'diet/diet_history_screen.dart';
import 'diet/diet_recipes_screen.dart';
import 'messages/chat_list_screen.dart';
import 'nearby_screen.dart';
import 'settings_screen.dart';

/// "我的" — reached either by pushing this screen from Home's bottom-right
/// FAB ([onBack] set, shows a back arrow) or embedded as the social module's
/// last tab ([onBack] left null, no back arrow — the module's own bottom bar
/// is the way out). Never carries its own 5-tab bottom bar.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.dietLog,
    required this.chat,
    required this.settings,
    required this.onLogout,
    required this.onOpenSocial,
    this.onBack,
  });

  final DietLogController dietLog;
  final ChatController chat;
  final SettingsController settings;
  final VoidCallback onLogout;
  final VoidCallback onOpenSocial;
  final VoidCallback? onBack;

  static const _recent = [
    ('胸推 · 腿', '42:59'),
    ('夜跑 · 5.2km', '28:59'),
    ('深蹲', '50:59'),
  ];

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                if (onBack != null) ...[
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
                  const SizedBox(width: 12),
                ],
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.brandGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '源雅女',
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        '坚持训练 128 天',
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SettingsScreen(settings: settings, onLogout: onLogout)),
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), shape: BoxShape.circle),
                    child: const Icon(Icons.settings_outlined, color: AppColors.ink, size: 20),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _StatBlock(value: '72 次', label: '训练'),
                _StatBlock(value: '86 时', label: '时长'),
                _StatBlock(value: '12.4k', label: '消耗'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => DietHistoryScreen(dietLog: dietLog)),
                    ),
                    child: _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '饮食记录',
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            '查看今日餐次',
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => DietRecipesScreen(dietLog: dietLog)),
                    ),
                    child: _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '健康食谱',
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            '减脂 / 增肌 / 维持',
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: onOpenSocial,
              child: _SectionCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '社交圈',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          '看看好友的训练动态',
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '›',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ChatListScreen(chat: chat)),
                    ),
                    child: _SectionCard(
                      child: Row(
                        children: const [
                          Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.ink),
                          SizedBox(width: 8),
                          Text('消息', style: TextStyle(fontFamily: AppFonts.inter, fontWeight: FontWeight.w600, color: AppColors.ink)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NearbyScreen()),
                    ),
                    child: _SectionCard(
                      child: Row(
                        children: const [
                          Icon(Icons.place_outlined, size: 18, color: AppColors.ink),
                          SizedBox(width: 8),
                          Text('附近的人', style: TextStyle(fontFamily: AppFonts.inter, fontWeight: FontWeight.w600, color: AppColors.ink)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '最近训练记录',
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                for (final entry in _recent)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.$1, style: const TextStyle(fontFamily: AppFonts.inter, color: AppColors.ink)),
                        Text(entry.$2, style: const TextStyle(fontFamily: AppFonts.inter, color: AppColors.textMuted)),
                      ],
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

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppFonts.inter,
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.ink,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}
