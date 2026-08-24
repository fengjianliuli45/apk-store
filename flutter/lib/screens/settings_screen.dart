import 'package:flutter/material.dart';

import '../state/auth_controller.dart';
import '../state/identity.dart';
import '../state/settings_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/back_bar.dart';
import '../widgets/gradient_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onLogout,
    this.auth,
    this.onEditPlan,
  });

  final SettingsController settings;
  final AuthController? auth;
  final VoidCallback onLogout;
  final VoidCallback? onEditPlan;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([settings, ?auth]),
      builder: (context, _) {
        return GradientBackground(
          child: Column(
            children: [
              const BackBar(title: '设置'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _GroupLabel('账号'),
                    _SectionCard(children: [
                      _NavRow(
                        label: '账号与安全',
                        value: auth?.phone == null ? '本地调试' : '已登录',
                        onTap: () => _showAccountInfo(context),
                      ),
                      _NavRow(label: '手机号', value: auth?.maskedPhone ?? '未绑定'),
                    ]),
                    _GroupLabel('训练'),
                    _SectionCard(children: [
                      _NavRow(
                        label: '规划数据',
                        value: '目标 / 身体 / 训练条件',
                        onTap: onEditPlan == null
                            ? null
                            : () {
                                Navigator.of(context).pop();
                                onEditPlan!();
                              },
                      ),
                      _SwitchRow(label: '训练提醒', value: settings.trainingReminder, onChanged: settings.setTrainingReminder),
                      _SwitchRow(label: '社交互动通知', value: settings.socialNotify, onChanged: settings.setSocialNotify),
                      _SwitchRow(label: '系统通知', value: settings.systemNotify, onChanged: settings.setSystemNotify),
                    ]),
                    _GroupLabel('隐私'),
                    _SectionCard(children: [
                      _NavRow(
                        label: '谁可以看我的动态',
                        value: settings.visibility.label,
                        onTap: () => _pickVisibility(context),
                      ),
                      _SwitchRow(label: '附近的人', value: settings.nearbyEnabled, onChanged: settings.setNearbyEnabled),
                    ]),
                    _GroupLabel('通用'),
                    _SectionCard(children: [
                      _SwitchRow(
                        label: '单位（公制）',
                        value: settings.metricUnits,
                        onChanged: settings.setMetricUnits,
                      ),
                      _NavRow(
                        label: '语言',
                        value: settings.language,
                        onTap: () => _pickLanguage(context),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    const Text('关于 Stopwatch', style: TextStyle(fontFamily: AppFonts.inter, color: AppColors.ink)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: onLogout,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.likeRed.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '退出登录',
                          style: TextStyle(fontFamily: AppFonts.inter, fontWeight: FontWeight.w600, color: AppColors.likeRed),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAccountInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '账号与安全',
                style: TextStyle(fontFamily: AppFonts.inter, fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.ink),
              ),
              const SizedBox(height: 10),
              Text(
                auth?.phone == null
                    ? '当前是跳过登录的本地调试会话，没有绑定手机号，也没有云端账号。'
                    : '手机号已保存在本机。验证码仍是调试码 ${AuthController.debugOtp}，还没有短信通道。',
                style: const TextStyle(fontFamily: AppFonts.inter, fontSize: 13, height: 1.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickVisibility(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in PostVisibility.values)
              ListTile(
                title: Text(option.label),
                trailing: option == settings.visibility ? const Icon(Icons.check, color: AppColors.brandGreen) : null,
                onTap: () {
                  settings.setVisibility(option);
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _pickLanguage(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in ['简体中文', 'English'])
              ListTile(
                title: Text(option),
                trailing: option == settings.language ? const Icon(Icons.check, color: AppColors.brandGreen) : null,
                onTap: () {
                  settings.setLanguage(option);
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: AppColors.textMuted)),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(children: children),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.label, this.value, this.onTap});

  final String label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontFamily: AppFonts.inter, color: AppColors.ink)),
            Row(
              children: [
                if (value != null) Text(value!, style: AppTextStyles.cardMeta),
                if (onTap != null) const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: AppFonts.inter, color: AppColors.ink)),
          Switch(value: value, activeThumbColor: AppColors.brandGreen, onChanged: onChanged),
        ],
      ),
    );
  }
}
