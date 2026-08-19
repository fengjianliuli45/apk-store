import 'package:flutter/material.dart';

import '../../data/diet_catalog.dart';
import '../../models/meal.dart';
import '../../state/diet_log_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/back_bar.dart';
import '../../widgets/gradient_background.dart';

class DietRecipesScreen extends StatefulWidget {
  const DietRecipesScreen({super.key, required this.dietLog});

  final DietLogController dietLog;

  @override
  State<DietRecipesScreen> createState() => _DietRecipesScreenState();
}

class _DietRecipesScreenState extends State<DietRecipesScreen> {
  RecipeGoal _goal = RecipeGoal.recommend;

  @override
  Widget build(BuildContext context) {
    final recipes = DietCatalog.recipes.where((r) => r.goal == _goal).toList();
    return GradientBackground(
      child: Column(
        children: [
          const BackBar(title: '健康食谱'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                for (final goal in RecipeGoal.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _GoalChip(
                      label: goal.label,
                      selected: goal == _goal,
                      onTap: () => setState(() => _goal = goal),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final recipe in recipes)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipe.name, style: AppTextStyles.cardTitle),
                        const SizedBox(height: 4),
                        Text(recipe.items.join(' · '), style: AppTextStyles.cardMeta),
                        const SizedBox(height: 4),
                        Text(recipe.blurb, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${recipe.kcal} kcal', style: AppTextStyles.cardStat),
                            GestureDetector(
                              onTap: () async {
                                await widget.dietLog.logRecipe(recipe);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('已打卡：${recipe.name}')),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(color: AppColors.brandGreen, borderRadius: BorderRadius.circular(14)),
                                child: const Text('记为今日餐', style: TextStyle(fontFamily: AppFonts.inter, fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.ink)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandGreen : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: const TextStyle(fontFamily: AppFonts.inter, fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.ink)),
      ),
    );
  }
}
