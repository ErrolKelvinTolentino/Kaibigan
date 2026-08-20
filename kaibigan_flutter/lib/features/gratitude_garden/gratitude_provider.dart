import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/api_logger.dart';
import '../../core/utils/uuid_helper.dart';
import 'gratitude_model.dart';

class GratitudeProvider extends ChangeNotifier {
  final List<GratitudeEntry> _entries = [];
  final List<GratitudeEntry> _communityEntries = [];
  bool _isLoading = false;
  String _activeSoundscape = 'lofi_guitar'; // 'lofi_guitar', 'rain_nipa', 'night_crickets', 'ocean_breeze', 'off'

  List<GratitudeEntry> get entries => List.unmodifiable(_entries);
  List<GratitudeEntry> get communityEntries => List.unmodifiable(_communityEntries);
  bool get isLoading => _isLoading;
  int get flowerCount => _entries.length;
  String get activeSoundscape => _activeSoundscape;

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
    _initCommunityMeadow();
    fetchGratitudeEntries();
  }

  void setSoundscape(String soundscape) {
    _activeSoundscape = soundscape;
    notifyListeners();
  }

  void _initSampleData() {
    _entries.addAll([
      GratitudeEntry(
        id: UuidHelper.generateV4(),
        content: 'Tumawag si Mama, ang saya ng boses niya.',
        flowerType: 'sunflower',
        growthStage: 3,
        waterCount: 2,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      GratitudeEntry(
        id: UuidHelper.generateV4(),
        content: 'Napanood ko ang magandang sunset sa biyahe pauwi.',
        flowerType: 'sampaguita',
        growthStage: 3,
        waterCount: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      GratitudeEntry(
        id: UuidHelper.generateV4(),
        content: 'Nakatapos ng mahirap na task sa school with team.',
        flowerType: 'tulip',
        growthStage: 3,
        waterCount: 2,
        createdAt: DateTime.now(),
      ),
      GratitudeEntry(
        id: UuidHelper.generateV4(),
        content: 'A warm cup of tsokolate on a rainy afternoon.',
        flowerType: 'orchid',
        growthStage: 3,
        waterCount: 1,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ]);
  }

  void _initCommunityMeadow() {
    _communityEntries.addAll([
      GratitudeEntry(
        id: UuidHelper.generateV4(),
        content: 'Nakatulong ako sa matanda na tumawid sa kalsada ngayong umaga.',
        flowerType: 'sampaguita',
        growthStage: 3,
        waterCount: 12,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      GratitudeEntry(
        id: UuidHelper.generateV4(),
        content: 'Passed my major exam after studying hard all week! 📚🎉',
        flowerType: 'sunflower',
        growthStage: 3,
        waterCount: 28,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      GratitudeEntry(
        id: UuidHelper.generateV4(),
        content: 'Grateful for rainy weather and hot sinigang with family.',
        flowerType: 'rose',
        growthStage: 3,
        waterCount: 45,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ]);
  }

  Future<void> fetchGratitudeEntries() async {
    if (!SupabaseService.isInitialized) return;
    _isLoading = true;
    notifyListeners();

    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      var query = SupabaseService.client.from('gratitude_entries').select();
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      final response = await query.order('created_at', ascending: true);

      final List data = response as List;
      _entries.clear();
      _entries.addAll(data.map((e) => GratitudeEntry.fromMap(e)).toList());

      ApiLogger.logDatabase(
        operation: 'SELECT',
        table: 'gratitude_entries',
        payload: {'user_id': userId, 'order': 'created_at ASC'},
        result: {'count': data.length, 'sample': data.isNotEmpty ? data.first : null},
      );
    } catch (e) {
      ApiLogger.logDatabase(
        operation: 'SELECT',
        table: 'gratitude_entries',
        error: e.toString(),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<GratitudeEntry> addGratitudeEntry(String content, {String flowerType = 'sunflower', bool shareToCommunity = false}) async {
    _isLoading = true;
    notifyListeners();

    final flowerTypesList = ['sunflower', 'sampaguita', 'tulip', 'orchid', 'rose'];
    final chosenType = flowerType == 'random' 
        ? flowerTypesList[_entries.length % flowerTypesList.length] 
        : flowerType;

    final newEntry = GratitudeEntry(
      id: UuidHelper.generateV4(),
      content: content,
      flowerType: chosenType,
      growthStage: 3,
      waterCount: 1,
      createdAt: DateTime.now(),
    );

    _entries.add(newEntry);

    if (shareToCommunity) {
      _communityEntries.insert(0, newEntry);
    }

    if (SupabaseService.isInitialized) {
      try {
        final userId = SupabaseService.client.auth.currentUser?.id;
        final map = newEntry.toMap(userId: userId);
        await SupabaseService.client.from('gratitude_entries').insert(map);

        ApiLogger.logDatabase(
          operation: 'INSERT',
          table: 'gratitude_entries',
          payload: map,
          result: {'status': 'success', 'id': newEntry.id},
        );
      } catch (e) {
        ApiLogger.logDatabase(
          operation: 'INSERT',
          table: 'gratitude_entries',
          error: e.toString(),
        );
      }
    }

    _isLoading = false;
    notifyListeners();
    return newEntry;
  }

  Future<void> waterFlower(String id) async {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      final updated = _entries[index].copyWith(waterCount: _entries[index].waterCount + 1);
      _entries[index] = updated;
      notifyListeners();

      if (SupabaseService.isInitialized && UuidHelper.isValidUuid(id)) {
        try {
          await SupabaseService.client
              .from('gratitude_entries')
              .update({'water_count': updated.waterCount})
              .eq('id', id);

          ApiLogger.logDatabase(
            operation: 'UPDATE',
            table: 'gratitude_entries (water)',
            payload: {'id': id, 'water_count': updated.waterCount},
            result: {'status': 'success'},
          );
        } catch (e) {
          ApiLogger.logDatabase(
            operation: 'UPDATE',
            table: 'gratitude_entries (water)',
            error: e.toString(),
          );
        }
      }
    }
  }

  Future<void> updateGratitudeEntry(String id, String newContent) async {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      final updated = _entries[index].copyWith(content: newContent);
      _entries[index] = updated;
      notifyListeners();

      if (SupabaseService.isInitialized && UuidHelper.isValidUuid(id)) {
        try {
          await SupabaseService.client
              .from('gratitude_entries')
              .update({'content': newContent})
              .eq('id', id);

          ApiLogger.logDatabase(
            operation: 'UPDATE',
            table: 'gratitude_entries',
            payload: {'id': id, 'content': newContent},
            result: {'status': 'success'},
          );
        } catch (e) {
          ApiLogger.logDatabase(
            operation: 'UPDATE',
            table: 'gratitude_entries',
            error: e.toString(),
          );
        }
      }
    }
  }

  Future<void> deleteGratitudeEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();

    if (SupabaseService.isInitialized && UuidHelper.isValidUuid(id)) {
      try {
        await SupabaseService.client
            .from('gratitude_entries')
            .delete()
            .eq('id', id);

        ApiLogger.logDatabase(
          operation: 'DELETE',
          table: 'gratitude_entries',
          payload: {'id': id},
          result: {'status': 'success', 'id': id},
        );
      } catch (e) {
        ApiLogger.logDatabase(
          operation: 'DELETE',
          table: 'gratitude_entries',
          error: e.toString(),
        );
      }
    }
  }
}
