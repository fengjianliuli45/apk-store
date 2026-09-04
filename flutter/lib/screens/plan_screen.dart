import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:table_calendar/table_calendar.dart';

import '../data/training_catalog.dart';
import '../planner/plan_adapter.dart';
import '../planner/plan_overview.dart';
import '../state/plan_controller.dart';
import '../state/workout_log_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'cycle_review_screen.dart';

/// 计划 tab: stage goal, weekly rhythm, today's session and the existing
/// month calendar. Cycle evidence opens a secondary page.
class PlanScreen extends StatefulWidget {
  const PlanScreen({
    super.key,
    required this.plan,
    required this.workoutLog,
    this.onEditPlan,
    this.onStartToday,
    this.onCycleCheckIn,
  });

  final PlanController plan;
  final WorkoutLogController workoutLog;
  final VoidCallback? onEditPlan;
  final VoidCallback? onStartToday;
  final ValueChanged<int>? onCycleCheckIn;

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.plan, widget.workoutLog]),
      builder: (context, _) {
        final generated = widget.plan.plan;
        final overview = generated == null
            ? null
            : PlanOverview.from(plan: generated, logs: widget.workoutLog.entries);
        final selectedPlan = generated != null
            ? dayWorkoutForDate(generated, _selectedDay)
            : TrainingCatalog.forDate(_selectedDay);
        bool isRestDay(DateTime date) => generated != null
            ? dayWorkoutForDate(generated, date).isRestDay
            : TrainingCatalog.forDate(date).isRestDay;

        return ListView(
          scrollCacheExtent: const ScrollCacheExtent.pixels(1400),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                const Expanded(child: Text('计划', style: AppTextStyles.screenTitle)),
                if (widget.onEditPlan != null)
                  IconButton(
                    tooltip: '调整计划',
                    onPressed: widget.onEditPlan,
                    icon: const Icon(Icons.add, color: AppColors.ink),
                  ),
              ],
            ),
            if (overview != null) ...[
              Text('阶段第 ${overview.currentWeek} / ${overview.cycleWeeks} 周', style: AppTextStyles.socialPill),
              const SizedBox(height: 14),
              _CycleCard(
                overview: overview,
                versionLabel: widget.plan.versionLabel,
                plannerVersion: widget.plan.plannerVersion,
                syncLabel: widget.plan.syncLabel,
                onVersionTap: _openVersionHistory,
              ),
              const SizedBox(height: 18),
              Text('本周节奏', style: _sectionLabel),
              const SizedBox(height: 8),
              _WeekRhythm(days: overview.weekDays),
              const SizedBox(height: 14),
              _TodayCard(
                overview: overview,
                onStart: overview.today.isRest ? null : widget.onStartToday,
              ),
              const SizedBox(height: 18),
              Text('为什么这样安排', style: _sectionLabel),
              const SizedBox(height: 8),
              _ReasonsCard(reasons: overview.reasons),
              const SizedBox(height: 12),
              _ReviewBanner(
                overview: overview,
                onOpen: () => _openReview(overview),
              ),
              const SizedBox(height: 18),
            ] else ...[
              const SizedBox(height: 8),
              _EmptyPlanCard(onEditPlan: widget.onEditPlan),
              const SizedBox(height: 18),
            ],
            Text('训练日历', style: _sectionLabel),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: AppColors.brandGreen.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.brandGreen,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(
                    fontFamily: AppFonts.inter,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: AppColors.ink,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
                eventLoader: (day) => isRestDay(day) ? const [] : const [1],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedDay.month}月${_selectedDay.day}日 · ${selectedPlan.title}',
                    style: AppTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 12),
                  if (selectedPlan.isRestDay)
                    Text(
                      '这天是休息日',
                      style: TextStyle(fontFamily: AppFonts.inter, color: AppColors.textMuted),
                    )
                  else
                    for (final ex in selectedPlan.exercises)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                ex.name,
                                style: const TextStyle(fontFamily: AppFonts.inter, color: AppColors.ink),
                              ),
                            ),
                            Text('${ex.sets} 组 × ${ex.reps}', style: AppTextStyles.cardMeta),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openReview(PlanOverview overview) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CycleReviewScreen(
          overview: overview,
          plan: widget.plan,
          workoutLog: widget.workoutLog,
        ),
      ),
    );
  }

  Future<void> _openVersionHistory() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: 420,
          child: AnimatedBuilder(
            animation: widget.plan,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 10),
                  child: Text('计划版本', style: AppTextStyles.cardTitle),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final version in widget.plan.versions.reversed)
                        ListTile(
                          title: Text(
                            'v${version.number} · ${version.changeReason}',
                            style: const TextStyle(
                              fontFamily: AppFonts.inter,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '引擎 ${version.plannerVersion} · '
                            '${version.synced ? '云端已同步' : '本地已保存'}',
                          ),
                          trailing: version.number == widget.plan.currentVersion
                              ? const Text('当前')
                              : const Icon(Icons.restore),
                          onTap: version.number == widget.plan.currentVersion
                              ? null
                              : () async {
                                  await widget.plan.restoreVersion(version.number);
                                  if (sheetContext.mounted) {
                                    Navigator.of(sheetContext).pop();
                                  }
                                },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _sectionLabel = TextStyle(
  fontFamily: AppFonts.inter,
  fontWeight: FontWeight.w600,
  fontSize: 10,
  letterSpacing: 1.4,
  color: AppColors.textMuted,
);

class _CycleCard extends StatelessWidget {
  const _CycleCard({
    required this.overview,
    required this.versionLabel,
    required this.plannerVersion,
    required this.syncLabel,
    required this.onVersionTap,
  });

  final PlanOverview overview;
  final String versionLabel;
  final String plannerVersion;
  final String syncLabel;
  final VoidCallback onVersionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.brandGreen.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF4D642B).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.brandGreen,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(overview.mesocycleLabel, style: AppTextStyles.tagLabel),
          ),
          const SizedBox(height: 12),
          Text(
            overview.stageTitle,
            style: const TextStyle(
              fontFamily: AppFonts.inter,
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            overview.stageSummary,
            style: const TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            overview.volumeSummary,
            style: AppTextStyles.cardMeta.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.ink.withValues(alpha: 0.12)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('本周期目标', style: _sectionLabel),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  overview.cycleTargetLabel,
                  style: const TextStyle(
                    fontFamily: AppFonts.inter,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(overview.reviewDateLabel, style: _sectionLabel),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onVersionTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '计划 $versionLabel · 引擎 $plannerVersion · $syncLabel',
                      style: AppTextStyles.socialPill,
                    ),
                  ),
                  const Icon(Icons.history, size: 15, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekRhythm extends StatelessWidget {
  const _WeekRhythm({required this.days});

  final List<WeekDayStatus> days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (final day in days)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: day.isToday ? AppColors.brandGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(
                  children: [
                    Text(
                      day.label,
                      style: TextStyle(
                        fontFamily: AppFonts.jetBrainsMono,
                        fontSize: 10,
                        color: day.isToday ? AppColors.ink : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Icon(
                      day.isRest ? Icons.remove : Icons.add,
                      size: 14,
                      color: day.isToday ? AppColors.ink : const Color(0xFF2F8A5A),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      day.isToday ? '今日' : day.typeLabel,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 9,
                        fontWeight: day.isToday ? FontWeight.w700 : FontWeight.w500,
                        color: day.isToday ? AppColors.ink : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.overview, this.onStart});

  final PlanOverview overview;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final today = overview.today;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('今日训练 · ${today.sessionIndexLabel}', style: _sectionLabel),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(today.title, style: AppTextStyles.cardTitle)),
              if (!today.isRest)
                Text(
                  '${today.durationMin} MIN',
                  style: AppTextStyles.cardMeta.copyWith(color: AppColors.ink),
                ),
            ],
          ),
          if (!today.isRest) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _statChip('目标强度', today.intensityLabel),
                const SizedBox(width: 8),
                _statChip('动作', '${today.exerciseCount} 个'),
                const SizedBox(width: 8),
                _statChip('主项', today.primaryLoadLabel),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: const Key('plan-start-today'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: AppColors.ink,
                disabledBackgroundColor: AppColors.brandGreen.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
              onPressed: today.isRest ? null : onStart,
              child: Text(today.isRest ? '今日休息' : '开始今日训练'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F4),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: _sectionLabel),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontFamily: AppFonts.jetBrainsMono,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonsCard extends StatelessWidget {
  const _ReasonsCard({required this.reasons});

  final List<PlanReason> reasons;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (var i = 0; i < reasons.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    reasons[i].caution ? Icons.info_outline : Icons.check,
                    size: 16,
                    color: reasons[i].caution ? const Color(0xFFC47A12) : const Color(0xFF2F8A5A),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      reasons[i].text,
                      style: const TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
            if (i != reasons.length - 1)
              Divider(height: 1, color: AppColors.ink.withValues(alpha: 0.08)),
          ],
        ],
      ),
    );
  }
}

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner({required this.overview, required this.onOpen});

  final PlanOverview overview;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const Key('plan-cycle-review'),
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  overview.review.reviewDue ? '到检查周了，查看阶段复评' : '查看阶段复评与下一周期变化',
                  style: const TextStyle(
                    fontFamily: AppFonts.inter,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.ink),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPlanCard extends StatelessWidget {
  const _EmptyPlanCard({this.onEditPlan});

  final VoidCallback? onEditPlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('还没有个性化计划', style: AppTextStyles.cardTitle),
          const SizedBox(height: 6),
          Text(
            '填写身体和训练条件后，这里会显示阶段目标、周节奏和复评。',
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: AppColors.textMuted),
          ),
          if (onEditPlan != null) ...[
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: AppColors.ink,
              ),
              onPressed: onEditPlan,
              child: const Text('填写规划数据'),
            ),
          ],
        ],
      ),
    );
  }
}
