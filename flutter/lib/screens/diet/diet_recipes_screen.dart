import 'package:flutter/material.dart';

import '../../models/meal.dart';
import '../../state/diet_log_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'diet_history_screen.dart';

/// Immersive Figma recipe presentation (199:300).
class DietRecipesScreen extends StatefulWidget {
  const DietRecipesScreen({super.key, required this.dietLog});
  final DietLogController dietLog;

  @override
  State<DietRecipesScreen> createState() => _DietRecipesScreenState();
}

class _DietRecipesScreenState extends State<DietRecipesScreen> {
  late final List<RecipeItem> _pool = widget.dietLog.goals.recommendedRecipes();
  late RecipeItem _recipe = _pool.first;
  bool _saved = false;

  Future<void> _save() async {
    await widget.dietLog.logRecipe(_recipe);
    if (mounted) setState(() => _saved = true);
  }

  void _nextRecipe() {
    final index = _pool.indexOf(_recipe);
    setState(() {
      _recipe = _pool[(index + 1) % _pool.length];
      _saved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF070908),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/diet/recipe-hero.png', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x33000000),
                  Color(0x08000000),
                  Color(0xF5000000),
                ],
                stops: [0, 0.34, 1],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _GlassButton(
                        icon: Icons.chevron_left,
                        onTap: () => Navigator.pop(context),
                      ),
                      Row(
                        children: [
                          _GlassButton(
                            icon: Icons.history,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    DietHistoryScreen(dietLog: widget.dietLog),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _GlassButton(
                            icon: Icons.more_horiz,
                            onTap: _nextRecipe,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.54),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _recipe.name,
                        style: const TextStyle(
                          fontFamily: AppFonts.inter,
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '按${widget.dietLog.goals.recipeGoal.label}计划推荐',
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandGreen,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          _recipe.goal.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _Meta(
                            icon: Icons.schedule,
                            label: '${_recipe.prepMinutes} min',
                          ),
                          const SizedBox(width: 14),
                          _Meta(
                            icon: Icons.fitness_center,
                            label: _recipe.difficulty,
                          ),
                          const SizedBox(width: 14),
                          _Meta(
                            icon: Icons.local_fire_department,
                            label: '${_recipe.kcal} kcal',
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        '营养信息',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _Nutrient(
                            label: '蛋白质',
                            value: '${_recipe.proteinG}g',
                          ),
                          _Nutrient(label: '碳水', value: '${_recipe.carbG}g'),
                          _Nutrient(label: '脂肪', value: '${_recipe.fatG}g'),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        '推荐理由',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _recipe.blurb,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saved ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandGreen,
                            disabledBackgroundColor: Colors.white24,
                            foregroundColor: AppColors.ink,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            _saved ? '已记录到今日饮食' : '记录这份食谱',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
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

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white30),
      ),
      child: Icon(icon, size: 21, color: Colors.white),
    ),
  );
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 15, color: Colors.white),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
    ],
  );
}

class _Nutrient extends StatelessWidget {
  const _Nutrient({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 90,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white60),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppFonts.chakraPetch,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}
