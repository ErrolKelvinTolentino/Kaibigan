import 'package:flutter/material.dart';

import '../../../core/theme/kaibigan_tokens.dart';
import '../../../core/utils/language_helper.dart';
import '../../../core/widgets/kaibigan_surface.dart';
import '../sleep_insights.dart';
import 'sleep_status_card.dart';

/// The written read on a night: how it compared to the target, what the debt
/// looks like, whether the schedule is steady, and one thing to do tonight.
class SleepFeedbackCard extends StatelessWidget {
  const SleepFeedbackCard({
    super.key,
    required this.insights,
    this.language = 'english',
  });

  final SleepInsights insights;
  final String language;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    if (insights.feedback.isEmpty) return const SizedBox.shrink();

    return KaibiganSurface(
      key: const ValueKey('sleep-feedback-card'),
      tone: KaibiganSurfaceTone.elevated,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                size: 18,
                color: palette.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  LanguageHelper.pick(
                    language,
                    english: 'What this night is telling you',
                    filipino: 'Ano ang sinasabi ng gabing ito',
                  ),
                  style: text.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...insights.feedback.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _FeedbackRow(item: item),
            ),
          ),
        ],
      ),
    );
  }
}

/// The three headline numbers, each carrying the sentence that makes it
/// legible: a duration on its own does not say whether it was enough.
class SleepMetricsRow extends StatelessWidget {
  const SleepMetricsRow({
    super.key,
    required this.insights,
    this.language = 'english',
  });

  final SleepInsights insights;
  final String language;

  String _copy(String english, String filipino) =>
      LanguageHelper.pick(language, english: english, filipino: filipino);

  /// How a duration compares with the target, in the fewest words that still
  /// answer "was that enough?".
  String _againstTarget(double? hours) {
    if (hours == null) return _copy('not recorded', 'walang tala');
    final gap = insights.needHours - hours;
    if (gap.abs() < 0.25) return _copy('right on target', 'nasa target');
    if (gap < 0) {
      return _copy(
        '${SleepInsights.formatHours(-gap)} over target',
        'lampas ng ${SleepInsights.formatHours(-gap)}',
      );
    }
    return _copy(
      '${SleepInsights.formatHours(gap)} short',
      'kulang ng ${SleepInsights.formatHours(gap)}',
    );
  }

  String _debtCaption() {
    final status = insights.status;
    return switch (status.level) {
      SleepDebtLevel.none => _copy('nothing to repay', 'walang babawiin'),
      SleepDebtLevel.slight => _copy('one good night clears it', 'isang gabi lang'),
      SleepDebtLevel.moderate => _copy('worth acting on', 'dapat asikasuhin'),
      SleepDebtLevel.high => _copy('sleep deprived', 'kulang sa tulog'),
      SleepDebtLevel.severe => _copy('badly behind', 'malubhang kulang'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final lastNightHours = insights.lastNight?.hours;
    final status = insights.status;

    return KaibiganSurface(
      key: const ValueKey('sleep-metrics-row'),
      tone: KaibiganSurfaceTone.elevated,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Metric(
            label: _copy('LAST NIGHT', 'KAGABI'),
            value: lastNightHours == null
                ? '—'
                : SleepInsights.formatHours(lastNightHours),
            caption: _againstTarget(lastNightHours),
          ),
          Container(width: 1, height: 58, color: palette.border),
          _Metric(
            label: _copy('14-DAY AVG', '14-ARAW'),
            value: insights.debtWindowNights == 0
                ? '—'
                : SleepInsights.formatHours(insights.averageHours),
            caption: insights.debtWindowNights == 0
                ? _copy('no timed nights', 'walang oras na tala')
                : _againstTarget(insights.averageHours),
          ),
          Container(width: 1, height: 58, color: palette.border),
          _Metric(
            key: const ValueKey('sleep-debt-metric'),
            label: _copy('SLEEP DEBT', 'SLEEP DEBT'),
            value: status.hasDebt
                ? SleepInsights.formatHours(status.debtHours)
                : _copy('None', 'Wala'),
            caption: _debtCaption(),
            valueColor: SleepStatusCard.statusColor(status.level, palette),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
    this.valueColor,
  });

  final String label;
  final String value;
  final String caption;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelSmall?.copyWith(
              color: palette.textMuted,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleSmall?.copyWith(
              color: valueColor ?? palette.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(
              color: palette.textMuted,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackRow extends StatelessWidget {
  const _FeedbackRow({required this.item});

  final SleepFeedbackItem item;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    final (colour, icon) = switch (item.tone) {
      SleepFeedbackTone.good => (palette.botanical, Icons.check_circle_rounded),
      SleepFeedbackTone.watch => (palette.warning, Icons.info_rounded),
      SleepFeedbackTone.concern => (palette.danger, Icons.priority_high_rounded),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: colour.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: colour),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: text.labelLarge?.copyWith(color: palette.textPrimary),
              ),
              const SizedBox(height: 3),
              Text(
                item.detail,
                style: text.bodySmall?.copyWith(
                  color: palette.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
