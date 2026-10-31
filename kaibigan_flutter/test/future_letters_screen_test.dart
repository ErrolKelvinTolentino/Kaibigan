import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/features/future_letters/future_letters_screen.dart';
import 'package:kaibigan_flutter/features/future_letters/letters_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kaibigan_flutter/core/services/offline_mode.dart';

void main() {
  testWidgets(
      'custom delivery accepts today with a later time and seals the letter',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    OfflineMode.setEnabledForTesting(true);
    addTearDown(() => OfflineMode.setEnabledForTesting(false));
    await tester.binding.setSurfaceSize(const Size(390, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final letters = LettersProvider();
    await letters.fetchLetters();
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: letters, child: const MaterialApp(home: FutureLettersScreen())));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('write-letter-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('letter-title-field')), 'Today’s letter');
    await tester.tap(find.byKey(const ValueKey('composer-next-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('letter-message-field')),
        'Remember this afternoon.');
    await tester.tap(find.byKey(const ValueKey('composer-next-button')));
    await tester.pumpAndSettle();
    final custom =
        find.widgetWithIcon(OutlinedButton, Icons.calendar_month_outlined);
    await tester.ensureVisible(custom);
    await tester.tap(custom);
    await tester.pumpAndSettle();
    final today = DateUtils.dateOnly(DateTime.now());
    expect(
        tester
            .widget<DatePickerDialog>(find.byType(DatePickerDialog))
            .firstDate,
        today);
    // Select today's supported calendar day, then confirm through the real dialog.
    tester
        .widget<CalendarDatePicker>(find.byType(CalendarDatePicker))
        .onDateChanged(today);
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    final time = tester
        .widget<TimePickerDialog>(find.byType(TimePickerDialog))
        .initialTime;
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    final expected =
        DateTime(today.year, today.month, today.day, time.hour, time.minute);
    if (!expected.isAfter(DateTime.now())) {
      // At the very end of the day there is no later same-day minute.
      expect(
          find.text('Choose a delivery time later than now.'), findsOneWidget);
      return;
    }
    await tester.tap(find.byKey(const ValueKey('composer-next-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('composer-next-button')));
    await tester.pumpAndSettle();
    expect(letters.letters, hasLength(1));
    expect(letters.letters.single.deliverAt, expected);
    expect(letters.letters.single.isReadyToUnlock, isFalse);
    expect(tester.takeException(), isNull);
  });
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
