import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/constants/app_colors.dart';
import 'package:kaibigan_flutter/core/theme/garden_appearance.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/garden_layout.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/garden_screen.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_model.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_provider.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_planting_page.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/polished_flower_asset.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/responsive_garden_scene.dart';
import 'package:kaibigan_flutter/features/settings/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  GratitudeEntry entry(
    int number, {
    int? gardenIndex,
    int? plotIndex,
    String flowerType = 'sunflower',
  }) {
    return GratitudeEntry(
      id: 'flower-$number',
      content: 'Gratitude $number',
      flowerType: flowerType,
      gardenIndex: gardenIndex ?? number ~/ GardenLayout.capacity,
      plotIndex: plotIndex ?? number % GardenLayout.capacity,
      createdAt: DateTime(2026, 8, 1).add(Duration(days: number)),
    );
  }

  /// The garden sways its blooms continuously, so tests that settle the tree
  /// ask for reduced motion the same way the platform would.
  Widget stillApp(Widget home) => MaterialApp(
        home: home,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
      );

  test('garden backgrounds follow local day and night hours', () {
    expect(
      GardenLayout.periodFor(DateTime(2026, 8, 25, 6)),
      GardenScenePeriod.day,
    );
    expect(
      GardenLayout.periodFor(DateTime(2026, 8, 25, 17, 59)),
      GardenScenePeriod.day,
    );
    expect(
      GardenLayout.periodFor(DateTime(2026, 8, 25, 18)),
      GardenScenePeriod.night,
    );
    expect(
      GardenLayout.backgroundAssetFor(DateTime(2026, 8, 25, 23)),
      contains('Garden BG Night.png'),
    );
    expect(
      GardenLayout.periodFor(
        DateTime(2026, 8, 25, 23),
        appearance: GardenAppearance.day,
      ),
      GardenScenePeriod.day,
    );
    expect(
      GardenLayout.periodFor(
        DateTime(2026, 8, 25, 12),
        appearance: GardenAppearance.night,
      ),
      GardenScenePeriod.night,
    );
  });

  test('ten perspective plots stay inside the supplied clean lawn', () {
    expect(GardenLayout.plots.length, GardenLayout.capacity);
    expect(
      GardenLayout.plots.map((plot) => '${plot.x}-${plot.groundY}').toSet(),
      hasLength(10),
    );
    for (final plot in GardenLayout.plots) {
      expect(plot.x, inInclusiveRange(220, 850));
      expect(plot.groundY, inInclusiveRange(740, 1670));
    }
  });

  test('every plot renders its bloom at the same size', () {
    expect(GardenLayout.flowerScale, inInclusiveRange(0.55, 1.05));
  });

  test('a new garden unlocks only after ten flowers', () {
    expect(GardenLayout.unlockedGardenCount(const []), 1);
    expect(
      GardenLayout.unlockedGardenCount(List.generate(9, entry)),
      1,
    );
    expect(
      GardenLayout.unlockedGardenCount(List.generate(10, entry)),
      2,
    );
    expect(
      GardenLayout.unlockedGardenCount(List.generate(19, entry)),
      2,
    );
    expect(
      GardenLayout.unlockedGardenCount(List.generate(20, entry)),
      3,
    );
  });

  test('unlocked gardens remain available when an older plot is cleared', () {
    final entries = List.generate(11, entry)..removeAt(3);

    expect(GardenLayout.unlockedGardenCount(entries), 2);
    expect(GardenLayout.firstAvailablePlot(entries, 0), 3);
    expect(GardenLayout.isFull(entries, 0), isFalse);
  });

  test('all supplied flower assets have distinct paths and varied scales', () {
    final paths = GratitudeEntry.availableFlowerTypes
        .map(GratitudeEntry.getFlowerAssetPath)
        .toSet();
    final scales = GratitudeEntry.availableFlowerTypes
        .map(GratitudeEntry.getFlowerScale)
        .toSet();

    expect(GratitudeEntry.availableFlowerTypes, hasLength(10));
    expect(paths, hasLength(10));
    expect(scales.length, greaterThan(3));
    expect(
      GratitudeEntry.getFlowerAssetPath('sampaguita'),
      endsWith('Lily.png'),
    );
  });

  test('garden placement round-trips through database maps', () {
    final original = entry(19, flowerType: 'lavender');
    final map = original.toMap();
    final restored = GratitudeEntry.fromMap({
      ...map,
      'growth_stage': 1,
      'water_count': 7,
    });

    expect(map, isNot(contains('growth_stage')));
    expect(map, isNot(contains('water_count')));
    expect(restored.toMap(), isNot(contains('water_count')));
    expect(restored.content, original.content);
    expect(restored.gardenIndex, 1);
    expect(restored.plotIndex, 9);
    expect(restored.flowerType, 'lavender');
  });

  testWidgets('flower art uses smooth edges and a restrained glow',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: PolishedFlowerAsset(
            flowerType: 'sunflower',
            width: 120,
            height: 220,
            glowOpacity: 0.16,
          ),
        ),
      ),
    );

    expect(find.byType(ImageFiltered), findsOneWidget);
    expect(find.byType(ColorFiltered), findsOneWidget);
    final images = tester.widgetList<Image>(find.byType(Image));
    expect(images, hasLength(2));
    for (final image in images) {
      expect(image.filterQuality, FilterQuality.high);
      expect(image.isAntiAlias, isTrue);
      expect(image.fit, BoxFit.contain);
    }
  });

  testWidgets('a full garden exposes the next unlocked garden', (tester) async {
    SharedPreferences.setMockInitialValues({
      'preferred_language': 'english',
      'garden_appearance': 'night',
    });
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final entries = List.generate(GardenLayout.capacity, entry);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider<GratitudeProvider>(
            create: (_) => _FakeGratitudeProvider(entries),
          ),
        ],
        child: stillApp(const GardenScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ResponsiveGardenScene), findsOneWidget);
    expect(
      find.byKey(const ValueKey(
        'assets/gratitude garden assets/Garden BG Night.png',
      )),
      findsOneWidget,
    );
    expect(find.text('Garden 1 of 2'), findsOneWidget);
    expect(find.text('10 / 10 flowers'), findsOneWidget);
    expect(find.text('Open Garden 2'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('garden-flower-shadow-flower-0')),
      findsOneWidget,
    );
    final firstFlower = tester.widget<PolishedFlowerAsset>(
      find.byType(PolishedFlowerAsset).first,
    );
    expect(firstFlower.glowOpacity, greaterThanOrEqualTo(0.3));
    expect(
      firstFlower.width,
      closeTo(282 * 1.3 * GardenLayout.flowerScale * 0.84, 0.01),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('garden-navigator'))).dy,
      greaterThan(
        tester
            .getBottomLeft(find.byKey(const ValueKey('garden-flower-flower-0')))
            .dy,
      ),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('garden-controls')),
        matching: find.byKey(const ValueKey('garden-navigator')),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('garden-view-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gratitude 9'));
    await tester.pumpAndSettle();
    expect(find.text('“Gratitude 9”'), findsOneWidget);
    expect(find.text('Edit gratitude'), findsOneWidget);
    expect(find.byTooltip('Remove flower'), findsOneWidget);
    expect(find.byIcon(Icons.water_drop_outlined), findsNothing);
    expect(find.textContaining('Watered'), findsNothing);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('garden-view-toggle')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('open-next-garden')));
    await tester.pumpAndSettle();

    expect(find.text('Garden 2 of 2'), findsOneWidget);
    expect(find.byKey(const ValueKey('empty-garden-plant-action')),
        findsOneWidget);
  });

  testWidgets('garden header controls stay readable over the illustration',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'preferred_language': 'english',
      'garden_appearance': 'day',
    });
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider<GratitudeProvider>(
            create: (_) => _FakeGratitudeProvider([]),
          ),
        ],
        child: stillApp(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                key: const ValueKey('open-garden'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const GardenScreen(),
                  ),
                ),
                child: const Text('Open garden'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-garden')));
    await tester.pumpAndSettle();

    final back = tester.widget<Material>(
      find.byKey(const ValueKey('garden-back-button')),
    );
    final menu = tester.widget<Material>(
      find.byKey(const ValueKey('garden-view-toggle')),
    );
    expect(back.color, AppColors.pollenGlow.withValues(alpha: .96));
    expect(menu.color, AppColors.pollenGlow.withValues(alpha: .96));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('garden-back-button')),
        matching: find.byIcon(Icons.arrow_back_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('garden-view-toggle')),
        matching: find.byIcon(Icons.format_list_bulleted_rounded),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'planting uses fullscreen gentle disclosure and a flower carousel',
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
          ChangeNotifierProvider<GratitudeProvider>(
            create: (_) => _FakeGratitudeProvider([]),
          ),
        ],
        child: stillApp(const GardenScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('plant-flower')));
    await tester.pumpAndSettle();

    expect(find.byType(GratitudePlantingPage), findsOneWidget);
    expect(find.byKey(const ValueKey('gratitude-reflection-step')),
        findsOneWidget);
    expect(
      find.byKey(const ValueKey('gratitude-paper-note')),
      findsOneWidget,
    );
    expect(
        find.byKey(const ValueKey('gratitude-flower-carousel')), findsNothing);
    expect(find.byType(DraggableScrollableSheet), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('gratitude-planting-page'))),
      const Size(360, 800),
    );

    await tester.tap(find.byKey(const ValueKey('continue-to-flower')));
    await tester.pump();
    expect(
      find.text('Write one honest thing you appreciate before continuing.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('gratitude-planting-field')),
      'The quiet cup of tea I had after a long afternoon.',
    );
    await tester.tap(find.byKey(const ValueKey('continue-to-flower')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('gratitude-flower-carousel')),
        findsOneWidget);
    // A quiet cup of tea reads as calm, so the carousel opens on Lavender and
    // marks it, while every other bloom stays one swipe away.
    expect(
      find.byKey(const ValueKey('gratitude-flower-suggestion')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('flower-seed-lavender')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('flower-suggested-chip-lavender')),
      findsOneWidget,
    );
    expect(find.text('Lavender'), findsOneWidget);
    expect(find.byKey(const ValueKey('confirm-plant-flower')), findsOneWidget);
  });

  testWidgets('planted flowers sway, and hold still under reduced motion',
      (tester) async {
    SharedPreferences.setMockInitialValues({'preferred_language': 'english'});
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Widget garden({required bool reduceMotion}) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => UserProvider()),
            ChangeNotifierProvider<GratitudeProvider>(
              create: (_) => _FakeGratitudeProvider([entry(0)]),
            ),
          ],
          child: MaterialApp(
            home: const GardenScreen(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(disableAnimations: reduceMotion),
              child: child!,
            ),
          ),
        );

    // Only the stem's rotation puts a value in the matrix's shear slot, so
    // this reads the sway without depending on the widget nesting order.
    double angleOfFlower() {
      final transforms = tester.widgetList<Transform>(
        find.descendant(
          of: find.byKey(const ValueKey('garden-flower-flower-0')),
          matching: find.byType(Transform),
        ),
      );
      return transforms.fold<double>(
        0,
        (total, widget) => total + widget.transform.storage[1],
      );
    }

    await tester.pumpWidget(garden(reduceMotion: false));
    // Past the one-shot entrance so only the ambient sway is left moving.
    await tester.pump(const Duration(seconds: 2));
    final first = angleOfFlower();
    await tester.pump(const Duration(milliseconds: 900));
    final second = angleOfFlower();
    expect(
      (second - first).abs(),
      greaterThan(0.0001),
      reason: 'the garden should breathe rather than sit perfectly still',
    );

    await tester.pumpWidget(garden(reduceMotion: true));
    await tester.pumpAndSettle();
    final restA = angleOfFlower();
    await tester.pump(const Duration(seconds: 1));
    expect(
      angleOfFlower(),
      restA,
      reason: 'reduced motion means no ambient movement at all',
    );
  });

  testWidgets('a flower planted on the matched bloom is marked in the garden',
      (tester) async {
    SharedPreferences.setMockInitialValues({'preferred_language': 'english'});
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final matched = GratitudeEntry(
      id: 'matched',
      content: 'My barkada and I laughed all night.',
      flowerType: 'chrysanthemum',
      gardenIndex: 0,
      plotIndex: 0,
      createdAt: DateTime(2026, 8, 2),
    );
    final unmatched = GratitudeEntry(
      id: 'unmatched',
      content: 'My barkada and I laughed all night.',
      flowerType: 'lavender',
      gardenIndex: 0,
      plotIndex: 1,
      createdAt: DateTime(2026, 8, 3),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider<GratitudeProvider>(
            create: (_) => _FakeGratitudeProvider([matched, unmatched]),
          ),
        ],
        child: stillApp(const GardenScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('garden-flower-matched-matched')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('garden-flower-matched-unmatched')),
      findsNothing,
    );
  });
}

class _FakeGratitudeProvider extends GratitudeProvider {
  final List<GratitudeEntry> _fakeEntries;

  _FakeGratitudeProvider(this._fakeEntries);

  @override
  List<GratitudeEntry> get entries => List.unmodifiable(_fakeEntries);

  @override
  int get flowerCount => _fakeEntries.length;

  @override
  int get unlockedGardenCount => GardenLayout.unlockedGardenCount(_fakeEntries);

  @override
  List<GratitudeEntry> entriesForGarden(int gardenIndex) =>
      GardenLayout.entriesForGarden(_fakeEntries, gardenIndex);

  @override
  int flowersInGarden(int gardenIndex) =>
      GardenLayout.flowerCountInGarden(_fakeEntries, gardenIndex);

  @override
  bool isGardenFull(int gardenIndex) =>
      GardenLayout.isFull(_fakeEntries, gardenIndex);
}
