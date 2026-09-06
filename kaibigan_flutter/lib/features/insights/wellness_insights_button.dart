import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/kaibigan_tokens.dart';
import '../../core/utils/language_helper.dart';
import '../mood_tracking/mood_provider.dart';
import '../routines/routines_provider.dart';
import '../settings/user_provider.dart';
import 'wellness_analytics.dart';
import 'wellness_insights_panel.dart';

class WellnessInsightsButton extends StatelessWidget {
  const WellnessInsightsButton({super.key, required this.feature});
  final String feature;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider?>();
    final language = user?.language ?? 'english';
    return IconButton(
      key: ValueKey('$feature-insights-button'),
      tooltip: LanguageHelper.pick(language,
          english: 'Your last 7 days',
          filipino: 'Ang huling 7 araw mo',
          taglish: 'Your last 7 days'),
      icon: const Icon(Icons.insights_outlined),
      onPressed: () {
        final snapshot = WellnessAnalytics.build(
            now: DateTime.now(),
            routines: context.read<RoutinesProvider?>()?.logs ?? [],
            moods: context.read<MoodProvider?>()?.logs ?? []);
        showWellnessDetails(context, snapshot, language, feature);
      },
    );
  }
}

Future<void> showWellnessDetails(BuildContext context,
        WellnessSnapshot snapshot, String language, String feature) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 600),
      backgroundColor: context.kaibigan.background,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .8,
        minChildSize: .4,
        maxChildSize: .95,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Row(children: [
              Expanded(
                  child: Text(
                      LanguageHelper.pick(language,
                          english: 'Your last 7 days',
                          filipino: 'Ang huling 7 araw mo'),
                      style: Theme.of(context).textTheme.titleLarge)),
              IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded)),
            ]),
            const SizedBox(height: 16),
            WellnessInsightsPanel(
                snapshot: snapshot, language: language, feature: feature),
          ],
        ),
      ),
    );
