import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/services/offline_mode.dart';
import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/flower_detail_sheet.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_provider.dart';
import 'package:kaibigan_flutter/features/settings/settings_screen.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'preferred_language': 'english'});
    OfflineMode.setEnabledForTesting(true);
  });

  testWidgets('saving gratitude survives the dialog closing transition',
      (tester) async {
    final provider = GratitudeProvider();
    await provider.fetchGratitudeEntries();
    final entry = await provider.addGratitudeEntry('Original note');
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () => FlowerDetailSheet.showEditDialog(context,
                          entry: entry!, provider: provider),
                      child: const Text('Edit')),
                ))));
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Updated note');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(provider.entries.single.content, 'Updated note');
    final reader = GratitudeProvider();
    await reader.fetchGratitudeEntries();
    expect(reader.entries.single.content, 'Updated note');
  });

  testWidgets('Filipino selection keeps Material controls and Settings usable',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final user = UserProvider();
    await user.ready;
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: user,
      child: Consumer<UserProvider>(
          builder: (_, user, __) => MaterialApp(
                theme: AppTheme.lightTheme,
                locale: user.language == 'filipino'
                    ? const Locale('fil')
                    : const Locale('en'),
                supportedLocales: const [Locale('en'), Locale('fil')],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate
                ],
                home: const SettingsScreen(),
              )),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Language'));
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filipino'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(user.language, 'filipino');
    expect(find.text('Wika'), findsOneWidget);
  });
}
