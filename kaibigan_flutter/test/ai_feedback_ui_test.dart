import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/features/journaling/journal_editor_screen.dart';
import 'package:kaibigan_flutter/features/journaling/journal_model.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('journal feedback explains privacy and offers retry reasons',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'preferred_language': 'english',
      'selected_companion': 'kai',
    });
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final entry = JournalEntry(
      id: 'entry',
      title: 'A day',
      content: 'I felt stuck on my project today.',
      aiResponse: 'It sounds like the first step still feels unclear.',
      companionId: 'kai',
      createdAt: DateTime(2026, 8, 25),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: MaterialApp(home: JournalEditorScreen(initialEntry: entry)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Did this feel helpful?'), findsNothing);
    expect(find.byTooltip('Not helpful'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Not helpful'));
    await tester.tap(find.byTooltip('Not helpful'));
    await tester.pumpAndSettle();

    expect(find.text('What could be better?'), findsOneWidget);
    expect(find.text('No journal text is saved with this feedback.'),
        findsOneWidget);
    expect(find.text('Too generic'), findsOneWidget);
    expect(find.text('Wrong language or tone'), findsOneWidget);
  });
}
