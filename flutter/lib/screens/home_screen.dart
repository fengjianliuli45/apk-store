import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../state/diet_log_controller.dart';
import '../state/workout_log_controller.dart';
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
    required this.workoutLog,
    required this.plannedDaysPerWeek,
    required this.onOpenProfile,
    required this.onOpenSocial,
    required this.onEditPlan,
  });

  final WorkoutSessionController session;
  final DietLogController dietLog;
  final WorkoutLogController workoutLog;
  final int plannedDaysPerWeek;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenSocial;
  final VoidCallback onEditPlan;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _enterPod() {
    if (!widget.session.canStart) return;
    if (widget.session.canStart && widget.session.phase == WorkoutPhase.idle) {
      widget.session.startSession();
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
          MaterialPageRoute(
            builder: (_) => DietCaptureScreen(dietLog: widget.dietLog),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: AnimatedBuilder(
        animation: Listenable.merge([widget.session, widget.workoutLog]),
        builder: (context, _) {
          final session = widget.session;
          final weekProgress = widget.workoutLog.weekProgress(
            plannedDays: widget.plannedDaysPerWeek,
          );
          final ringProgress = session.phase == WorkoutPhase.idle
              ? weekProgress
              : session.ringProgress;
          return GradientBackground(
            showHudTexture: true,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('STOPWATCH', style: AppTextStyles.wordmark),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandGreen,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x3D6B9E00),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          session.phaseLabel,
                          style: AppTextStyles.ready,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 1,
                  color: AppColors.ink.withValues(alpha: 0.10),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    children: [
                      Text(
                        '当前训练计时',
                        style: const TextStyle(
                          fontFamily: AppFonts.jetBrainsMono,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 1.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(session.timerText, style: AppTextStyles.timer),
                      const SizedBox(height: 6),
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: GestureDetector(
                    onTap: _enterPod,
                    onLongPress: session.phase == WorkoutPhase.idle
                        ? null
                        : session.stopWorkout,
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(220, 220),
                            painter: DualRingPainter(progress: ringProgress),
                          ),
                          Container(
                            width: 134,
                            height: 132,
                            decoration: BoxDecoration(
                              color: AppColors.brandGreen,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x3D6B9E00),
                                  blurRadius: 24,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  'assets/figma-home/dumbbell.svg',
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  session.isRestDay
                                      ? '今日休息'
                                      : session.phase == WorkoutPhase.idle
                                      ? '开始训练'
                                      : '继续训练',
                                  style: const TextStyle(
                                    fontFamily: AppFonts.chakraPetch,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  session.phase == WorkoutPhase.idle
                                      ? session.previewCue
                                      : '长按结束训练',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppFonts.jetBrainsMono,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 8,
                                    letterSpacing: 0.2,
                                    color: AppColors.textMuted,
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
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: GestureDetector(
                    onTap: widget.onEditPlan,
                    child: Text(
                      '填写规划数据',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.ink.withValues(alpha: 0.72),
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.ink.withValues(alpha: 0.32),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: VoiceBar(onCommand: _handleVoiceCommand),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                DietCaptureScreen(dietLog: widget.dietLog),
                          ),
                        ),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.58),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.ink.withValues(alpha: 0.08),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/figma-home/camera.svg',
                                width: 18,
                                height: 18,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                '拍照',
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 8,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onOpenProfile,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.brandGreen,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x3D6B9E00),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/figma-home/user.svg',
                                width: 18,
                                height: 18,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                '我的',
                                style: TextStyle(
                                  fontFamily: AppFonts.inter,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 8,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}
