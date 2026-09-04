import 'package:flutter/material.dart';

import '../planner/plan_overview.dart';
import '../state/plan_controller.dart';
import '../state/workout_log_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Engine-backed stage review. Opening the page evaluates the current local
/// evidence; adopting appends a new immutable plan version.
class CycleReviewScreen extends StatefulWidget {
  const CycleReviewScreen({
    super.key,
    required this.overview,
    required this.plan,
    required this.workoutLog,
  });

  final PlanOverview overview;
  final PlanController plan;
  final WorkoutLogController workoutLog;

  @override
  State<CycleReviewScreen> createState() => _CycleReviewScreenState();
}

class _CycleReviewScreenState extends State<CycleReviewScreen> {
  late final Future<PlanReviewResult> _reviewFuture;
  bool _adopting = false;

  @override
  void initState() {
    super.initState();
    _reviewFuture = widget.plan.reviewCurrentCycle(widget.workoutLog.entries);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlanReviewResult>(
      future: _reviewFuture,
      builder: (context, snapshot) {
        final result = snapshot.data;
        final review = result == null
            ? widget.overview.review
            : _engineReview(widget.overview.review, result.review);
        return _page(context, review, result, snapshot.error);
      },
    );
  }

  Widget _page(
    BuildContext context,
    CycleReviewSnapshot review,
    PlanReviewResult? result,
    Object? error,
  ) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.ink, size: 18),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('阶段复评', style: AppTextStyles.screenTitle),
                          Text(
                            review.weekLabel,
                            style: AppTextStyles.socialPill,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${widget.overview.currentWeek} / ${widget.overview.cycleWeeks} 周',
                      style: AppTextStyles.cardMeta.copyWith(color: AppColors.ink),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    if (error != null)
                      _LoadErrorCard(message: '$error')
                    else
                      _EvidenceCard(review: review),
                    const SizedBox(height: 14),
                    _ConclusionCard(review: review),
                    const SizedBox(height: 18),
                    Text('下一周期变化', style: _sectionLabel),
                    const SizedBox(height: 8),
                    _ChangesCard(changes: review.changes),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandGreen,
                          foregroundColor: AppColors.ink,
                          disabledBackgroundColor: AppColors.brandGreen.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                        ),
                        onPressed: result?.canAdopt == true && !_adopting
                            ? () => _adopt(result!)
                            : null,
                        child: Text(
                          _adopting
                              ? '正在保存新版本…'
                              : '采用新计划 · v${widget.plan.currentVersion + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        side: BorderSide(color: AppColors.ink.withValues(alpha: 0.12)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        minimumSize: const Size.fromHeight(46),
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('保留当前计划'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '计划采用后仍可在历史版本中恢复',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.socialPill,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _adopt(PlanReviewResult result) async {
    setState(() => _adopting = true);
    try {
      await widget.plan.adoptReview(result);
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _adopting = false);
    }
  }
}

CycleReviewSnapshot _engineReview(
  CycleReviewSnapshot base,
  Map<String, dynamic> review,
) {
  final verdict = review['verdict'] as String? ?? 'extend';
  final assessment = Map<String, dynamic>.from(
    review['assessment'] as Map? ?? const {},
  );
  final safetyMet = assessment['safety_met'] as bool? ?? true;
  final dataQualityMet = assessment['data_quality_met'] as bool? ?? false;
  final loadChanges = (review['load_changes'] as List? ?? const [])
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList();
  final loadValue = loadChanges.isEmpty
      ? '保持'
      : loadChanges
          .map((item) {
            final from = (item['from_kg'] as num).toDouble();
            final to = (item['to_kg'] as num).toDouble();
            final delta = to - from;
            return '${delta >= 0 ? '+' : ''}${_compactNumber(delta)} kg';
          })
          .toSet()
          .join(' / ');
  final volume = switch (review['volume_change']) {
    'up_one_step' => '+1 档',
    'down_10pct' => '-10%',
    _ => '保持',
  };
  final kcal = (review['kcal_change'] as num?)?.toInt() ?? 0;
  final title = switch (verdict) {
    'advance' => '阶段达成',
    'deload_then_retry' => '先减载再继续',
    'address_safety' => '先处理安全问题',
    _ => '延长当前阶段',
  };
  return CycleReviewSnapshot(
    weekLabel: base.weekLabel,
    completionPct: base.completionPct,
    completionKnown: base.completionKnown,
    intensityLabel: dataQualityMet ? '证据已达标' : '继续观察',
    recoveryLabel: '未记录',
    painLabel: safetyMet ? '未报告' : '需要处理',
    painCaution: !safetyMet,
    weightTrendLabel: base.weightTrendLabel,
    weightTrendKnown: base.weightTrendKnown,
    conclusionTitle: title,
    conclusionBody: review['summary'] as String? ?? base.conclusionBody,
    cautionBody: !safetyMet ? '安全问题解决前不会生成新计划。' : null,
    changes: [
      NextStageChange(label: '训练容量', value: volume),
      NextStageChange(label: '主项负荷', value: loadValue),
      NextStageChange(
        label: '每日能量建议',
        value: kcal == 0 ? '维持' : '${kcal > 0 ? '+' : ''}$kcal kcal',
      ),
    ],
    reviewDue: base.reviewDue,
    adoptEnabled: verdict != 'address_safety',
  );
}

