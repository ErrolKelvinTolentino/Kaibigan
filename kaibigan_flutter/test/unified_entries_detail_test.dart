import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_model.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_provider.dart';
import 'package:kaibigan_flutter/features/journaling/journal_model.dart';
import 'package:kaibigan_flutter/features/journaling/journal_provider.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_model.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_provider.dart';
import 'package:kaibigan_flutter/features/routines/routine_model.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:kaibigan_flutter/features/unified_entries/unified_entries_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('every entry category opens its own fullscreen viewer',
      (tester) async {
    SharedPreferences.setMockInitialValues({'preferred_language': 'english'});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final now = DateTime(2026, 8, 25, 20, 30);
    final journal = JournalEntry(
      id: 'journal-one',
      title: 'A quiet realization',
      content: 'I noticed I was kinder to myself today.',
      aiResponse: 'That gentleness sounds worth carrying forward.',
      companionId: 'kai',
      createdAt: now,
    );
    final reflection = JournalEntry(
      id: 'reflection-one',
      title: 'Evening reflection',
      content: 'Today had both effort and rest.',
      aiResponse: 'You made room for the whole day.',
      companionId: 'ann',
      tags: const ['Daily Reflection'],
      createdAt: now.subtract(const Duration(minutes: 1)),
    );
    final gratitude = GratitudeEntry(
      id: 'gratitude-one',
      content: 'The warm meal my family shared.',
      flowerType: 'sunflower',
      gardenIndex: 0,
      plotIndex: 0,
      createdAt: now.subtract(const Duration(minutes: 2)),
    );
    final mood = MoodLog(
      id: 'mood-one',
      moodScore: 4,
      moodLabel: 'Good',
      stressLevel: 2,
      energyLevel: 4,
      sleepQuality: 3,
      anxietyLevel: 2,
      note: 'A steady day with enough breathing room.',
      createdAt: now.subtract(const Duration(minutes: 3)),
    );
    final focus = RoutineLog(
      id: 'focus-one',
      routineId: 'morning',
      routineType: RoutineType.morning,
      completedAt: now.subtract(const Duration(minutes: 4)),
      focusOrHighlight: 'Finish one meaningful task without rushing.',
    );
    final highlight = RoutineLog(
      id: 'highlight-one',
      routineId: 'night',
      routineType: RoutineType.night,
      completedAt: now.subtract(const Duration(minutes: 5)),
      focusOrHighlight: 'Laughing together after dinner.',
    );
    final sleep = RoutineLog(
      id: 'sleep-one',
      routineId: 'morning',
      routineType: RoutineType.morning,
      completedAt: now.subtract(const Duration(minutes: 6)),
      sleepFeeling: SleepFeeling.wellRested,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider<JournalProvider>(
            create: (_) => _FakeJournalProvider([journal, reflection]),
          ),
          ChangeNotifierProvider<GratitudeProvider>(
            create: (_) => _FakeGratitudeProvider([gratitude]),
          ),
          ChangeNotifierProvider<MoodProvider>(
            create: (_) => _FakeMoodProvider([mood]),
          ),
          ChangeNotifierProvider<RoutinesProvider>(
            create: (_) => _FakeRoutinesProvider([focus, highlight, sleep]),
          ),
        ],
        child: const MaterialApp(home: UnifiedEntriesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final cases = <({String query, String title, String key, String marker})>[
      (
        query: 'quiet realization',
        title: 'A quiet realization',
        key: 'entry-detail-journal',
        marker: 'JOURNAL CONVERSATION',
      ),
      (
        query: 'evening reflection',
        title: 'Evening reflection',
        key: 'entry-detail-reflection',
        marker: 'YOUR REFLECTION',
      ),
      (
        query: 'warm meal',
        title: 'Gratitude: Sunflower',
        key: 'entry-detail-gratitude',
        marker: 'A MEMORY IN BLOOM',
      ),
      (
        query: 'steady day',
        title: 'Mood: Good',
        key: 'entry-detail-mood',
        marker: 'CHECK-IN DETAILS',
      ),
      (
        query: 'meaningful task',
        title: "Today's Focus",
        key: 'entry-detail-focus',
        marker: 'THE DIRECTION YOU CHOSE',
      ),
      (
        query: 'laughing together',
        title: "Today's Highlight",
        key: 'entry-detail-highlight',
        marker: 'THE MOMENT YOU KEPT',
      ),
      (
        query: 'sleep status',
        title: 'Sleep Status: Well Rested',
        key: 'entry-detail-sleep',
        marker: 'REST & ENERGY',
      ),
    ];

    for (final detailCase in cases) {
      await tester.enterText(find.byType(TextField).first, detailCase.query);
      await tester.pumpAndSettle();
      await tester.tap(find.text(detailCase.title).last);
      await tester.pumpAndSettle();

      expect(find.byKey(ValueKey(detailCase.key)), findsOneWidget);
      expect(find.text(detailCase.marker), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      if (detailCase.key == 'entry-detail-gratitude') {
        expect(find.text('“The warm meal my family shared.”'), findsOneWidget);
        expect(find.byKey(const ValueKey('entry-detail-water-flower')),
            findsNothing);
        expect(find.byIcon(Icons.water_drop_outlined), findsNothing);
        expect(find.textContaining('Revisited'), findsNothing);
      }

      await tester.tap(find.byTooltip('Back to all entries'));
      await tester.pumpAndSettle();
    }
  });
}

class _FakeJournalProvider extends JournalProvider {
  _FakeJournalProvider(this._fakeEntries);

  final List<JournalEntry> _fakeEntries;

  @override
  List<JournalEntry> get entries => List.unmodifiable(_fakeEntries);
}

class _FakeGratitudeProvider extends GratitudeProvider {
  _FakeGratitudeProvider(this._fakeEntries);

  final List<GratitudeEntry> _fakeEntries;

  @override
  List<GratitudeEntry> get entries => List.unmodifiable(_fakeEntries);
}

class _FakeMoodProvider extends MoodProvider {
  _FakeMoodProvider(this._fakeLogs);

  final List<MoodLog> _fakeLogs;

  @override
  List<MoodLog> get logs => List.unmodifiable(_fakeLogs);
}

class _FakeRoutinesProvider extends RoutinesProvider {
  _FakeRoutinesProvider(this._fakeLogs);

  final List<RoutineLog> _fakeLogs;

  @override
  List<RoutineLog> get logs => List.unmodifiable(_fakeLogs);
}
