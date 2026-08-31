import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/features/future_letters/future_letters_screen.dart';
import 'package:kaibigan_flutter/features/future_letters/letters_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('letter composer gently discloses its four-stage flow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LettersProvider(),
        child: const MaterialApp(home: FutureLettersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('future-letters-banner')), findsOneWidget);
    expect(find.text('A quiet inbox from you.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('write-letter-button')));
    await tester.pumpAndSettle();

    expect(find.text('What is this letter for?'), findsOneWidget);
    for (var index = 0; index < 4; index++) {
      expect(find.byKey(ValueKey('composer-progress-$index')), findsOneWidget);
    }

    await tester.enterText(
      find.byKey(const ValueKey('letter-title-field')),
      'For a braver Tuesday',
    );
    await tester.tap(find.byKey(const ValueKey('composer-next-button')));
    await tester.pumpAndSettle();

    expect(find.text('Write the part worth keeping.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('letter-message-field')),
      'You already know how to begin.',
    );
    await tester.tap(find.byKey(const ValueKey('composer-next-button')));
    await tester.pumpAndSettle();

    expect(find.text('When should it find you?'), findsOneWidget);
    expect(find.text('3 days'), findsOneWidget);
    expect(find.text('1 month'), findsOneWidget);
    expect(find.text('1 year'), findsOneWidget);
    expect(find.text('3 years'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('composer-next-button')));
    await tester.pumpAndSettle();

    expect(find.text('Ready to seal it?'), findsOneWidget);
    expect(find.text('For a braver Tuesday'), findsOneWidget);
    expect(find.text('You already know how to begin.'), findsOneWidget);
  });
}
