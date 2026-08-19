import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../state/auth_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.auth, required this.phone});

  final AuthController auth;
  final String phone;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _codeController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final ok = await widget.auth.verifyOtp(widget.phone, _codeController.text.trim());
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      setState(() => _error = '验证码不对，再试试');
    }
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
                const SizedBox(height: 10),
                Text('已发送至 +86 ${widget.phone}', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: AppFonts.jetBrainsMono, fontSize: 22, letterSpacing: 8),
                decoration: const InputDecoration(counterText: '', border: InputBorder.none, hintText: '· · · · · ·'),
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Text(
                '调试模式验证码：${AuthController.debugOtp}',
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: AppColors.textMuted),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: AppColors.likeRed)),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _verify,
                child: const Text('验证并继续', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
