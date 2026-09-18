import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/features/affirmations/affirmations_provider.dart';
import 'package:kaibigan_flutter/features/affirmations/affirmations_screen.dart';
import 'package:kaibigan_flutter/features/comfort_corner/comfort_corner_screen.dart';
import 'package:kaibigan_flutter/features/comfort_corner/comfort_provider.dart';
import 'package:kaibigan_flutter/features/future_letters/future_letters_screen.dart';
import 'package:kaibigan_flutter/features/future_letters/letters_provider.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/garden_screen.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_provider.dart';
import 'package:kaibigan_flutter/features/home/home_screen.dart';
import 'package:kaibigan_flutter/features/journaling/journal_editor_screen.dart';
import 'package:kaibigan_flutter/features/journaling/journal_list_screen.dart';
import 'package:kaibigan_flutter/features/journaling/journal_provider.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/friend_support/friend_support_hub_screen.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/learning_hub_screen.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/friend_support/friend_support_practice_model.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/friend_support/friend_support_practice_screen.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/learning_toolkit_screen.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_provider.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_tracker_screen.dart';
import 'package:kaibigan_flutter/features/routines/screens/daily_reflection_screen.dart';
import 'package:kaibigan_flutter/features/routines/screens/grounding_session_screen.dart';
import 'package:kaibigan_flutter/features/routines/screens/mindfulness_meditation_screen.dart';
import 'package:kaibigan_flutter/features/routines/screens/sleep_log_flow_screen.dart';
import 'package:kaibigan_flutter/core/services/ambient_sound_service.dart';
import 'package:kaibigan_flutter/features/routines/routines_hub_screen.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/routines/screens/sleep_analytics_screen.dart';
import 'package:kaibigan_flutter/features/settings/journal_appearance_screen.dart';
import 'package:kaibigan_flutter/features/settings/profile_screen.dart';
import 'package:kaibigan_flutter/features/settings/settings_screen.dart';
import 'package:kaibigan_flutter/features/settings/sound_settings_screen.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:kaibigan_flutter/features/unified_entries/unified_entries_screen.dart';
import 'package:kaibigan_flutter/features/weekly_reflection/weekly_reflection_screen.dart';

/// Renders the main screens on the smallest phones the app supports and at the
/// largest accessibility text size, and fails on any layout exception.
///
/// Overflow errors are the "red screen" people see in the running app, and the
/// combination that produces them is almost always narrow width plus enlarged
/// text — a pairing that is easy to miss on a development device.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'display_name': 'Sam',
      'preferred_language': 'english',
      'selected_companion': 'kai',
    });
  });

  Widget appWith(Widget home, {required double textScale}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AffirmationsProvider()),
        ChangeNotifierProvider(create: (_) => LettersProvider()),
        ChangeNotifierProvider(create: (_) => GratitudeProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => MoodProvider()),
        ChangeNotifierProvider(create: (_) => ComfortProvider()),
        ChangeNotifierProvider(
          create: (_) => RoutinesProvider(syncOnCreate: false),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: home,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            // Ambient motion never settles, and this suite only cares about
            // the resting layout.
            disableAnimations: true,
          ),
          child: child!,
        ),
      ),
    );
  }

  final screens = <String, Widget Function()>{
    'home': () => const HomeScreen(),
    'journal editor': () => const JournalEditorScreen(),
    'weekly reflection': () => const WeeklyReflectionScreen(),
    'sleep analytics': () => const SleepAnalyticsScreen(),
    'gratitude garden': () => const GardenScreen(),
    'journal list': () => const JournalListScreen(),
    'unified entries': () => const UnifiedEntriesScreen(),
    'routines hub': () => const RoutinesHubScreen(),
    'learning hub': () => const LearningHubScreen(),
    'friend support hub': () => const FriendSupportHubScreen(),
    'comfort corner': () => const ComfortCornerScreen(),
    'affirmations': () => const AffirmationsScreen(),
    'future letters': () => const FutureLettersScreen(),
    'journal appearance': () => const JournalAppearanceScreen(),
    'sound settings': () => const SoundSettingsScreen(language: 'english'),
    'settings': () => const SettingsScreen(),
    'profile': () => const ProfileScreen(),
    'daily reflection': () => const DailyReflectionScreen(),
    'mood tracker': () => const MoodTrackerScreen(),
    'sleep log flow': () => const SleepLogFlowScreen(),
    'breathing setup': () => MindfulnessMeditationScreen(
          soundPlayer: SilentAmbientSoundController(),
        ),
    'grounding session': () => const GroundingSessionScreen(),
    'learning toolkit': () => const LearningToolkitScreen(),
    'practice briefing': () => FriendSupportPracticeScreen(
          scenario: PracticeScenarios.byId('practice-hopeless'),
        ),
  };

  // 320x640 is the smallest phone still in circulation; 1.6 is a text size
  // people genuinely use.
  const sizes = <Size>[Size(320, 640), Size(390, 844)];
  const textScales = <double>[1.0, 1.6];

  for (final entry in screens.entries) {
    for (final size in sizes) {
      for (final scale in textScales) {
        testWidgets(
          '${entry.key} lays out at ${size.width.toInt()}px, ${scale}x text',
          (tester) async {
            await tester.binding.setSurfaceSize(size);
            addTearDown(() => tester.binding.setSurfaceSize(null));

            await tester.pumpWidget(
              appWith(entry.value(), textScale: scale),
            );
            await tester.pump(const Duration(milliseconds: 400));
            await tester.pump(const Duration(milliseconds: 400));

            expect(
              tester.takeException(),
              isNull,
              reason: '${entry.key} threw at ${size.width.toInt()}px '
                  'with ${scale}x text',
            );
          },
        );
      }
    }
  }
}
