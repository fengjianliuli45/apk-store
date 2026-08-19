import 'package:flutter/material.dart';

import '../data/training_catalog.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 训练 tab, embedded only inside the social module's bottom bar (screen
/// screen-social-feed, node 193:65) — never shown on Home. Today's plan
/// (from the fixed weekly sample) + a flat exercise library.
class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = TrainingCatalog.forDate(DateTime.now());
    return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [Text('训练', style: AppTextStyles.screenTitle)],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('今日计划 · ${today.title}', style: AppTextStyles.cardTitle),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: AppColors.brandGreen, borderRadius: BorderRadius.circular(10)),
                            child: const Text('今天', style: AppTextStyles.tagLabel),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (today.isRestDay)
                        Text('今天是休息日，好好恢复', style: TextStyle(fontFamily: AppFonts.inter, color: AppColors.textMuted))
                      else
                        for (final ex in today.exercises)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(ex.name, style: const TextStyle(fontFamily: AppFonts.inter, color: AppColors.ink)),
                                Text('${ex.sets} 组 × ${ex.reps}', style: AppTextStyles.cardMeta),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('动作库', style: TextStyle(fontFamily: AppFonts.inter, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const SizedBox(height: 10),
                for (final ex in TrainingCatalog.exerciseLibrary)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(color: AppColors.brandGreen.withValues(alpha: 0.4), shape: BoxShape.circle),
                              child: const Icon(Icons.fitness_center, size: 16, color: AppColors.ink),
                            ),
                            const SizedBox(width: 12),
                            Text(ex.name, style: AppTextStyles.cardName),
                          ],
                        ),
                        Text('${ex.sets} 组 × ${ex.reps}', style: AppTextStyles.cardMeta),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
    );
  }
}
