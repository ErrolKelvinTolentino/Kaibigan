import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/kaibigan_tokens.dart';
import '../../core/utils/language_helper.dart';
import 'wellness_analytics.dart';

/// Shared, readable statistics for weekly insights and individual activities.
class WellnessInsightsPanel extends StatelessWidget {
  const WellnessInsightsPanel(
      {super.key,
      required this.snapshot,
      required this.language,
      this.feature,
      this.onFeatureTap,
      this.showRules = true});
  final WellnessSnapshot snapshot;
  final String language;
  final String? feature;
  final ValueChanged<String>? onFeatureTap;
  final bool showRules;
  String copy(String en, String fil, [String? mix]) =>
      LanguageHelper.pick(language, english: en, filipino: fil, taglish: mix);

  String _label(String id) => switch (id) {
        'mood' => copy('Check-ins', 'Kumusta ka', 'Check-ins'),
        'sleep' => copy('Sleep', 'Tulog', 'Sleep'),
        'breathing' => copy('Breathing', 'Paghinga', 'Breathing'),
        'grounding' => copy('Grounding', 'Pagtuon sa paligid', 'Grounding'),
        'journal' => copy('Journal', 'Talaarawan', 'Journal'),
        'gratitude' => copy('Gratitude', 'Pasasalamat', 'Gratitude'),
        'routine' => copy('Routines', 'Mga gawain', 'Routines'),
        _ => copy(
            'Small reflections', 'Maiikling pagninilay', 'Small reflections'),
      };
  IconData _icon(String id) => switch (id) {
        'mood' => Icons.sentiment_satisfied_alt_rounded,
        'sleep' => Icons.bedtime_outlined,
        'breathing' => Icons.air_rounded,
        'grounding' => Icons.spa_outlined,
        'journal' => Icons.menu_book_outlined,
        'gratitude' => Icons.local_florist_outlined,
        'routine' => Icons.checklist_rounded,
        _ => Icons.edit_note_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    final ids = feature == null ? snapshot.metrics.keys : [feature!];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (feature == null) ...[
        Container(
          key: const ValueKey('wellness-week-overview'),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: palette.accentSubtle,
              borderRadius: BorderRadius.circular(24)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                copy('Small moments, seen together',
                    'Mga sandali ng pag-aalaga', 'Small moments of care'),
                style: text.titleLarge),
            const SizedBox(height: 8),
            Text(
                copy(
                    '${snapshot.activeDays} of 7 days with a moment of care',
                    '${snapshot.activeDays} sa 7 araw ang may pag-aalaga sa sarili',
                    '${snapshot.activeDays} of 7 days with a moment for yourself'),
                style: text.bodyMedium?.copyWith(color: palette.textSecondary)),
            const SizedBox(height: 16),
            Row(
                children: snapshot.dayCounts.entries
                    .map((day) => Expanded(
                          child: Semantics(
                              label:
                                  '${DateFormat('MMM d').format(day.key)}: ${day.value} ${copy("saved activities", "naitalang gawain")}',
                              child: Column(children: [
                                Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: day.value > 0
                                            ? palette.accent
                                            : palette.surface),
                                    child: Icon(
                                        day.value > 0
                                            ? Icons.check_rounded
                                            : Icons.remove_rounded,
                                        size: 17,
                                        color: day.value > 0
                                            ? palette.onAccent
                                            : palette.textMuted)),
                                const SizedBox(height: 6),
                                Text('${day.key.day}', style: text.labelSmall),
                              ])),
                        ))
                    .toList()),
            const SizedBox(height: 12),
            Text(
                copy(
                    'A record of care, never a score to chase.',
                    'Tala ito ng pag-aalaga, hindi paligsahan.',
                    'A record of care. Walang kailangang habuling score.'),
                style: text.bodySmall),
          ]),
        ),
        const SizedBox(height: 20),
      ],
      LayoutBuilder(builder: (context, constraints) {
        final twoColumns = feature == null &&
            constraints.maxWidth >= 340 &&
            MediaQuery.textScalerOf(context).scale(14) < 20;
        final width =
            twoColumns ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
        return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: ids.map((id) {
              final metric = snapshot.metrics[id]!;
              return SizedBox(
                  width: width,
                  child: Material(
                    key: ValueKey('wellness-metric-$id'),
                    color: palette.surface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: palette.border)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap:
                          onFeatureTap == null ? null : () => onFeatureTap!(id),
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Icon(_icon(id),
                                      size: 21, color: palette.accent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(_label(id),
                                          style: text.titleSmall)),
                                  if (onFeatureTap != null)
                                    Icon(Icons.chevron_right_rounded,
                                        size: 18, color: palette.textMuted),
                                ]),
                                const SizedBox(height: 14),
                                Text(
                                    metric.average != null
                                        ? '${metric.average!.toStringAsFixed(1)} / 5'
                                        : '${metric.count}',
                                    style: text.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(
                                    metric.average != null
                                        ? copy(
                                            'Daily average · ${metric.numericDays} days',
                                            'Karaniwan · ${metric.numericDays} araw',
                                            'Daily average · ${metric.numericDays} days')
                                        : copy(
                                            '${metric.count == 1 ? "Saved entry" : "Saved entries"} · ${metric.days} days',
                                            'Mga tala · ${metric.days} araw',
                                            'Saved entries · ${metric.days} days'),
                                    style: text.bodySmall?.copyWith(
                                        color: palette.textSecondary)),
                                if (metric.average != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                      id == 'sleep'
                                          ? copy('1 restless → 5 energized',
                                              '1 hindi mapakali → 5 masigla')
                                          : copy('1 struggling → 5 great',
                                              '1 nahihirapan → 5 maganda'),
                                      style: text.bodySmall?.copyWith(
                                          color: palette.textSecondary)),
                                ],
                                if (id == 'sleep' &&
                                    snapshot.sleepHours != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                      copy(
                                          '${snapshot.sleepHours!.toStringAsFixed(1)} h average · ${snapshot.sleepDurationDays} nights with duration',
                                          '${snapshot.sleepHours!.toStringAsFixed(1)} oras · ${snapshot.sleepDurationDays} gabi na may tagal'),
                                      style: text.bodySmall),
                                ],
                                if (id == 'breathing' &&
                                    metric.totalMinutes != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                      copy(
                                          '${metric.totalMinutes!.toStringAsFixed(1)} min across ${metric.knownDurationCount} timed sessions',
                                          '${metric.totalMinutes!.toStringAsFixed(1)} minuto sa ${metric.knownDurationCount} pagsasanay'),
                                      style: text.bodySmall),
                                ],
                                const SizedBox(height: 10),
                                Text(
                                    metric.change != null
                                        ? copy(
                                            '${metric.change! >= 0 ? "+" : ""}${metric.change!.toStringAsFixed(1)} points vs previous 7 days',
                                            '${metric.change! >= 0 ? "+" : ""}${metric.change!.toStringAsFixed(1)} puntos kumpara sa nakaraang 7 araw')
                                        : metric.average != null
                                            ? copy(
                                                'More logged days needed to compare',
                                                'Kailangan pa ng mga araw na may tala para maihambing')
                                            : copy(
                                                'Previous 7 days: ${metric.previousCount}',
                                                'Nakaraang 7 araw: ${metric.previousCount}'),
                                    style: text.bodySmall?.copyWith(
                                        color: palette.textSecondary)),
                              ])),
                    ),
                  ));
            }).toList());
      }),
      if (feature == 'mood') ...[
        const SizedBox(height: 12),
        Text(
            copy(
                'Energy: ${snapshot.energy?.toStringAsFixed(1) ?? "—"}/5 · Stress: ${snapshot.stress?.toStringAsFixed(1) ?? "—"}/5. Higher means more energy or stress.',
                'Lakas: ${snapshot.energy?.toStringAsFixed(1) ?? "—"}/5 · Stress: ${snapshot.stress?.toStringAsFixed(1) ?? "—"}/5. Mas mataas ang bilang, mas mataas ang antas.'),
            style: text.bodySmall),
      ],
      if (showRules) ...[
        const SizedBox(height: 24),
        Text(
            copy('What you can take from this', 'Maaaring mapulot dito',
                'What you can take from this'),
            style: text.titleMedium),
        const SizedBox(height: 4),
        Text(
            copy(
                'Based on your logs · no AI needed',
                'Batay sa iyong mga tala · walang AI',
                'Based on your logs · no AI needed'),
            style: text.bodySmall?.copyWith(color: palette.textSecondary)),
        for (final rule in snapshot.observations.where((o) =>
            feature == null ||
            (feature == 'mood' && o.id.startsWith('mood')) ||
            (feature == 'sleep' && o.id.startsWith('sleep')) ||
            (['grounding', 'breathing'].contains(feature) &&
                o.id == 'practice'))) ...[
          const SizedBox(height: 12),
          Text(rule.text(language),
              key: ValueKey('wellness-rule-${rule.id}'),
              style: text.bodyMedium?.copyWith(height: 1.55)),
        ],
      ],
      if (snapshot.feedbackCount > 0 && feature == null) ...[
        const SizedBox(height: 20),
        Text(
            copy(
                'You marked ${snapshot.helpedCount} of ${snapshot.feedbackCount} activity check-backs as helpful. Your experience matters more than a session count.',
                'Nakatulong sa iyo ang ${snapshot.helpedCount} sa ${snapshot.feedbackCount} gawaing binigyan mo ng puna. Mas mahalaga ang karanasan mo kaysa sa dami ng pagsasanay.'),
            style: text.bodyMedium),
      ],
      const SizedBox(height: 20),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
            copy('How these numbers work', 'Paano kinukuha ang mga bilang'),
            style: text.titleSmall),
        children: [
          Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                  copy(
                      'The last 7 calendar days, including today, compared with the 7 before. Each mood day has equal weight; sleep uses the latest log each day. A score comparison needs 3 logged days in each period. Missing values stay blank. Opening a feature does not count as completing it. These observations describe your logs, not your health.',
                      'Huling 7 araw, kasama ang ngayon, kumpara sa 7 araw bago nito. Pantay ang bigat ng bawat araw na may damdamin; pinakahuling tala bawat araw ang gamit sa tulog. Kailangan ng 3 araw na may tala sa bawat panahon para maghambing. Blangko ang walang tala. Hindi katumbas ng pagkumpleto ang pagbukas ng tampok. Mga tala mo ang inilalarawan nito, hindi ang kalusugan mo.'),
                  style: text.bodySmall?.copyWith(height: 1.6)))
        ],
      ),
    ]);
  }
}
