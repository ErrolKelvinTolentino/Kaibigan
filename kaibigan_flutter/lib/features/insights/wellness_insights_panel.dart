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

  String _verbalSummary() {
    if (!snapshot.hasData) {
      return copy(
        'There is not enough saved activity yet to describe a pattern. That is okay—missing days are left unknown, not treated as bad days.',
        'Wala pang sapat na naitalang gawain para makakita ng pattern. Ayos lang iyon—hindi itinuturing na masamang araw ang mga araw na walang tala.',
        'Wala pang enough saved activity para makakita ng pattern. Okay lang—unknown ang missing days, hindi bad days.',
      );
    }

    if (feature == 'mood') {
      final mood = snapshot.metrics['mood']!;
      if (mood.numericDays < 3) {
        return copy(
          'You have started checking in with yourself. A few more logged days will make it easier to tell whether this week felt steady or changeable.',
          'Nagsimula ka nang kumustahin ang sarili mo. Makakatulong ang ilan pang araw na may tala para makita kung naging matatag o pabago-bago ang linggo.',
          'You have started checking in. A few more logged days will make the pattern easier to understand.',
        );
      }
      if (mood.change != null) {
        final direction = mood.change! > 0
            ? copy('lighter', 'mas magaan')
            : copy('more difficult', 'mas mabigat');
        return copy(
          'The days you logged felt $direction than the previous week. This is a pattern in your check-ins, not a judgment about the whole week.',
          'Ang mga araw na naitala mo ay $direction kaysa nakaraang linggo. Pattern lamang ito sa iyong mga check-in, hindi paghatol sa buong linggo.',
          'Your logged days felt $direction than last week. Pattern ito sa check-ins mo, not a judgment on your whole week.',
        );
      }
      final tone = mood.average! >= 3.5
          ? copy('generally on the lighter side', 'karaniwang mas magaan')
          : mood.average! <= 2.5
              ? copy('more difficult overall', 'mas mabigat sa kabuuan')
              : copy('mixed or near the middle', 'halo-halo o nasa gitna');
      return copy(
        'Your logged days were $tone. The average cannot explain why, so your notes and the situations around each check-in matter most.',
        'Ang mga araw na naitala mo ay $tone. Hindi maipapaliwanag ng average kung bakit, kaya pinakamahalaga ang iyong mga tala at sitwasyon sa bawat check-in.',
        'Your logged days were $tone. The average cannot explain why, so context from your notes matters most.',
      );
    }

    if (feature == 'sleep') {
      final sleep = snapshot.metrics['sleep']!;
      if (sleep.days == 0) {
        return copy(
          'No recent sleep logs are available yet, so there is no sleep pattern to interpret.',
          'Wala pang kamakailang tala ng tulog, kaya wala pang pattern na maaaring unawain.',
          'Wala pang recent sleep logs, so wala pang pattern to interpret.',
        );
      }
      if (snapshot.sleepHours != null && sleep.average != null) {
        return copy(
          'Your logs include both sleep length and how rested you felt. Those two measures may tell different stories, so neither should be read on its own.',
          'Kasama sa iyong mga tala ang haba ng tulog at pakiramdam pagkagising. Maaaring magkaiba ang kuwento ng dalawang ito, kaya hindi sapat ang isa lamang.',
          'Your logs include sleep length and how rested you felt. They can tell different stories, so look at both together.',
        );
      }
      return copy(
        'You recorded how sleep felt, but some nights do not have an exact duration. The quality pattern is useful; the missing hours should stay unknown.',
        'Naitala mo ang pakiramdam ng tulog, ngunit walang eksaktong tagal ang ilang gabi. Kapaki-pakinabang ang quality pattern; mananatiling hindi alam ang kulang na oras.',
        'You recorded how sleep felt, but some nights have no exact duration. Useful pa rin ang quality pattern; unknown ang missing hours.',
      );
    }

    if (feature == 'breathing' || feature == 'grounding') {
      final count = snapshot.metrics[feature]!.count;
      return count == 0
          ? copy(
              'There are no completed ${_label(feature!)} sessions in this seven-day window yet.',
              'Wala pang natapos na ${_label(feature!)} session sa nakaraang pitong araw.',
            )
          : copy(
              'You returned to ${_label(feature!).toLowerCase()} this week. A session count shows that you practiced; your own check-back tells whether it helped.',
              'Bumalik ka sa ${_label(feature!).toLowerCase()} ngayong linggo. Ipinapakita ng bilang na nagsanay ka; ikaw ang makapagsasabi kung nakatulong ito.',
            );
    }

    final activeMetrics = snapshot.metrics.entries
        .where((entry) => entry.value.days > 0)
        .toList()
      ..sort((left, right) => right.value.days.compareTo(left.value.days));
    final strongest = activeMetrics.isEmpty ? null : activeMetrics.first;
    if (strongest == null) {
      return copy(
        'You saved a few moments of care this week. There is not yet one activity that stands out as a repeated pattern.',
        'May ilang sandali ng pag-aalaga kang naitala ngayong linggo. Wala pang isang gawaing malinaw na paulit-ulit.',
      );
    }
    return copy(
      'You made space for yourself on ${snapshot.activeDays} days. ${_label(strongest.key)} was the most repeated part of your week, which may make it a useful place to look for context—not proof of what caused you to feel better or worse.',
      'Naglaan ka ng oras para sa sarili sa ${snapshot.activeDays} araw. Ang ${_label(strongest.key)} ang pinakamadalas na bahagi ng linggo, kaya maaari itong pagkunan ng konteksto—hindi patunay ng sanhi ng iyong naramdaman.',
      'You made space for yourself on ${snapshot.activeDays} days. ${_label(strongest.key)} appeared most often, so it may be a useful place to look for context.',
    );
  }

  String _helpfulNextStep() {
    if (!snapshot.hasData) {
      return copy(
        'Start with one short mood check-in today. A sentence about what was happening will be more useful than a score alone.',
        'Magsimula sa isang maikling mood check-in ngayon. Mas makatutulong ang isang pangungusap tungkol sa nangyayari kaysa numero lamang.',
        'Start with one short mood check-in today. Add one sentence of context, not just a score.',
      );
    }
    if (feature == 'mood') {
      final mood = snapshot.metrics['mood']!;
      return mood.numericDays < 3
          ? copy(
              'Try two more quick check-ins on different days, adding one note about what made the moment easier or harder.',
              'Subukan ang dalawa pang mabilis na check-in sa magkaibang araw at magdagdag ng maikling tala tungkol sa nagpagaan o nagpabigat ng sandali.',
            )
          : copy(
              'Compare one easier logged day with one harder day. Look for a difference in rest, demands, people, or routines that you may want to remember.',
              'Ihambing ang isang magaan na araw at isang mabigat na araw. Tingnan kung may pagkakaiba sa pahinga, gawain, kasama, o routine na nais mong tandaan.',
            );
    }
    if (feature == 'sleep') {
      return snapshot.sleepDurationDays < 3
          ? copy(
              'For the next few nights, record both the duration and how rested you feel. That pairing will make the insight more useful.',
              'Sa susunod na ilang gabi, itala ang tagal at pakiramdam pagkagising. Mas magiging kapaki-pakinabang ang insight kapag magkasama ang dalawa.',
            )
          : copy(
              'Compare your most-rested night with a less-rested one and note one difference you could gently test again.',
              'Ihambing ang gabing pinakanakapagpahinga ka sa isang hindi gaanong nakapagpahinga, at pumili ng isang pagkakaibang maaari mong subukan muli.',
            );
    }
    if (feature == 'breathing' || feature == 'grounding') {
      return copy(
        'After your next session, pause for a moment and mark whether it helped. That check-back is more informative than adding another count.',
        'Pagkatapos ng susunod na session, huminto sandali at itala kung nakatulong ito. Mas makabuluhan iyon kaysa dagdag na bilang lamang.',
      );
    }
    if (snapshot.metrics['mood']!.numericDays < 3) {
      return copy(
        'Add a few short mood check-ins on different days. Include what was happening so future patterns have real context.',
        'Magdagdag ng ilang maikling mood check-in sa magkaibang araw. Isama ang nangyayari para may tunay na konteksto ang susunod na pattern.',
      );
    }
    if (snapshot.metrics['sleep']!.days > snapshot.sleepDurationDays) {
      return copy(
        'When you next log sleep, include both duration and how rested you feel. This fills the most important gap in the current picture.',
        'Sa susunod na tala ng tulog, isama ang tagal at pakiramdam pagkagising. Ito ang pinakamahalagang kulang sa kasalukuyang larawan.',
      );
    }
    return copy(
      'Choose one easier day and one harder day from this week. Add a brief note about what was different before deciding what to repeat or adjust.',
      'Pumili ng isang magaan at isang mabigat na araw ngayong linggo. Magdagdag ng maikling tala tungkol sa pagkakaiba bago pumili ng uulitin o babaguhin.',
      'Choose one easier day and one harder day. Note what was different before deciding what to repeat or adjust.',
    );
  }

  Widget _buildVerbalInsight(BuildContext context) {
    final palette = context.kaibigan;
    final text = Theme.of(context).textTheme;
    return Container(
      key: const ValueKey('wellness-verbal-insight'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: palette.botanicalSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.chat_bubble_outline_rounded,
                    size: 20, color: palette.accentStrong),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  copy('What your logs are saying',
                      'Ano ang sinasabi ng iyong mga tala'),
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_verbalSummary(),
              style: text.bodyMedium?.copyWith(height: 1.55)),
          const SizedBox(height: 16),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.arrow_forward_rounded,
                  size: 19, color: palette.accentStrong),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copy('A helpful next step',
                          'Isang makatutulong na susunod na hakbang'),
                      style: text.labelLarge?.copyWith(
                        color: palette.accentStrong,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _helpfulNextStep(),
                      key: const ValueKey('wellness-next-step'),
                      style: text.bodyMedium?.copyWith(height: 1.5),
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
      _buildVerbalInsight(context),
      const SizedBox(height: 20),
      Text(
        copy('The numbers behind it', 'Mga bilang na pinagbabatayan'),
        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
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
