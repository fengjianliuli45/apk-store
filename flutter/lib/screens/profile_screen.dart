import 'package:flutter/material.dart';

import '../state/settings_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import 'settings_screen.dart';

/// “我的”主界面，对应用户选定的个人中心参考图。
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.settings,
    required this.onLogout,
  });

  final SettingsController settings;
  final VoidCallback onLogout;

  static const _recent = [
    ('胸 · 推类', '42分钟  昨天'),
    ('夜跑 5.2km', '28分钟  周一'),
    ('腿 · 深蹲', '50分钟  周日'),
  ];

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: GradientBackground(
        showHudTexture: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          children: [
            _ProfileHeader(
              onOpenSettings: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      SettingsScreen(settings: settings, onLogout: onLogout),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _IdentityBlock(),
            const SizedBox(height: 14),
            const _PerformanceCard(),
            const SizedBox(height: 14),
            const _RecentTrainingCard(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '我的',
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: AppColors.ink,
          ),
        ),
        const Spacer(),
        Container(
          width: 52,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'ME',
            style: TextStyle(
              fontFamily: AppFonts.jetBrainsMono,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.4,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onOpenSettings,
          tooltip: '设置',
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            minimumSize: const Size(40, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(
            Icons.settings_outlined,
            size: 29,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _IdentityBlock extends StatelessWidget {
  const _IdentityBlock();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 68,
          height: 68,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.brandGreen,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.ink, width: 2),
          ),
          child: const Text(
            '源',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontWeight: FontWeight.bold,
              fontSize: 32,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 18),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '源雅女',
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '坚持训练 128 天',
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 282,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatBlock(value: '72次', label: '累计训练'),
              _StatBlock(value: '86时', label: '累计时长'),
              _StatBlock(value: '12.4k', label: '累计消耗'),
            ],
          ),
          SizedBox(height: 18),
          Divider(height: 1, color: Color(0x180D1112)),
          SizedBox(height: 18),
          Text(
            '体能维度雷达图',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.ink,
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: Image(
              image: AssetImage('assets/profile/fitness-radar.png'),
              fit: BoxFit.contain,
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
    return SizedBox(
      width: 88,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppFonts.inter,
              fontWeight: FontWeight.bold,
              fontSize: 23,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTrainingCard extends StatelessWidget {
  const _RecentTrainingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '最近训练记录',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          for (
            var index = 0;
            index < ProfileScreen._recent.length;
            index++
          ) ...[
            _RecentTrainingRow(
              title: ProfileScreen._recent[index].$1,
              meta: ProfileScreen._recent[index].$2,
            ),
            if (index != ProfileScreen._recent.length - 1)
              const SizedBox(height: 13),
          ],
        ],
      ),
    );
  }
}

class _RecentTrainingRow extends StatelessWidget {
  const _RecentTrainingRow({required this.title, required this.meta});

  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.brandGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: AppColors.ink,
            ),
          ),
        ),
        Text(
          meta,
          style: const TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
