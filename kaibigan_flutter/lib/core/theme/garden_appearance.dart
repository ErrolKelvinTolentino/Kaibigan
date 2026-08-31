enum GardenAppearance {
  syncWithTime,
  day,
  night;

  static GardenAppearance fromStorage(String? value) => switch (value) {
        'day' => GardenAppearance.day,
        'night' => GardenAppearance.night,
        _ => GardenAppearance.syncWithTime,
      };
}
