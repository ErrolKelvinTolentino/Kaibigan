import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/language_helper.dart';
import '../../mood_tracking/mood_model.dart';
import '../adaptive_support_recommendation.dart';

class AdaptiveSupportCard extends StatelessWidget {
  final AdaptiveSupportRecommendation recommendation;
  final String language;
  final bool isDark;
  final VoidCallback onTap;

  const AdaptiveSupportCard({
    super.key,
    required this.recommendation,
    required this.language,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final copy = _AdaptiveSupportCopy.forRecommendation(
      recommendation,
      language,
    );
    const accent = AppColors.honeyAmber;
    final highlight = switch (recommendation.kind) {
      AdaptiveSupportKind.checkIn => AppColors.honeyGold,
      AdaptiveSupportKind.grounding => AppColors.softOlive,
      AdaptiveSupportKind.breathing => AppColors.skyBlue,
      AdaptiveSupportKind.reflection => AppColors.lavenderMist,
      AdaptiveSupportKind.gratitude => AppColors.warmPeach,
      AdaptiveSupportKind.focus => AppColors.softYellow,
    };
    final foreground =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final compact = MediaQuery.sizeOf(context).width <= 360;

    return Semantics(
      button: true,
      label: '${copy.heading}. ${copy.title}. ${copy.description}',
      child: InkWell(
        key: const ValueKey('adaptive-support-card'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          key: const ValueKey('adaptive-support-surface'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Color.alphaBlend(
                        highlight.withValues(alpha: 0.16),
                        AppColors.darkCard,
                      ),
                      AppColors.darkCard,
                    ]
                  : [
                      Color.alphaBlend(
                        highlight.withValues(alpha: 0.20),
                        Colors.white,
                      ),
                      Color.alphaBlend(
                        AppColors.pollenGlow.withValues(alpha: 0.12),
                        Colors.white,
                      ),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: highlight.withValues(alpha: isDark ? 0.42 : 0.36),
            ),
            boxShadow: [
              BoxShadow(
                color: highlight.withValues(alpha: isDark ? 0.08 : 0.12),
                blurRadius: 22,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: compact ? 72 : 86,
                  height: compact ? 88 : 96,
                  foregroundDecoration: BoxDecoration(
                    border: Border.all(
                      color: highlight.withValues(alpha: 0.40),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _assetFor(recommendation.kind) != null
                      ? Image.asset(
                          _assetFor(recommendation.kind)!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                          isAntiAlias: true,
                          errorBuilder: (_, __, ___) => ColoredBox(
                            color: highlight.withValues(alpha: 0.16),
                            child: Icon(
                              _iconFor(recommendation.kind),
                              color: highlight,
                              size: 46,
                            ),
                          ),
                        )
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                highlight.withValues(alpha: 0.25),
                                accent.withValues(alpha: 0.13),
                              ],
                            ),
                          ),
                          child: Icon(
                            _iconFor(recommendation.kind),
                            color: highlight,
                            size: 43,
                          ),
                        ),
                ),
              ),
              SizedBox(width: compact ? 10 : 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            highlight.withValues(alpha: isDark ? 0.15 : 0.18),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        copy.heading,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? AppColors.textPrimaryDark : accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.55,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      copy.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      copy.description,
                      maxLines: compact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondary,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        if (_signalLabel(recommendation) case final signal?)
                          Expanded(
                            child: Text(
                              signal,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: secondary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: copy.action,
                          child: FilledButton(
                            key: const ValueKey('adaptive-support-action'),
                            onPressed: onTap,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              padding: EdgeInsets.zero,
                              backgroundColor: accent,
                              foregroundColor: AppColors.onHoney,
                              shape: const CircleBorder(),
                            ),
                            child: Icon(
                              _usesWritingAction(recommendation.kind)
                                  ? Icons.edit_rounded
                                  : Icons.play_arrow_rounded,
                              size: 21,
                            ),
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
      ),
    );
  }

  static bool _usesWritingAction(AdaptiveSupportKind kind) => switch (kind) {
        AdaptiveSupportKind.reflection ||
        AdaptiveSupportKind.gratitude ||
        AdaptiveSupportKind.focus =>
          true,
        _ => false,
      };

  static String? _assetFor(AdaptiveSupportKind kind) => switch (kind) {
        AdaptiveSupportKind.checkIn => FeatureIconHelper.moodTracker,
        AdaptiveSupportKind.reflection => FeatureIconHelper.dailyReflection,
        AdaptiveSupportKind.gratitude => FeatureIconHelper.gratitudeGarden,
        AdaptiveSupportKind.focus => FeatureIconHelper.todaysFocus,
        _ => null,
      };

  static String? _signalLabel(AdaptiveSupportRecommendation recommendation) {
    final source = recommendation.source;
    if (source == null) return null;
    return 'Latest check-in  •  Mood ${source.moodScore}/5  •  Stress ${source.stressLevel}/5  •  Energy ${source.energyLevel}/5';
  }

  static IconData _iconFor(AdaptiveSupportKind kind) => switch (kind) {
        AdaptiveSupportKind.checkIn => Icons.wb_sunny_outlined,
        AdaptiveSupportKind.grounding => Icons.spa_outlined,
        AdaptiveSupportKind.breathing => Icons.air_rounded,
        AdaptiveSupportKind.reflection => Icons.edit_note_rounded,
        AdaptiveSupportKind.gratitude => Icons.local_florist_outlined,
        AdaptiveSupportKind.focus => Icons.center_focus_strong_rounded,
      };
}

class _AdaptiveSupportCopy {
  final String eyebrow;
  final String heading;
  final String title;
  final String description;
  final String action;
  final String privacy;

  const _AdaptiveSupportCopy({
    required this.eyebrow,
    required this.heading,
    required this.title,
    required this.description,
    required this.action,
    required this.privacy,
  });

  static _AdaptiveSupportCopy forRecommendation(
    AdaptiveSupportRecommendation recommendation,
    String language,
  ) {
    String pick(String english, String filipino, String taglish) =>
        LanguageHelper.pick(
          language,
          english: english,
          filipino: filipino,
          taglish: taglish,
        );

    final usesCheckIn = recommendation.usesRecentCheckIn;
    final common = (
      eyebrow: usesCheckIn
          ? pick(
              'BASED ON YOUR CHECK-IN',
              'MULA SA IYONG CHECK-IN',
              'BASED SA CHECK-IN MO',
            )
          : pick('A GENTLE SUGGESTION', 'BANAYAD NA MUNGKAHI',
              'A GENTLE SUGGESTION'),
      heading: pick(
        'What might help?',
        'Ano ang maaaring makatulong?',
        'Ano kaya ang makakatulong?',
      ),
      privacy: usesCheckIn
          ? pick(
              'Uses only your latest check-in—not journal text or AI.',
              'Pinakabagong check-in lamang—hindi journal o AI.',
              'Latest check-in lang—hindi journal text o AI.',
            )
          : pick(
              'Your suggestion updates after a mood check-in.',
              'Magbabago ang mungkahi pagkatapos ng mood check-in.',
              'Mag-a-update ito after ng mood check-in.',
            ),
    );

    final content = switch (recommendation.kind) {
      AdaptiveSupportKind.checkIn => (
          title: pick(
            'Check in with yourself',
            'Kumustahin ang sarili',
            'Mag-check in muna',
          ),
          description: pick(
            'Share how today feels so Kaibigan can suggest one activity that fits the moment.',
            'Ibahagi ang nararamdaman ngayon upang makapagmungkahi ang Kaibigan ng angkop na gawain.',
            'Share how today feels para makapagmungkahi ang Kaibigan ng activity na bagay ngayon.',
          ),
          action: pick('Check in now', 'Mag-check in ngayon', 'Check in now'),
        ),
      AdaptiveSupportKind.grounding => (
          title: pick(
            'Come back to the present',
            'Bumalik sa kasalukuyan',
            'Balik muna sa present',
          ),
          description: _groundingDescription(recommendation.reason, pick),
          action: pick(
            'Start 5–4–3–2–1 grounding',
            'Simulan ang 5–4–3–2–1',
            'Start 5–4–3–2–1 grounding',
          ),
        ),
      AdaptiveSupportKind.breathing => (
          title: pick(
            'Take a one-minute pause',
            'Huminto nang isang minuto',
            'One-minute pause muna',
          ),
          description: _breathingDescription(recommendation.reason, pick),
          action: pick('Breathe with a guide', 'Huminga nang may gabay',
              'Breathe with a guide'),
        ),
      AdaptiveSupportKind.reflection => (
          title: pick(
            'Make room for what you feel',
            'Bigyan ng puwang ang nararamdaman',
            'Bigyan ng space ang nararamdaman',
          ),
          description: pick(
            'Your latest mood felt lower. An open reflection can give it space without asking you to fix it.',
            'Mas mababa ang mood sa huling check-in. Maaaring bigyan ito ng puwang sa isang bukas na pagninilay.',
            'Mas mababa ang latest mood mo. An open reflection can give it space—no need to fix it agad.',
          ),
          action: pick('Open a reflection', 'Buksan ang pagninilay',
              'Open a reflection'),
        ),
      AdaptiveSupportKind.gratitude => (
          title: pick(
            'Keep one good detail',
            'Itabi ang isang magandang detalye',
            'Keep one good detail',
          ),
          description: pick(
            'Your latest check-in held a brighter mood. You might save one detail you want to remember.',
            'Mas magaan ang mood sa huling check-in. Maaaring itala ang isang detalyeng nais mong tandaan.',
            'Mas bright ang latest mood mo. Baka may isang detail kang gustong tandaan.',
          ),
          action: pick('Plant a gratitude', 'Magtanim ng pasasalamat',
              'Plant a gratitude'),
        ),
      AdaptiveSupportKind.focus => (
          title: pick(
            'Choose one kind priority',
            'Pumili ng isang banayad na prayoridad',
            'Choose one gentle priority',
          ),
          description: pick(
            'You logged steadier energy and manageable stress. Choose one thing worthy of your attention.',
            'Mas matatag ang lakas at kayang dalhin ang stress. Pumili ng isang bagay na bibigyan ng pansin.',
            'Steadier ang energy at manageable ang stress mo. Choose one thing worth your attention.',
          ),
          action: pick('Set today’s focus', 'Itakda ang pokus ngayon',
              'Set today’s focus'),
        ),
    };

    return _AdaptiveSupportCopy(
      eyebrow: common.eyebrow,
      heading: common.heading,
      title: content.title,
      description: content.description,
      action: content.action,
      privacy: common.privacy,
    );
  }

  static String _groundingDescription(
    AdaptiveSupportReason reason,
    String Function(String, String, String) pick,
  ) {
    final signal = switch (reason) {
      AdaptiveSupportReason.highStressAndAnxiety => pick(
          'higher stress and anxiety',
          'mas mataas na stress at pagkabalisa',
          'higher stress at anxiety',
        ),
      AdaptiveSupportReason.highAnxiety =>
        pick('higher anxiety', 'mas mataas na pagkabalisa', 'higher anxiety'),
      _ => pick('higher stress', 'mas mataas na stress', 'higher stress'),
    };
    return pick(
      'Your latest check-in showed $signal. A senses exercise can offer a steady point of attention.',
      'Nagpakita ang huling check-in ng $signal. Maaaring magbigay ng matatag na pokus ang ehersisyo sa mga pandama.',
      'Your latest check-in showed $signal. A senses exercise can give you a steady point of attention.',
    );
  }

  static String _breathingDescription(
    AdaptiveSupportReason reason,
    String Function(String, String, String) pick,
  ) {
    return switch (reason) {
      AdaptiveSupportReason.lowEnergyAndSleep => pick(
          'Energy and sleep were both lower in your latest check-in. A brief breathing pause asks very little of you.',
          'Mas mababa ang lakas at tulog sa huling check-in. Kaunti lamang ang hinihingi ng maikling paghinga.',
          'Lower ang energy at sleep sa latest check-in mo. A brief breathing pause asks very little of you.',
        ),
      AdaptiveSupportReason.lowEnergy => pick(
          'Energy was lower in your latest check-in. A brief breathing pause asks very little of you.',
          'Mas mababa ang lakas sa huling check-in. Kaunti lamang ang hinihingi ng maikling paghinga.',
          'Lower ang energy sa latest check-in mo. A brief breathing pause asks very little of you.',
        ),
      AdaptiveSupportReason.poorSleep => pick(
          'Sleep felt limited in your latest check-in. A brief breathing pause can be a low-effort reset.',
          'Kulang ang tulog sa huling check-in. Maaaring maging magaang na pahinga ang maikling paghinga.',
          'Limited ang sleep sa latest check-in mo. A brief breathing pause can be a low-effort reset.',
        ),
      _ => pick(
          'Nothing in your latest check-in needs fixing. A short breathing pause can simply mark a reset.',
          'Walang kailangang ayusin sa huling check-in. Maaaring maging simpleng pahinga ang maikling paghinga.',
          'Nothing in your latest check-in needs fixing. A short breathing pause can simply mark a reset.',
        ),
    };
  }
}
