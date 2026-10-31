import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/services/ai_service.dart';
import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/features/affirmations/affirmations_provider.dart';
import 'package:kaibigan_flutter/features/future_letters/letters_provider.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_provider.dart';
import 'package:kaibigan_flutter/features/journaling/journal_editor_screen.dart';
import 'package:kaibigan_flutter/features/journaling/journal_list_screen.dart';
import 'package:kaibigan_flutter/features/journaling/journal_model.dart';
import 'package:kaibigan_flutter/features/journaling/journal_provider.dart';
import 'package:kaibigan_flutter/features/journaling/journal_save_reflection_screen.dart';
import 'package:kaibigan_flutter/features/main_navigation_screen.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_provider.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(
      {'preferred_language': 'english'}));

  Widget app(Widget home) => MultiProvider(providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => GratitudeProvider()),
        ChangeNotifierProvider(create: (_) => MoodProvider()),
        ChangeNotifierProvider(
            create: (_) => RoutinesProvider(syncOnCreate: false)),
        ChangeNotifierProvider(create: (_) => LettersProvider()),
        ChangeNotifierProvider(create: (_) => AffirmationsProvider()),
      ], child: MaterialApp(theme: AppTheme.lightTheme, home: home));

  testWidgets('navbar follows scroll direction and restores destinations',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(const MainNavigationScreen()));
    await tester.pumpAndSettle();
    final bar = find.byKey(const ValueKey('scroll-aware-navbar'));
    expect(tester.getSize(bar).height, greaterThan(0));
    await tester.drag(
        find.byKey(const ValueKey('home-scroll-view')), const Offset(0, -350));
    await tester.pumpAndSettle();
    expect(tester.getSize(bar).height, 0);
    await tester.drag(
        find.byKey(const ValueKey('home-scroll-view')), const Offset(0, 180));
    await tester.pumpAndSettle();
    expect(tester.getSize(bar).height, greaterThan(0));
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1);
    expect(find.byTooltip('Back'), findsNothing);
    await tester.tap(find.byType(NavigationDestination).at(3));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('friend-support-entry-card')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'formatting follows the earlier selected turn and preserves focus',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final entry = JournalEntry(
        id: 'older-turn',
        title: 'Today',
        content: 'A hard day',
        aiResponse: 'I hear you.',
        companionId: 'kai',
        createdAt: DateTime(2026, 10, 12),
        conversationTurns: const [
          JournalConversationTurn(
              userText: 'A hard day', aiResponse: 'I hear you.')
        ]);
    await tester.pumpWidget(app(JournalEditorScreen(entry: entry)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('journal-format-toolbar')), findsNothing);
    final field = find.byType(TextField).at(1);
    await tester.tap(field);
    await tester.pump();
    final writing = tester.widget<TextField>(field);
    writing.controller!.selection =
        const TextSelection(baseOffset: 2, extentOffset: 6);
    await tester.tap(find.byKey(const ValueKey('journal-toggle-formatting')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('journal-format-bold')));
    await tester.pump();
    expect(writing.controller!.text, 'A **hard** day');
    expect(writing.focusNode!.hasFocus, isTrue);
    expect(
        tester
            .widget<TextField>(
                find.byKey(const ValueKey('active-journal-writing-field')))
            .controller!
            .text,
        isEmpty);
    for (final textField
        in tester.widgetList<TextField>(find.byType(TextField))) {
      expect(textField.decoration!.filled, false);
      expect(textField.decoration!.fillColor, Colors.transparent);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved insights reopen without a new AI request', (tester) async {
    var requests = 0;
    final entry = JournalEntry(
        id: 'saved',
        title: 'Today',
        content: 'I rested.',
        companionId: 'kai',
        createdAt: DateTime(2026, 10, 12),
        summary: const AIJournalSaveSummary(
            summary: 'A saved moment of rest.',
            emotions: ['calm'],
            moments: []));
    await tester.pumpWidget(MaterialApp(
        home: JournalSaveReflectionScreen(
      entry: entry,
      language: 'english',
      companionId: 'kai',
      summaryLoader: () async {
        requests++;
        throw StateError('Must use the saved summary');
      },
    )));
    await tester.pumpAndSettle();
    expect(find.text('A saved moment of rest.'), findsOneWidget);
    expect(requests, 0);
  });

  testWidgets('insight save failure is visible and retry uses the same summary',
      (tester) async {
    var attempts = 0;
    var requests = 0;
    final entry = JournalEntry(
        id: 'unsaved-summary',
        title: 'Today',
        content: 'I rested.',
        companionId: 'kai',
        createdAt: DateTime(2026, 10, 12));
    await tester.pumpWidget(MaterialApp(
        home: JournalSaveReflectionScreen(
      entry: entry,
      language: 'english',
      companionId: 'kai',
      summaryLoader: () async {
        requests++;
        return const AIJournalSaveSummary(
            summary: 'Rest mattered.', emotions: [], moments: []);
      },
      onSummaryReady: (_) async => ++attempts > 1,
    )));
    await tester.pumpAndSettle();
    expect(find.textContaining('could not be kept yet'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.textContaining('could not be kept yet'), findsNothing);
    expect(attempts, 2);
    expect(requests, 1);
  });

  testWidgets('AI journal shows only All and Favorites filter pills',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(app(const JournalListScreen()));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Favorites'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Reflections'), findsNothing);
    expect(find.widgetWithText(ChoiceChip, 'AI Journal'), findsNothing);
  });
}
