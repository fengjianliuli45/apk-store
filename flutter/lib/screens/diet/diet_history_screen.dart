import 'package:flutter/material.dart';

import '../../models/meal.dart';
import '../../state/diet_log_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/back_bar.dart';
import '../../widgets/gradient_background.dart';

class DietHistoryScreen extends StatelessWidget {
  const DietHistoryScreen({super.key, required this.dietLog});

  final DietLogController dietLog;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: dietLog,
      builder: (context, _) {
        final meals = dietLog.meals;
        final grouped = <String, List<LoggedMeal>>{};
        for (final meal in meals) {
          grouped.putIfAbsent(meal.dayKey, () => []).add(meal);
        }
        final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
        return GradientBackground(
          child: Column(
            children: [
              const BackBar(title: '饮食记录'),
              Expanded(
                child: meals.isEmpty
                    ? Center(
                        child: Text('还没有打卡记录', style: TextStyle(fontFamily: AppFonts.inter, color: AppColors.textMuted)),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          for (final day in days) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(day, style: const TextStyle(fontFamily: AppFonts.jetBrainsMono, fontWeight: FontWeight.w600, color: AppColors.ink)),
                                  Text(
                                    '${grouped[day]!.fold(0, (sum, m) => sum + m.kcal)} kcal',
                                    style: AppTextStyles.cardStat,
                                  ),
                                ],
                              ),
                            ),
                            for (final meal in grouped[day]!)
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(meal.name, style: AppTextStyles.cardName),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppColors.brandGreen.withValues(alpha: 0.35),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(meal.source.label, style: const TextStyle(fontFamily: AppFonts.inter, fontSize: 10, color: AppColors.ink)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text('${meal.slot.label} · ${meal.kcal} kcal', style: AppTextStyles.cardMeta),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 6),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
