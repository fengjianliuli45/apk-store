import 'package:flutter/material.dart';

import '../state/auth_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import 'otp_screen.dart';

/// Phone entry. There's no SMS provider wired up (see AuthController) so
/// "获取验证码" just moves to the OTP screen where the debug code works;
/// "跳过" bypasses login entirely for local testing.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth});

  final AuthController auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          children: [
            Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.bolt, color: AppColors.brandGreen),
                ),
                const SizedBox(height: 12),
                const Text('STOPWATCH', style: AppTextStyles.wordmark),
                const SizedBox(height: 4),
                const Text(
                  '用手机号开始训练',
                  style: TextStyle(fontFamily: AppFonts.inter, fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.ink),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Text('+86', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 16, color: AppColors.textMuted)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: '请输入手机号', border: InputBorder.none),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  final phone = _phoneController.text.trim().isEmpty ? '138 0013 0000' : _phoneController.text.trim();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OtpScreen(auth: widget.auth, phone: phone),
                    ),
                  );
                },
                child: const Text('获取验证码', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: widget.auth.skip,
              child: Text('跳过，先看看', style: TextStyle(fontFamily: AppFonts.inter, color: AppColors.textMuted)),
            ),
            const SizedBox(height: 8),
            Text(
              '继续即代表同意《用户协议》和《隐私政策》',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
