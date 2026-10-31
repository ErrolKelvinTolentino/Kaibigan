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

  testWidgets('every entry category opens its unique feature viewer',
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

    // 1. Gratitude entry opens the FlowerDetailSheet with edit & delete
    await tester.enterText(find.byType(TextField).first, 'warm meal');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gratitude: Sunflower').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('flower-detail-sheet')), findsOneWidget);
    expect(find.text('“The warm meal my family shared.”'), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-gratitude-button')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('delete-gratitude-button')), findsOneWidget);

    Navigator.of(
            tester.element(find.byKey(const ValueKey('flower-detail-sheet'))))
        .pop();
    await tester.pumpAndSettle();

    // 2. Mood entry opens the MoodDetailSheet with mascot avatar, metrics, edit & delete
    await tester.enterText(find.byType(TextField).first, 'steady day');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mood: Good').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mood-detail-sheet')), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('mood-detail-sheet')),
            matching: find.text('Mood: Good')),
        findsOneWidget);
    expect(find.text('Stress: 2/5'), findsOneWidget);
    expect(find.text('Energy: 4/5'), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-mood-note-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('delete-mood-button')), findsOneWidget);

    Navigator.of(
            tester.element(find.byKey(const ValueKey('mood-detail-sheet'))))
        .pop();
    await tester.pumpAndSettle();

    // 3. Journal entry opens the UnifiedEntryDetailScreen
    await tester.enterText(find.byType(TextField).first, 'quiet realization');
    await tester.pumpAndSettle();
    await tester.tap(find.text('A quiet realization').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('entry-detail-journal')), findsOneWidget);
    await tester.tap(find.byTooltip('Back to all entries'));
    await tester.pumpAndSettle();

    // 4. Reflection entry opens the UnifiedEntryDetailScreen
    await tester.enterText(find.byType(TextField).first, 'evening reflection');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Evening reflection').last);
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('entry-detail-reflection')), findsOneWidget);
    await tester.tap(find.byTooltip('Back to all entries'));
    await tester.pumpAndSettle();

    // 5. Routine focus opens the focus detail view
    await tester.enterText(find.byType(TextField).first, 'meaningful task');
    await tester.pumpAndSettle();
    await tester.tap(find.text("Today's Focus").last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('entry-detail-focus')), findsOneWidget);
    expect(find.text('THE DIRECTION YOU CHOSE'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to all entries'));
    await tester.pumpAndSettle();

    // 6. Routine highlight opens the highlight detail view
    await tester.enterText(find.byType(TextField).first, 'laughing together');
    await tester.pumpAndSettle();
    await tester.tap(find.text("Today's Highlight").last);
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('entry-detail-highlight')), findsOneWidget);
    expect(find.text('THE MOMENT YOU KEPT'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to all entries'));
    await tester.pumpAndSettle();

    // 7. Sleep routine log opens the sleep detail view
    await tester.enterText(find.byType(TextField).first, 'sleep status');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sleep Status: Well Rested').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('entry-detail-sleep')), findsOneWidget);
    expect(find.text('REST & ENERGY'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to all entries'));
    await tester.pumpAndSettle();
  });

  Future<void> pumpRecords(WidgetTester tester, List<RoutineLog> logs) async {
    SharedPreferences.setMockInitialValues({'preferred_language': 'english'});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider<JournalProvider>(
            create: (_) => _FakeJournalProvider([])),
        ChangeNotifierProvider<GratitudeProvider>(
            create: (_) => _FakeGratitudeProvider([])),
        ChangeNotifierProvider<MoodProvider>(
            create: (_) => _FakeMoodProvider([])),
        ChangeNotifierProvider(
            create: (_) =>
                RoutinesProvider(initialLogs: logs, syncOnCreate: false)),
      ],
      child: const MaterialApp(home: UnifiedEntriesScreen()),
    ));
    await tester.pumpAndSettle();
  }

  RoutineLog savedLog(String routineId, String note, {SleepFeeling? feeling}) =>
      RoutineLog.fromMap({
        'id': 'saved-$routineId',
        'routine_id': routineId,
        'routine_type': 'morning',
        'completed_at': '2026-10-19T08:00:00Z',
        'focus_or_highlight': note,
        'sleep_feeling': feeling?.name,
      });

  for (final activity in ['breathing', 'grounding']) {
    testWidgets('saved $activity has its own record, filter and detail view',
        (tester) async {
      final breathing = activity == 'breathing';
      final note = breathing
          ? 'Completed 2 minute Box breathing breathing exercise.'
          : 'Completed 5-4-3-2-1 grounding with 5 saved observations.';
      final title = breathing ? 'Breathing Session' : 'Grounding Session';
      await pumpRecords(tester, [
        savedLog('${activity}_123', note),
        savedLog('focus_456', 'My real focus'),
      ]);
      expect(find.text(title), findsOneWidget);
      expect(find.text("Today's Highlight"), findsNothing);

      final filter = find.byKey(ValueKey('records-filter-$activity'));
      await tester.scrollUntilVisible(filter.hitTestable(), 150,
          scrollable: find.descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable)));
      await tester.tap(filter);
      await tester.pumpAndSettle();
      expect(tester.widget<ChoiceChip>(filter).selected, isTrue);
      expect(find.text(title), findsOneWidget);
      expect(find.text("Today's Focus"), findsNothing);
      expect(find.text('My real focus'), findsNothing);
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('entry-detail-$activity')), findsOneWidget);
      expect(find.text(breathing ? 'BREATHING SESSION' : 'GROUNDING SESSION'),
          findsOneWidget);
      expect(find.text('THE DIRECTION YOU CHOSE'), findsNothing);
      expect(find.text('“$note”'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final routineId in ['sleep_123', 'morning']) {
    testWidgets('$routineId sleep summary appears once as sleep, never focus',
        (tester) async {
      const summary = 'Slept 8 hrs (23:00->07:00): Woke up refreshed';
      await pumpRecords(tester,
          [savedLog(routineId, summary, feeling: SleepFeeling.wellRested)]);
      expect(find.text('Sleep Status: Well Rested'), findsOneWidget);
      expect(find.text(summary), findsOneWidget);
      expect(find.text("Today's Focus"), findsNothing);
      expect(find.text("Today's Highlight"), findsNothing);
      await tester.tap(find.text('Sleep Status: Well Rested'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('entry-detail-sleep')), findsOneWidget);
      expect(find.text(summary), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('combined morning routine retains a real focus and sleep log',
      (tester) async {
    await pumpRecords(tester, [
      savedLog('morning', 'Finish my project calmly.',
          feeling: SleepFeeling.wellRested)
    ]);
    expect(find.text("Today's Focus"), findsNWidgets(2));
    expect(find.text('Sleep Status: Well Rested'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Finish my project');
    await tester.pumpAndSettle();
    expect(find.text('Sleep Status: Well Rested'), findsNothing);
    expect(find.text('Finish my project calmly.'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
