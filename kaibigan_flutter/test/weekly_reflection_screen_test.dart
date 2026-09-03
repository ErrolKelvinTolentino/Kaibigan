import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_provider.dart';
import 'package:kaibigan_flutter/features/journaling/journal_model.dart';
import 'package:kaibigan_flutter/features/journaling/journal_provider.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_model.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_provider.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:kaibigan_flutter/features/weekly_reflection/weekly_reflection_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  String currentStorageKey() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 6));
    return 'weekly_reflection_v4_local_${DateFormat('yyyyMMdd').format(start)}';
  }

  Widget screenUnderTest() => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider<JournalProvider>(
            create: (_) => _FakeJournalProvider([
              JournalEntry(
                id: 'weekly-entry',
                title: 'What helped',
                content: 'I felt overloaded, and stepping outside helped.',
                companionId: 'kai',
                createdAt: DateTime.now(),
              ),
            ]),
          ),
          ChangeNotifierProvider(create: (_) => GratitudeProvider()),
          ChangeNotifierProvider<MoodProvider>(
            create: (_) => _FakeMoodProvider([
              MoodLog(
                id: 'mood-this-week',
                moodScore: 4,
                moodLabel: 'Good',
                energyLevel: 3,
                stressLevel: 2,
                sleepQuality: 4,
                createdAt: DateTime.now(),
              ),
            ]),
          ),
          ChangeNotifierProvider(create: (_) => RoutinesProvider()),
        ],
        child: const MaterialApp(home: WeeklyReflectionScreen()),
      );

  testWidgets('old generic companion fallback is removed instead of shown',
      (tester) async {
    final storageKey = currentStorageKey();
    SharedPreferences.setMockInitialValues({
      'preferred_language': 'english',
      storageKey: '''
**What I noticed**

The emotional weight seems to sit closest to what happened today.

**Today's theme**

Pressure and limited energy.

**A question to sit with**

Which part of this feels most important to understand—not necessarily solve?
''',
    });
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(screenUnderTest());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('weekly-companion-reflection')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Create reflection'), findsOneWidget);
    expect(find.text('Pressure and limited energy.'), findsNothing);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey(storageKey), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved weekly narrative renders as three distinct sections',
      (tester) async {
    final storageKey = currentStorageKey();
    SharedPreferences.setMockInitialValues({
      'preferred_language': 'english',
      storageKey: jsonEncode({
        'version': 2,
        'savedAt': DateTime.now().toIso8601String(),
        'text': '''
**Evidence**

Mood averaged 4.0/5 across one check-in.

**Pattern**

One active day is not enough to establish a repeated pattern.

**One experiment**

Log mood before and after the busiest period on three days next week.
''',
      }),
    });
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(screenUnderTest());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('weekly-companion-reflection')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('WHAT YOU SHARED'), findsOneWidget);
    expect(find.text('WHAT MAY CONNECT'), findsOneWidget);
    expect(find.text('TRY THIS NEXT'), findsOneWidget);
    expect(find.textContaining('Mood averaged 4.0/5'), findsOneWidget);
    expect(find.text('Reflect again'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    final migrated = jsonDecode(preferences.getString(storageKey)!);
    expect(migrated['version'], 4);
    expect(migrated['snapshotSignature'], isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stale reflection is removed when weekly totals have changed',
      (tester) async {
    final storageKey = currentStorageKey();
    SharedPreferences.setMockInitialValues({
      'preferred_language': 'english',
      storageKey: jsonEncode({
        'version': 3,
        'savedAt': DateTime.now().toIso8601String(),
        'snapshotSignature': 'older-weekly-totals',
        'text': '''
**Evidence**

Old evidence that no longer matches.

**Pattern**

Old pattern that no longer matches.

**One experiment**

Old experiment that no longer matches.
''',
      }),
    });
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(screenUnderTest());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('weekly-companion-reflection')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Create reflection'), findsOneWidget);
    expect(find.textContaining('Old evidence'), findsNothing);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey(storageKey), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('weekly reflection generates and saves a structured fallback',
      (tester) async {
    final storageKey = currentStorageKey();
    SharedPreferences.setMockInitialValues({
      'preferred_language': 'english',
    });
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(screenUnderTest());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('weekly-companion-reflection')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final generateButton =
        find.byKey(const ValueKey('weekly-reflection-generate'));
    await tester.ensureVisible(generateButton);
    await tester.pumpAndSettle();
    await tester.tap(generateButton);
    await tester.pumpAndSettle();

    expect(find.text('WHAT YOU SHARED'), findsOneWidget);
    expect(find.text('WHAT MAY CONNECT'), findsOneWidget);
    expect(find.text('TRY THIS NEXT'), findsOneWidget);
    expect(find.textContaining('stepping outside helped'), findsWidgets);
    expect(
      find.byKey(const ValueKey('weekly-reflection-device-note')),
      findsOneWidget,
    );
    final preferences = await SharedPreferences.getInstance();
    final saved = jsonDecode(preferences.getString(storageKey)!);
    expect(saved['version'], 4);
    expect(saved['snapshotSignature'], isNotEmpty);
    expect(tester.takeException(), isNull);
  });
}

class _FakeMoodProvider extends MoodProvider {
  _FakeMoodProvider(this._logs);

  final List<MoodLog> _logs;

  @override
  List<MoodLog> get logs => List.unmodifiable(_logs);

  @override
  Future<void> fetchMoodLogs() async {}
}

class _FakeJournalProvider extends JournalProvider {
  _FakeJournalProvider(this._entries);

  final List<JournalEntry> _entries;

  @override
  List<JournalEntry> get allEntries => List.unmodifiable(_entries);

  @override
  Future<void> fetchJournalEntries() async {}
}
