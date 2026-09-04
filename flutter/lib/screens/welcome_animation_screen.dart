import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../state/goal_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';

/// Plays a MiniMax-generated welcome clip picked by [goal]. Until that
/// clip exists at the paths below, falls back to a simple pulsing icon so
/// the flow still works end to end — see assets/videos/README.md.
class WelcomeAnimationScreen extends StatefulWidget {
  const WelcomeAnimationScreen({
    super.key,
    required this.goal,
    required this.onDone,
  });

  final FitnessGoal goal;
  final VoidCallback onDone;

  static const assetForGoal = {
    FitnessGoal.weightLoss: 'assets/videos/goal_weight_loss.mp4',
    FitnessGoal.muscleGain: 'assets/videos/goal_muscle_gain.mp4',
    FitnessGoal.toning: 'assets/videos/goal_toning.mp4',
    FitnessGoal.endurance: 'assets/videos/goal_endurance.mp4',
    FitnessGoal.recovery: 'assets/videos/goal_recovery.mp4',
  };

  @override
  State<WelcomeAnimationScreen> createState() => _WelcomeAnimationScreenState();
}

class _WelcomeAnimationScreenState extends State<WelcomeAnimationScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _video;
  late final AnimationController _pulse;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    final path = WelcomeAnimationScreen.assetForGoal[widget.goal]!;
    VideoPlayerController? controller;
    try {
      // Avoid asking the platform video player to open a known-missing
      // placeholder. That fallback works visually but produces a native
      // FileNotFoundException in release diagnostics.
      await rootBundle.load(path);
      controller = VideoPlayerController.asset(path);
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      controller.addListener(_onVideoTick);
      setState(() => _video = controller);
      controller.play();
    } catch (_) {
      // Placeholder file missing/empty until the real clip is generated.
      // Fall back to the pulsing icon instead of touching the native player.
      await controller?.dispose();
    }
  }

  void _onVideoTick() {
    final value = _video?.value;
    if (value == null || _done) return;
    if (value.isInitialized && value.position >= value.duration) {
      _finish();
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _video?.removeListener(_onVideoTick);
    _video?.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          children: [
            const Spacer(),
            AspectRatio(
              aspectRatio: 9 / 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _buildAnimation(),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.goal.welcomeCopy,
              style: AppTextStyles.cardTitle,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _finish,
                child: const Text(
                  '进入 App',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimation() {
    final controller = _video;
    if (controller != null && controller.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final scale = 0.9 + _pulse.value * 0.1;
        return Container(
          color: AppColors.ink,
          alignment: Alignment.center,
          child: Transform.scale(
            scale: scale,
            child: Icon(
              widget.goal.welcomeIcon,
              color: AppColors.brandGreen,
              size: 96,
            ),
          ),
        );
      },
    );
  }
}

extension _WelcomeGoalContent on FitnessGoal {
  String get welcomeCopy => switch (this) {
    FitnessGoal.weightLoss => '欢迎开启减脂计划 🔥',
    FitnessGoal.muscleGain => '欢迎踏上增肌之路 💪',
    FitnessGoal.toning => '欢迎开始塑形训练 ✨',
    FitnessGoal.endurance => '欢迎提升你的体能 🏃',
    FitnessGoal.recovery => '欢迎开始恢复训练 🌿',
  };

  IconData get welcomeIcon => switch (this) {
    FitnessGoal.weightLoss => Icons.local_fire_department,
    FitnessGoal.muscleGain => Icons.fitness_center,
    FitnessGoal.toning => Icons.auto_awesome,
    FitnessGoal.endurance => Icons.directions_run,
    FitnessGoal.recovery => Icons.spa,
  };
}
