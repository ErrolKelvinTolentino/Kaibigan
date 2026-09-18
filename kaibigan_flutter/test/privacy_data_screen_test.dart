import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/features/settings/privacy_data_screen.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('privacy screen is specific and deletion needs typed consent',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = UserProvider();
    await provider.ready;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: PrivacyDataScreen(language: 'english'),
        ),
      ),
    );

    expect(find.text('Saved to your account'), findsOneWidget);
    expect(find.text('When you ask Kai'), findsOneWidget);
    // The AI card must name the seven-day summary that now travels with a
    // journal reflection, and the boundary that still holds.
    expect(
      find.textContaining('a short summary of your last seven days'),
      findsOneWidget,
    );
    expect(
      find.textContaining('never receives the text of your other entries'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('You can turn that off'),
      220,
    );
    expect(find.text('You can turn that off'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Kept on this device'),
      220,
    );
    expect(find.text('Kept on this device'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Wellness, not medical care'),
      220,
    );
    expect(find.text('Wellness, not medical care'), findsOneWidget);

    final deleteButton = find.byKey(const ValueKey('delete-account-button'));
    await tester.scrollUntilVisible(deleteButton, 220);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    FilledButton confirmButton() => tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Delete forever'),
        );
    expect(confirmButton().onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('delete-account-confirmation')),
      'DELETE',
    );
    await tester.pump();
    expect(confirmButton().onPressed, isNotNull);
  });
}
