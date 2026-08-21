import 'package:flutter/material.dart';

import '../../data/diet_catalog.dart';
import '../../models/meal.dart';
import '../../planner/plan_sync.dart';
import '../../state/diet_log_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'diet_history_screen.dart';
import 'diet_recipes_screen.dart';

/// Figma screen-analysis (199:109) and confirmation sheet (199:180).
class DietEstimateSheet extends StatefulWidget {
  const DietEstimateSheet({
    super.key,
    required this.dietLog,
    required this.initial,
    required this.onReroll,
    required this.onConfirm,
    required this.onManualPick,
  });

  final DietLogController dietLog;
  final MealTemplate initial;
  final MealTemplate Function() onReroll;
  final Future<LoggedMeal> Function(MealTemplate template) onConfirm;
  final VoidCallback onManualPick;

  @override
  State<DietEstimateSheet> createState() => _DietEstimateSheetState();
}

class _DietEstimateSheetState extends State<DietEstimateSheet> {
  late MealTemplate _template = widget.initial;
  bool _saving = false;

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() => _saving = true);
    await widget.onConfirm(_template);
    if (!mounted) return;
    setState(() => _saving = false);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SuccessSheet(
        template: _template,
        goals: widget.dietLog.goals,
        onContinue: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
        onReturn: () => Navigator.pop(context),
      ),
    );
  }

  (Color, String) _look(MacroLevel level) => switch (level) {
        MacroLevel.low => (const Color(0xFFD98C1A), '偏低'),
        MacroLevel.ok => (const Color(0xFF5C9926), '达标'),
        MacroLevel.high => (const Color(0xFFC44B3A), '偏高'),
      };

  @override
  Widget build(BuildContext context) {
    final goals = widget.dietLog.goals;
    final today = widget.dietLog.todayKcal + _template.kcal;
    final todayProtein = widget.dietLog.todayProtein + _template.proteinG;
    final todayCarbs = widget.dietLog.todayCarbs + _template.carbG;
    final todayFat = widget.dietLog.todayFat + _template.fatG;
    final progress = (today / goals.kcal.clamp(1, 1 << 31)).clamp(0.0, 1.0);
    final kcalLook = _look(DietCatalog.levelOf(today, goals.kcal));
    final proteinLook = _look(DietCatalog.levelOf(todayProtein, goals.proteinG));
    final carbLook = _look(DietCatalog.levelOf(todayCarbs, goals.carbG));
    final fatLook = _look(DietCatalog.levelOf(todayFat, goals.fatG));
    final slotMeal = goals.mealForSlot(_template.slot);
    final foodExample = goals.foodExampleFor(_template.slot);
    return _DietGradient(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '饮食分析',
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: AppColors.ink,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: '推荐食谱',
                        icon: const Icon(Icons.restaurant_menu, size: 21),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                DietRecipesScreen(dietLog: widget.dietLog),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '饮食记录',
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                DietHistoryScreen(dietLog: widget.dietLog),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        Image.asset(
                          'assets/diet/analysis-meal.png',
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 79,
                          child: Container(
                            height: 2,
                            decoration: const BoxDecoration(
                              color: AppColors.brandGreen,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandGreen,
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '● AI SCANNING COMPLETE',
                              style: TextStyle(
                                fontFamily: AppFonts.jetBrainsMono,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: AppColors.brandGreen,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('AI 识别结果', style: TextStyle(fontSize: 14)),
                            Text(
                              '置信度 98%',
                              style: TextStyle(
                                fontFamily: AppFonts.jetBrainsMono,
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final item in _template.items)
                              _FoodChip(label: item),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 16),
                            SizedBox(width: 6),
                            Text('AI 饮食建议', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• ${_template.tip}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                            height: 1.45,
                          ),
                        ),
                        if (slotMeal != null)
                          Text(
                            '• 本餐计划：${slotMeal.name} ${slotMeal.kcal.round()} kcal，蛋白 ${slotMeal.proteinG.round()}g',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              height: 1.45,
                            ),
                          ),
                        if (foodExample != null)
                          Text(
                            '• 蛋白来源参考：$foodExample',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              height: 1.45,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MacroTile(
                          label: '热量',
                          status: kcalLook.$2,
                          color: kcalLook.$1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MacroTile(
                          label: '蛋白质',
                          status: proteinLook.$2,
                          color: proteinLook.$1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MacroTile(
                          label: '碳水',
                          status: carbLook.$2,
                          color: carbLook.$1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MacroTile(
                          label: '脂肪',
                          status: fatLook.$2,
                          color: fatLook.$1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Card(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '今日摄入进度',
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              '$today / ${goals.kcal} kcal',
                              style: const TextStyle(
                                fontFamily: AppFonts.chakraPetch,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFF2F5F4),
                            color: AppColors.brandGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _OutlineButton(
                      label: '重新拍摄',
                      onTap: () =>
                          setState(() => _template = widget.onReroll()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PrimaryButton(
                      label: _saving ? '记录中…' : '确认记录',
                      onTap: _confirm,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessSheet extends StatelessWidget {
  const _SuccessSheet({
    required this.template,
    required this.goals,
    required this.onContinue,
    required this.onReturn,
  });
  final MealTemplate template;
  final DietGoals goals;
  final VoidCallback onContinue;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.70,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: AppColors.brandGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x667EDC00),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(Icons.check, size: 42, color: AppColors.ink),
          ),
          const SizedBox(height: 14),
          const Text(
            '记录成功！',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          Text(
            '已记录至今日${template.slot.label}',
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 22),
          _Card(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/diet/meal-thumb.png',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              template.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Text(
                            '${template.kcal} kcal',
                            style: const TextStyle(
                              fontFamily: AppFonts.chakraPetch,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: [
                          _MiniTag('热量${DietCatalog.levelOf(template.kcal, goals.kcalForSlot(template.slot)).label}'),
                          _MiniTag('蛋白质${DietCatalog.levelOf(template.proteinG, goals.proteinG ~/ 4).label}'),
                          _MiniTag('碳水${DietCatalog.levelOf(template.carbG, goals.carbG ~/ 4).label}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.brandGreen.withValues(alpha: 0.10),
              border: Border.all(
                color: AppColors.brandGreen.withValues(alpha: 0.35),
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'AI 饮食助手建议',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  template.tip,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _OutlineButton(label: '继续拍照', onTap: onContinue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PrimaryButton(label: '返回饮食分析', onTap: onReturn),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DietGradient extends StatelessWidget {
  const _DietGradient({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE2ECE9), Color(0xFFFAFAF8), Colors.white],
          stops: [0, 0.6, 1],
        ),
      ),
      child: child,
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D0D1112),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class _FoodChip extends StatelessWidget {
  const _FoodChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F5F4),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '●',
          style: TextStyle(color: AppColors.brandGreen, fontSize: 10),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({
    required this.label,
    required this.status,
    required this.color,
  });
  final String label;
  final String status;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D0D1112),
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppFonts.jetBrainsMono,
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          status,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 24,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    ),
  );
}

class _MiniTag extends StatelessWidget {
  const _MiniTag(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F5F4),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
    ),
  );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onTap,
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.brandGreen,
      foregroundColor: AppColors.ink,
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.ink,
      side: const BorderSide(color: AppColors.ink),
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}
