import 'package:flutter/material.dart';

import '../../../core/theme/kaibigan_tokens.dart';
import '../../../core/utils/language_helper.dart';
import '../../../core/widgets/kaibigan_surface.dart';
import '../sleep_insights.dart';

/// The answer to "am I sleep deprived?" before any number has to be read.
///
/// Sleep debt was previously one figure in a row of three, which made a
/// serious shortfall look like a statistic. This card names the level, says
/// what the hours amount to in nights, and gives the repayment that clears
/// it — so the number arrives already interpreted.
class SleepStatusCard extends StatelessWidget {
  const SleepStatusCard({
    super.key,
    required this.insights,
    this.language = 'english',
  });

  final SleepInsights insights;
  final String language;

  String _copy(String english, String filipino) =>
      LanguageHelper.pick(language, english: english, filipino: filipino);

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    final status = insights.status;
    final accent = statusColor(status.level, palette);
    final recovery = status.recovery;

    return KaibiganSurface(
      key: const ValueKey('sleep-status-card'),
      tone: KaibiganSurfaceTone.elevated,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(_statusIcon(status.level), size: 20, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _copy('SLEEP DEBT', 'SLEEP DEBT'),
                      style: text.labelSmall?.copyWith(
                        color: palette.textMuted,
                        letterSpacing: 0.9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status.title,
                      key: const ValueKey('sleep-status-title'),
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (status.hasDebt)
                Flexible(
                  child: Text(
                    SleepInsights.formatHours(status.debtHours),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleLarge?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          if (status.hasDebt) ...[
            const SizedBox(height: 14),
            _DebtMeter(
              nightsBehind: status.nightsBehind,
              colour: accent,
              language: language,
            ),
          ],
          const SizedBox(height: 12),
          Text(
            status.meaning,
            key: const ValueKey('sleep-status-meaning'),
            style: text.bodyMedium?.copyWith(
              color: palette.textSecondary,
              height: 1.5,
            ),
          ),
          if (status.symptomNote != null) ...[
            const SizedBox(height: 12),
            Container(
              key: const ValueKey('sleep-status-symptoms'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.psychology_alt_outlined, size: 17, color: accent),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      status.symptomNote!,
                      style: text.bodySmall?.copyWith(
                        color: palette.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            key: const ValueKey('sleep-status-plan'),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: palette.surfaceSubtle,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  recovery == null
                      ? Icons.verified_outlined
                      : Icons.event_repeat_rounded,
                  size: 18,
                  color: palette.accentStrong,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recovery == null
                            ? _copy('Keep it here', 'Panatilihin ito')
                            : _copy(
                                'Your way back to even',
                                'Paraan para makabawi',
                              ),
                        style: text.labelLarge?.copyWith(
                          color: palette.accentStrong,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        status.action,
                        style: text.bodySmall?.copyWith(
                          color: palette.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      if (recovery != null) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _PlanChip(
                              value: '+${recovery.extraMinutesPerNight}m',
                              label: _copy('per night', 'bawat gabi'),
                            ),
                            _PlanChip(
                              value: '×${recovery.nights}',
                              label: recovery.nights == 1
                                  ? _copy('night', 'gabi')
                                  : _copy('nights', 'gabi'),
                            ),
                            _PlanChip(
                              value: SleepInsights.formatHours(
                                recovery.repaidHours,
                              ),
                              label: recovery.clearsDebt
                                  ? _copy('cleared', 'nabawi')
                                  : _copy('this week', 'ngayong linggo'),
                            ),
                          ],
                        ),
                      ],
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

  static IconData _statusIcon(SleepDebtLevel level) => switch (level) {
        SleepDebtLevel.none => Icons.check_circle_rounded,
        SleepDebtLevel.slight => Icons.trending_flat_rounded,
        SleepDebtLevel.moderate => Icons.info_rounded,
        SleepDebtLevel.high => Icons.warning_amber_rounded,
        SleepDebtLevel.severe => Icons.priority_high_rounded,
      };

  /// Shared with the metrics row so the same debt is the same colour
  /// wherever it appears.
  static Color statusColor(SleepDebtLevel level, KaibiganPalette palette) =>
      switch (level) {
        SleepDebtLevel.none => palette.botanical,
        SleepDebtLevel.slight => palette.accentStrong,
        SleepDebtLevel.moderate => palette.warning,
        SleepDebtLevel.high || SleepDebtLevel.severe => palette.danger,
      };
}

/// The debt drawn against one night, because "half a night gone" is a size
/// people can feel and "4h 30m" is not.
class _DebtMeter extends StatelessWidget {
  const _DebtMeter({
    required this.nightsBehind,
    required this.colour,
    required this.language,
  });

  final double nightsBehind;
  final Color colour;
  final String language;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    String copy(String english, String filipino) =>
        LanguageHelper.pick(language, english: english, filipino: filipino);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Stack(
            children: [
              Container(height: 9, color: palette.surfaceSubtle),
              FractionallySizedBox(
                widthFactor: (nightsBehind / 2).clamp(0.04, 1.0),
                child: Container(height: 9, color: colour),
              ),
              // The midpoint marks one whole night, which is where a
              // shortfall stops being something a single good night absorbs.
              Positioned(
                left: 0,
                right: 0,
                child: Row(
                  children: [
                    const Spacer(),
                    Container(
                      width: 2,
                      height: 9,
                      color: palette.background.withValues(alpha: 0.9),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          copy(
            'Midpoint is one full night behind.',
            'Ang gitna ay isang buong gabing kulang.',
          ),
          style: text.labelSmall?.copyWith(color: palette.textMuted),
        ),
      ],
    );
  }
}

class _PlanChip extends StatelessWidget {
  const _PlanChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: palette.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: palette.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// The changes worth making, chosen from what the logged nights show rather
/// than a fixed sleep-hygiene list.
class SleepTipsCard extends StatelessWidget {
  const SleepTipsCard({
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
    if (insights.tips.isEmpty) return const SizedBox.shrink();
    String copy(String english, String filipino) =>
        LanguageHelper.pick(language, english: english, filipino: filipino);

    return KaibiganSurface(
      key: const ValueKey('sleep-tips-card'),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates_rounded,
                  size: 18, color: palette.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  copy('What would actually help', 'Ano ang tunay na makakatulong'),
                  style: text.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            copy(
              'Chosen from your logged nights, not a general checklist.',
              'Batay sa mga gabing naitala mo, hindi sa pangkalahatang listahan.',
            ),
            style: text.bodySmall?.copyWith(color: palette.textMuted),
          ),
          const SizedBox(height: 14),
          ...insights.tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _categoryColor(tip.category, palette)
                          .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _categoryIcon(tip.category),
                      size: 16,
                      color: _categoryColor(tip.category, palette),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip.title,
                          style: text.labelLarge
                              ?.copyWith(color: palette.textPrimary),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tip.detail,
                          style: text.bodySmall?.copyWith(
                            color: palette.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
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

  static IconData _categoryIcon(SleepTipCategory category) => switch (category) {
        SleepTipCategory.tonight => Icons.nightlight_round,
        SleepTipCategory.schedule => Icons.schedule_rounded,
        SleepTipCategory.daytime => Icons.wb_sunny_outlined,
        SleepTipCategory.environment => Icons.bed_outlined,
        SleepTipCategory.support => Icons.health_and_safety_outlined,
      };

  static Color _categoryColor(
    SleepTipCategory category,
    KaibiganPalette palette,
  ) =>
      switch (category) {
        SleepTipCategory.tonight => palette.accentStrong,
        SleepTipCategory.schedule => palette.accent,
        SleepTipCategory.daytime => palette.warning,
        SleepTipCategory.environment => palette.botanical,
        SleepTipCategory.support => palette.danger,
      };
}
