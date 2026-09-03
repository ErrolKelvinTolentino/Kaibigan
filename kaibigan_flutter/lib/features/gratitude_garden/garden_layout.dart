import '../../core/theme/garden_appearance.dart';
import 'gratitude_model.dart';

enum GardenScenePeriod { day, night }

class GardenPlot {
  final double x;
  final double groundY;
  final double perspectiveScale;
  final double rotation;

  const GardenPlot({
    required this.x,
    required this.groundY,
    required this.perspectiveScale,
    this.rotation = 0,
  });
}

class GardenLayout {
  static const int capacity = 10;
  static const double sourceWidth = 1091;
  static const double sourceHeight = 2000;

  /// Coordinates are anchored to the open lawn in the supplied 1091×2000
  /// backgrounds. Ordering from back to front also controls natural z-order.
  static const plots = <GardenPlot>[
    GardenPlot(x: 330, groundY: 790, perspectiveScale: 0.64, rotation: -0.025),
    GardenPlot(x: 545, groundY: 760, perspectiveScale: 0.6, rotation: 0.018),
    GardenPlot(x: 755, groundY: 800, perspectiveScale: 0.66, rotation: 0.03),
    GardenPlot(x: 235, groundY: 1015, perspectiveScale: 0.76, rotation: -0.04),
    GardenPlot(x: 640, groundY: 1030, perspectiveScale: 0.79, rotation: -0.02),
    GardenPlot(x: 835, groundY: 1000, perspectiveScale: 0.76, rotation: 0.035),
    GardenPlot(x: 315, groundY: 1320, perspectiveScale: 0.92, rotation: -0.025),
    GardenPlot(x: 550, groundY: 1370, perspectiveScale: 1, rotation: 0.018),
    GardenPlot(x: 770, groundY: 1310, perspectiveScale: 0.9, rotation: 0.03),
    GardenPlot(x: 545, groundY: 1510, perspectiveScale: 0.94, rotation: -0.015),
  ];

  static GardenScenePeriod periodFor(
    DateTime time, {
    GardenAppearance appearance = GardenAppearance.syncWithTime,
  }) =>
      switch (appearance) {
        GardenAppearance.day => GardenScenePeriod.day,
        GardenAppearance.night => GardenScenePeriod.night,
        GardenAppearance.syncWithTime => time.hour >= 6 && time.hour < 18
            ? GardenScenePeriod.day
            : GardenScenePeriod.night,
      };

  static String backgroundAssetFor(
    DateTime time, {
    GardenAppearance appearance = GardenAppearance.syncWithTime,
  }) =>
      periodFor(time, appearance: appearance) == GardenScenePeriod.day
          ? 'assets/gratitude garden assets/Garden BG Day.png'
          : 'assets/gratitude garden assets/Garden BG Night.png';

  static List<GratitudeEntry> entriesForGarden(
    Iterable<GratitudeEntry> entries,
    int gardenIndex,
  ) =>
      entries.where((entry) => entry.gardenIndex == gardenIndex).toList()
        ..sort((a, b) => a.plotIndex.compareTo(b.plotIndex));

  static int flowerCountInGarden(
    Iterable<GratitudeEntry> entries,
    int gardenIndex,
  ) =>
      entries.where((entry) => entry.gardenIndex == gardenIndex).length;

  static bool isFull(Iterable<GratitudeEntry> entries, int gardenIndex) =>
      flowerCountInGarden(entries, gardenIndex) >= capacity;

  static int firstAvailablePlot(
    Iterable<GratitudeEntry> entries,
    int gardenIndex,
  ) {
    final occupied = entries
        .where((entry) => entry.gardenIndex == gardenIndex)
        .map((entry) => entry.plotIndex)
        .toSet();
    for (var plot = 0; plot < capacity; plot++) {
      if (!occupied.contains(plot)) return plot;
    }
    return -1;
  }

  static int unlockedGardenCount(Iterable<GratitudeEntry> entries) {
    final list = entries.toList();
    final highestAssigned = list.isEmpty
        ? 0
        : list
            .map((entry) => entry.gardenIndex)
            .reduce((a, b) => a > b ? a : b);
    var consecutiveFull = 0;
    while (isFull(list, consecutiveFull)) {
      consecutiveFull++;
    }
    final unlockedByCompletion = consecutiveFull + 1;
    return highestAssigned + 1 > unlockedByCompletion
        ? highestAssigned + 1
        : unlockedByCompletion;
  }

  static int automaticPlantingGarden(Iterable<GratitudeEntry> entries) {
    final list = entries.toList();
    final unlocked = unlockedGardenCount(list);
    for (var garden = unlocked - 1; garden >= 0; garden--) {
      if (!isFull(list, garden)) return garden;
    }
    return unlocked - 1;
  }
}
