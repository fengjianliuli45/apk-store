import 'package:flutter/material.dart';

import '../state/workout_session_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/back_bar.dart';
import '../widgets/gradient_background.dart';

/// Pushed when the user taps "开始训练". The real training-pod experience
/// (Ready / Active / Rest, 3D coach) is a native Unity scene built and wired
/// up by a separate host project — it is intentionally NOT reimplemented
/// here in Flutter widgets.
///
/// Hookup point for later: export the Unity project as an Android/iOS
/// library per `juicycleff/flutter_unity_widget`, then in this file swap the
/// icon placeholder below for a `UnityWidget`. Drive it from
/// [WorkoutSessionController] (already ported from the old Compose
/// `WorkoutSessionViewModel` state machine) — call
/// `UnityWidgetController.postMessage` on `startSet` / `completeSet` /
/// `addRestSeconds` / `skipRest` / `abortWorkout` so Flutter stays the single
/// timer source of truth and Unity only renders the scene.
class UnityCoachPlaceholderScreen extends StatelessWidget {
  const UnityCoachPlaceholderScreen({super.key, required this.session});

  final WorkoutSessionController session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        return GradientBackground(
          child: Column(
            children: [
              BackBar(title: '训练舱'),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        color: AppColors.brandGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.view_in_ar,
                        color: AppColors.ink,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Unity 训练舱接入点',
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '3D 教练与训练舱场景由本机 Unity 工程独立接入，\n此处仅作为 Flutter 侧的占位跳转页。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 13,
                        height: 1.6,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Text(
                            session.isRestDay
                                ? (session.sessionTitle.isEmpty ? '休息日' : session.sessionTitle)
                                : '${session.exerciseName} · 第 ${session.currentSet}/${session.totalSets} 组',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: AppFonts.inter,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            session.isRestDay ? '按计划恢复' : session.timerText,
                            style: AppTextStyles.timer.copyWith(fontSize: 28),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session.isRestDay ? '今日无训练组' : session.phaseLabel,
                            style: const TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: GestureDetector(
                  onTap: () {
                    session.abortWorkout();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '结束训练',
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
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
