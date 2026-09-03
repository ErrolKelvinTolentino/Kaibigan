import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/features/affirmations/affirmation_model.dart';
import 'package:kaibigan_flutter/features/affirmations/affirmations_provider.dart';
import 'package:kaibigan_flutter/features/affirmations/affirmations_screen.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('every affirmation category contains 30 distinct supportive reminders',
      () {
    final all = <String>{};
    final allFilipino = <String>{};

    expect(AffirmationCatalog.categories.length, 6);
    for (final category in AffirmationCatalog.categories) {
      expect(category.affirmations.length, 30, reason: category.id);
      expect(category.affirmations.toSet().length, 30, reason: category.id);
      expect(category.filipinoAffirmations.length, 30, reason: category.id);
      expect(category.filipinoAffirmations.toSet().length, 30,
          reason: category.id);
      for (final affirmation in category.affirmations) {
        expect(affirmation, affirmation.trim());
        expect(affirmation.length, inInclusiveRange(30, 150));
        expect(affirmation, matches(RegExp(r'[.!?”]$')));
        expect(
          affirmation.toLowerCase(),
          isNot(matches(RegExp(
            r'\b(cure|guarantee|invincible|i can do anything|everything will be okay|always happy)\b',
          ))),
        );
        expect(all.add(affirmation), isTrue,
            reason: 'Duplicate affirmation: $affirmation');
      }
      for (final affirmation in category.filipinoAffirmations) {
        expect(affirmation, affirmation.trim());
        expect(affirmation.length, inInclusiveRange(25, 180));
        expect(affirmation, matches(RegExp(r'[.!?”]$')));
        expect(allFilipino.add(affirmation), isTrue,
            reason: 'Duplicate Filipino affirmation: $affirmation');
      }
    }
  });

  test('selected focus persists and today’s reminder is stable', () async {
    SharedPreferences.setMockInitialValues({
      'affirmation_category_id': 'calm_grounding',
    });
    final provider = AffirmationsProvider();
    await provider.ready;

    final today = DateTime(2026, 8, 25, 10);
    expect(provider.selectedCategoryId, 'calm_grounding');
    expect(
        provider.affirmationForDay(today), provider.affirmationForDay(today));
    expect(
      provider.affirmationForDay(today),
      isNot(provider.affirmationForDay(today.add(const Duration(days: 1)))),
    );
    expect(
      AffirmationCatalog.byId('calm_grounding')!.filipinoAffirmations,
      contains(provider.affirmationForDay(today, language: 'filipino')),
    );

    await provider.selectCategory('self_compassion');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('affirmation_category_id'), 'self_compassion');
  });

  test('home always receives a passive daily quote before focus selection',
      () async {
    SharedPreferences.setMockInitialValues({});
    final provider = AffirmationsProvider();
    await provider.ready;

    final today = DateTime(2026, 8, 25, 10);
    expect(provider.selectedCategory, isNull);
    expect(provider.affirmationForDay(today), isNull);
    expect(provider.homeAffirmationForDay(today), isNotEmpty);
  });

  testWidgets('users choose a focus before entering the finite vertical feed',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'preferred_language': 'english',
    });
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => AffirmationsProvider()),
        ],
        child: const MaterialApp(home: AffirmationsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('affirmation-category-chooser')),
        findsOneWidget);
    expect(find.text('What kind of reminder would feel supportive?'),
        findsOneWidget);
    expect(find.text('Self-compassion'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('affirmation-category-self_compassion')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('affirmation-vertical-feed')),
        findsOneWidget);
    expect(find.text('1 / 30'), findsOneWidget);
    expect(find.text('Keep what feels honest. Skip what does not.'),
        findsOneWidget);
  });

  testWidgets('Filipino preference uses the complete Filipino affirmation set',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'preferred_language': 'filipino',
      'affirmation_category_id': 'self_compassion',
    });
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => AffirmationsProvider()),
        ],
        child: const MaterialApp(home: AffirmationsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final category = AffirmationCatalog.byId('self_compassion')!;
    final visibleText = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .whereType<String>()
        .toSet();

    expect(find.text('Pag-unawa sa sarili'), findsOneWidget);
    expect(find.text('1 / 30'), findsOneWidget);
    expect(
      category.filipinoAffirmations.any(visibleText.contains),
      isTrue,
      reason: 'The visible affirmation should come from the Filipino set.',
    );
    expect(find.text('Piliin ang tapat sa iyo. Laktawan ang hindi.'),
        findsOneWidget);
  });
}
