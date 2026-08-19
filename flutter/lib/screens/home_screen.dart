import 'package:flutter/material.dart';

import '../state/diet_log_controller.dart';
import '../state/workout_session_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/dual_ring_painter.dart';
import '../widgets/gradient_background.dart';
import '../widgets/voice_bar.dart';
import 'diet/diet_capture_screen.dart';
import 'placeholder_screens.dart';

/// Home (screen home-with-fab, node 207:236) is the app root — a standalone
/// module with no bottom tab bar, just the two corner FABs that push into
/// 我的 and 饮食, plus a bare home-indicator strip at the bottom.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.session,
    required this.dietLog,
    required this.onOpenProfile,
    required this.onOpenSocial,
  });

  final WorkoutSessionController session;
  final DietLogController dietLog;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenSocial;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _enterPod() {
    if (widget.session.phase == WorkoutPhase.idle) {
      widget.session.startSession();
      widget.session.startSet();
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UnityCoachPlaceholderScreen(session: widget.session),
      ),
    );
  }

  void _handleVoiceCommand(VoiceCommand command) {
    switch (command) {
      case VoiceCommand.startTraining:
        _enterPod();
      case VoiceCommand.openSocial:
        widget.onOpenSocial();
      case VoiceCommand.openDiet:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DietCaptureScreen(dietLog: widget.dietLog)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final session = widget.session;
        return GradientBackground(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('STOPWATCH', style: AppTextStyles.wordmark),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.brandGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(session.phaseLabel, style: AppTextStyles.ready),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 28),
                child: Column(
                  children: [
                    Text(
                      '当前训练计时',
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(session.timerText, style: AppTextStyles.timer),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 28),
                child: GestureDetector(
                  onTap: _enterPod,
                  onLongPress: session.phase == WorkoutPhase.idle ? null : session.abortWorkout,
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(220, 220),
                          painter: DualRingPainter(progress: session.ringProgress),
                        ),
                        Container(
                          width: 168,
                          height: 168,
                          decoration: const BoxDecoration(
                            color: AppColors.brandGreen,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.fitness_center, color: AppColors.ink, size: 26),
                              const SizedBox(height: 6),
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
                                session.phase == WorkoutPhase.idle ? '轻触进入训练舱' : '长按结束训练',
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontSize: 11,
                                  color: AppColors.ink.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: VoiceBar(onCommand: _handleVoiceCommand),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => DietCaptureScreen(dietLog: widget.dietLog)),
                      ),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.brandGreen, width: 1.5),
                        ),
                        child: const Icon(Icons.camera_alt, color: AppColors.ink, size: 20),
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onOpenProfile,
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
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: 134,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.ink.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
