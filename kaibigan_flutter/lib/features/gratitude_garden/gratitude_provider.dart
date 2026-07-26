import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';
import 'gratitude_model.dart';

class GratitudeProvider extends ChangeNotifier {
  final List<GratitudeEntry> _entries = [];
  bool _isLoading = false;

  List<GratitudeEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  int get flowerCount => _entries.length;

  // Gamification Level & Progression
  int get gardenLevel => (_entries.length ~/ 5) + 1;
  int get flowersInCurrentLevel => _entries.length % 5;
  double get levelProgress => flowersInCurrentLevel / 5.0;
  int get waterDrops => _entries.fold(0, (sum, e) => sum + (e.waterCount * 3)) + 10;

  // Unlocked garden features based on count
  bool get hasButterflies => _entries.length >= 3;
  bool get hasGoldenSun => _entries.length >= 5;
  bool get hasRainbow => _entries.length >= 10;

  GratitudeProvider() {
    _initSampleData();
  }

  void _initSampleData() {
    _entries.addAll([
      GratitudeEntry(
        id: 'g-1',
        content: 'Tumawag si Mama, ang saya ng boses niya.',
        flowerType: 'sunflower',
        growthStage: 3,
        waterCount: 2,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      GratitudeEntry(
        id: 'g-2',
        content: 'Napanood ko ang magandang sunset sa biyahe pauwi.',
        flowerType: 'sampaguita',
        growthStage: 3,
        waterCount: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      GratitudeEntry(
        id: 'g-3',
        content: 'Nakatapos ng mahirap na task sa school with team.',
        flowerType: 'tulip',
        growthStage: 3,
        waterCount: 2,
        createdAt: DateTime.now(),
      ),
      GratitudeEntry(
        id: 'g-4',
        content: 'A warm cup of tsokolate on a rainy afternoon.',
        flowerType: 'orchid',
        growthStage: 3,
        waterCount: 1,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ]);
  }

  Future<void> fetchGratitudeEntries() async {
    if (!SupabaseService.isInitialized) return;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await SupabaseService.client
          .from('gratitude_entries')
          .select()
          .order('created_at', ascending: true);

      final List data = response as List;
      _entries.clear();
      _entries.addAll(data.map((e) => GratitudeEntry.fromMap(e)).toList());
    } catch (e) {
      print("Error fetching gratitude entries: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<GratitudeEntry> addGratitudeEntry(String content, {String flowerType = 'sunflower'}) async {
    _isLoading = true;
    notifyListeners();

    final flowerTypesList = ['sunflower', 'sampaguita', 'tulip', 'orchid', 'rose'];
    final chosenType = flowerType == 'random' 
        ? flowerTypesList[_entries.length % flowerTypesList.length] 
        : flowerType;

    final newEntry = GratitudeEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      flowerType: chosenType,
      growthStage: 3,
      waterCount: 1,
      createdAt: DateTime.now(),
    );

    _entries.add(newEntry);

    if (SupabaseService.isInitialized) {
      try {
        await SupabaseService.client
            .from('gratitude_entries')
            .insert(newEntry.toMap());
      } catch (e) {
        print("Error saving gratitude entry to Supabase: $e");
      }
    }

    _isLoading = false;
    notifyListeners();
    return newEntry;
  }

  void waterFlower(String id) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      _entries[index] = _entries[index].copyWith(waterCount: _entries[index].waterCount + 1);
      notifyListeners();
    }
  }
}
