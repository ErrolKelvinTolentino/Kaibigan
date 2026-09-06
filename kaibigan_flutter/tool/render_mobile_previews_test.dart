// Opt-in visual QA: flutter test tool/render_mobile_previews_test.dart --update-goldens
// Uses a local system font for preview rendering, without downloading assets.
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as font_test;

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kaibigan_flutter/core/theme/app_theme.dart';
import 'package:kaibigan_flutter/features/affirmations/affirmations_provider.dart';
import 'package:kaibigan_flutter/features/future_letters/letters_provider.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_provider.dart';
import 'package:kaibigan_flutter/features/home/home_screen.dart';
import 'package:kaibigan_flutter/features/journaling/journal_provider.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/learning_catalog.dart';
import 'package:kaibigan_flutter/features/mental_health_learning/learning_lesson_screen.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_model.dart';
import 'package:kaibigan_flutter/features/mood_tracking/mood_provider.dart';
import 'package:kaibigan_flutter/features/routines/routine_model.dart';
import 'package:kaibigan_flutter/features/routines/routines_provider.dart';
import 'package:kaibigan_flutter/features/insights/wellness_analytics.dart';
import 'package:kaibigan_flutter/features/insights/wellness_insights_panel.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = File('C:/Windows/Fonts/segoeui.ttf');
    if (!await font.exists()) return;
    final bytes = ByteData.sublistView(await font.readAsBytes());
    font_test.assetManifest = _PreviewFontManifest();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      final path = utf8.decode(message!.buffer
          .asUint8List(message.offsetInBytes, message.lengthInBytes));
      if (path.startsWith('preview-fonts/')) return bytes;
      return messenger.delegate.send('flutter/assets', message);
    });
    final families = <String>{
      'Preview',
      'Roboto',
      'serif',
      'Quicksand_regular',
      'Quicksand_500',
      'Quicksand_600',
      'Quicksand_700',
      'Quicksand_800',
      'Quicksand_900'
    };
    final icons = File(
        'C:/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    await (FontLoader('MaterialIcons')
          ..addFont(
              Future.value(ByteData.sublistView(await icons.readAsBytes()))))
        .load();
    for (final family in families) {
      await (FontLoader(family)..addFont(Future.value(bytes))).load();
    }
  });
  setUp(() => SharedPreferences.setMockInitialValues(
      {'preferred_language': 'english', 'display_name': 'Sam'}));
  testWidgets('render home cards and learning on a phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final user = UserProvider();
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: user),
          ChangeNotifierProvider(create: (_) => AffirmationsProvider()),
          ChangeNotifierProvider(create: (_) => LettersProvider()),
          ChangeNotifierProvider(create: (_) => GratitudeProvider()),
          ChangeNotifierProvider(create: (_) => JournalProvider()),
          ChangeNotifierProvider(create: (_) => MoodProvider()),
          ChangeNotifierProvider(
              create: (_) => RoutinesProvider(syncOnCreate: false)),
        ],
        child: MaterialApp(
            theme: previewTheme(),
            home: const RepaintBoundary(
                key: ValueKey('preview'), child: HomeScreen()))));
    await tester.pumpAndSettle();
    await expectLater(find.byKey(const ValueKey('preview')),
        matchesGoldenFile('../../output/mobile-home.png'));
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('home-routine-card')), 400,
        scrollable: find
            .descendant(
                of: find.byKey(const ValueKey('home-scroll-view')),
                matching: find.byType(Scrollable))
            .first);
    await tester.pumpAndSettle();
    await expectLater(find.byKey(const ValueKey('preview')),
        matchesGoldenFile('../../output/mobile-home-actions.png'));
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: user,
        child: MaterialApp(
            theme: previewTheme(),
            home: RepaintBoundary(
                key: const ValueKey('lesson-preview'),
                child: LearningLessonScreen(
                    lesson: LearningCatalog.lessons.first)))));
    await tester.pumpAndSettle();
    await expectLater(find.byKey(const ValueKey('lesson-preview')),
        matchesGoldenFile('../../output/mobile-lesson.png'));
  });
  testWidgets('render weekly insights on a phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime(2026, 9, 6, 20);
    final snapshot = WellnessAnalytics.build(now: now, moods: [
      for (var i = 0; i < 4; i++)
        MoodLog(
            id: 'm$i',
            moodScore: 3 + i % 2,
            moodLabel: 'Okay',
            createdAt: now.subtract(Duration(days: i)))
    ], routines: [
      for (var i = 0; i < 3; i++)
        RoutineLog(
            id: 's$i',
            routineId: 'sleep_$i',
            routineType: RoutineType.morning,
            completedAt: now.subtract(Duration(days: i)),
            sleepFeeling: SleepFeeling.wellRested,
            focusOrHighlight: 'Slept 7.5 hrs')
    ]);
    await tester.pumpWidget(MaterialApp(
        theme: previewTheme(),
        home: RepaintBoundary(
            key: const ValueKey('preview'),
            child: Scaffold(
                appBar: AppBar(title: const Text('Weekly insights')),
                body: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: WellnessInsightsPanel(
                        snapshot: snapshot, language: 'english'))))));
    await tester.pumpAndSettle();
    await expectLater(find.byKey(const ValueKey('preview')),
        matchesGoldenFile('../../output/mobile-insights.png'));
  });
}

class _PreviewFontManifest implements AssetManifest {
  @override
  List<String> listAssets() => [
        for (final family in ['Quicksand', 'Lora'])
          for (final weight in [
            'Regular',
            'Medium',
            'SemiBold',
            'Bold',
            'ExtraBold',
            'Black'
          ])
            'preview-fonts/$family-$weight.ttf'
      ];
  @override
  List<AssetMetadata>? getAssetVariants(String key) => null;
}

ThemeData previewTheme() {
  final base = AppTheme.lightTheme;
  const label = TextStyle(
      fontFamily: 'Preview', fontSize: 14, fontWeight: FontWeight.w600);
  return base.copyWith(
    filledButtonTheme: FilledButtonThemeData(
        style: base.filledButtonTheme.style
            ?.copyWith(textStyle: const WidgetStatePropertyAll(label))),
    textButtonTheme: TextButtonThemeData(
        style: base.textButtonTheme.style
            ?.copyWith(textStyle: const WidgetStatePropertyAll(label))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: base.outlinedButtonTheme.style
            ?.copyWith(textStyle: const WidgetStatePropertyAll(label))),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: base.elevatedButtonTheme.style
            ?.copyWith(textStyle: const WidgetStatePropertyAll(label))),
  );
}
