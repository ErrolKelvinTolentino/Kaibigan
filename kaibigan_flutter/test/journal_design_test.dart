import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/core/widgets/journal_paper_surface.dart';
import 'package:kaibigan_flutter/features/journaling/journal_editor_screen.dart';
import 'package:kaibigan_flutter/features/journaling/journal_model.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({
        'preferred_language': 'english',
        'selected_companion': 'ann',
      }));

  Widget app(
          {JournalEntry? entry,
          bool dark = false,
          double keyboard = 0,
          double textScale = 1}) =>
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: JournalEditorScreen(entry: entry),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  viewInsets: EdgeInsets.only(bottom: keyboard),
                  textScaler: TextScaler.linear(textScale),
                  disableAnimations: true),
              child: child!),
        ),
      );

  testWidgets('journal has no mascot artwork and sharing follows writing',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('No rush. Start anywhere.'), findsOneWidget);
    expect(find.byKey(const ValueKey('companion-art-ann-welcoming')),
        findsNothing);
    expect(
        tester
            .widget<FilledButton>(
                find.byKey(const ValueKey('journal-share-button')))
            .onPressed,
        isNull);
    await tester.enterText(
        find.byKey(const ValueKey('active-journal-writing-field')),
        'Today I took a quiet walk.');
    await tester.pump();
    expect(
        tester
            .widget<FilledButton>(
                find.byKey(const ValueKey('journal-share-button')))
            .onPressed,
        isNotNull);
    expect(find.text('6 words'), findsOneWidget);
    expect(find.text('Save to keep this moment'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI replies are separate from the writing sheets',
      (tester) async {
    await tester.pumpWidget(app(
        entry: JournalEntry(
      id: 'conversation',
      title: 'A quiet walk',
      content: 'I needed some air.',
      aiResponse: 'It sounds like you gave yourself a little space.',
      companionId: 'ann',
      createdAt: DateTime(2026, 10, 12),
    )));
    await tester.pumpAndSettle();
    expect(find.byType(JournalPaperSurface), findsNWidgets(2));
    final reply = find.byKey(const ValueKey('journal-ai-reply-0'));
    expect(find.ancestor(of: reply, matching: find.byType(JournalPaperSurface)),
        findsNothing);
    expect(find.text('Your AI companion'), findsOneWidget);
    expect(find.byTooltip('Copy reflection'), findsOneWidget);
    expect(find.byTooltip('Not helpful'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets(
        'compact writing stays usable with keyboard and enlarged text ${dark ? 'at night' : 'by day'}',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app(dark: dark, keyboard: 260, textScale: 1.6));
      await tester.pumpAndSettle();
      expect(find.text('Your words. Your pace.'), findsOneWidget);
      await tester.enterText(
          find.byKey(const ValueKey('active-journal-writing-field')),
          'I have something on my mind.');
      await tester.pump();
      final controls =
          tester.getRect(find.byKey(const ValueKey('journal-editor-controls')));
      expect(controls.bottom, lessThanOrEqualTo(380));
      expect(
          tester
              .widget<FilledButton>(
                  find.byKey(const ValueKey('journal-share-button')))
              .onPressed,
          isNotNull);
      expect(tester.takeException(), isNull);
    });
  }
}