String _compactNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);

const _sectionLabel = TextStyle(
  fontFamily: AppFonts.inter,
  fontWeight: FontWeight.w600,
  fontSize: 10,
  letterSpacing: 1.4,
  color: AppColors.textMuted,
);

class _LoadErrorCard extends StatelessWidget {
  const _LoadErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          '复评计算失败：$message',
          style: const TextStyle(
            fontFamily: AppFonts.inter,
            color: Color(0xFFC47A12),
          ),
        ),
      );
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({required this.review});

  final CycleReviewSnapshot review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('本周期证据', style: _sectionLabel),
          const SizedBox(height: 12),
          Row(
            children: [
              _CompletionRing(
                pct: review.completionPct,
                known: review.completionKnown,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _metricRow('可比表现', review.intensityLabel),
                    _metricRow('恢复状态', review.recoveryLabel),
                    _metricRow(
                      '疼痛反馈',
                      review.painLabel,
                      caution: review.painCaution,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value, {bool caution = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: _sectionLabel)),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: caution ? const Color(0xFFC47A12) : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionRing extends StatelessWidget {
  const _CompletionRing({required this.pct, required this.known});

  final int pct;
  final bool known;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      height: 86,
      child: CustomPaint(
        painter: _RingPainter(progress: known ? pct / 100 : 0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                known ? '$pct%' : '—',
                style: const TextStyle(
                  fontFamily: AppFonts.jetBrainsMono,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: AppColors.ink,
                ),
              ),
              const Text('完成率', style: _sectionLabel),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 5;
    final track = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    final fill = Paint()
      ..color = AppColors.brandGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      progress.clamp(0.0, 1.0) * 6.2832,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ConclusionCard extends StatelessWidget {
  const _ConclusionCard({required this.review});

  final CycleReviewSnapshot review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.brandGreen.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF4D642B).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('引擎结论', style: AppTextStyles.tagLabel),
          ),
          const SizedBox(height: 12),
          Text(
            review.conclusionTitle,
            style: const TextStyle(
              fontFamily: AppFonts.inter,
              fontWeight: FontWeight.w700,
              fontSize: 28,
              letterSpacing: -1,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            review.conclusionBody,
            style: const TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: AppColors.ink),
          ),
          if (review.cautionBody != null) ...[
            const SizedBox(height: 8),
            Text(
              review.cautionBody!,
              style: const TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 13,
                color: Color(0xFFC47A12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChangesCard extends StatelessWidget {
  const _ChangesCard({required this.changes});

  final List<NextStageChange> changes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          for (var i = 0; i < changes.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      changes[i].label,
                      style: const TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: AppColors.ink),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: changes[i].caution
                          ? const Color(0x1EF2A63C)
                          : const Color(0x1A55C98A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      changes[i].value,
                      style: TextStyle(
                        fontFamily: AppFonts.jetBrainsMono,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: changes[i].caution ? const Color(0xFFC47A12) : const Color(0xFF2F8A5A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i != changes.length - 1)
              Divider(height: 1, color: AppColors.ink.withValues(alpha: 0.08)),
          ],
        ],
      ),
    );
  }
}
