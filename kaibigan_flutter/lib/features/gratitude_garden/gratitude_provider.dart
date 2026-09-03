import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/api_logger.dart';
import '../../core/utils/uuid_helper.dart';
import 'garden_layout.dart';
import 'gratitude_model.dart';

class GratitudeProvider extends ChangeNotifier {
  final List<GratitudeEntry> _entries = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _activeUserId;

  List<GratitudeEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get flowerCount => _entries.length;

  // Gamification Level & Progression
  int get gardenLevel => GardenLayout.automaticPlantingGarden(_entries) + 1;
  int get flowersInCurrentLevel =>
      GardenLayout.flowerCountInGarden(_entries, gardenLevel - 1);
  double get levelProgress => flowersInCurrentLevel / GardenLayout.capacity;
  int get unlockedGardenCount => GardenLayout.unlockedGardenCount(_entries);
  List<GratitudeEntry> entriesForGarden(int gardenIndex) =>
      GardenLayout.entriesForGarden(_entries, gardenIndex);
  int flowersInGarden(int gardenIndex) =>
      GardenLayout.flowerCountInGarden(_entries, gardenIndex);
  bool isGardenFull(int gardenIndex) =>
      GardenLayout.isFull(_entries, gardenIndex);

  // Unlocked garden features based on count
  bool get hasButterflies => _entries.length >= 3;
  bool get hasGoldenSun => _entries.length >= 5;
  bool get hasRainbow => _entries.length >= 10;

  GratitudeProvider() {
    syncForCurrentUser();
  }

  void syncForCurrentUser() {
    final userId = SupabaseService.isInitialized
        ? SupabaseService.client.auth.currentUser?.id
        : null;
    if (userId == _activeUserId) return;
    _activeUserId = userId;
    _entries.clear();
    _errorMessage = null;
    notifyListeners();
    if (userId != null) fetchGratitudeEntries();
  }

  Future<void> fetchGratitudeEntries() async {
    _errorMessage = null;
    if (!SupabaseService.isInitialized) {
      _errorMessage =
          'Garden sync is unavailable. Check the app configuration and try again.';
      notifyListeners();
      return;
    }
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final query = SupabaseService.client
          .from('gratitude_entries')
          .select()
          .eq('user_id', userId);
      final response = await query.order('created_at', ascending: true);

      final List data = response as List;
      _entries.clear();
      _entries.addAll(data.map((e) => GratitudeEntry.fromMap(e)).toList());

      ApiLogger.logDatabase(
        operation: 'SELECT',
        table: 'gratitude_entries',
        payload: {'user_id': userId, 'order': 'created_at ASC'},
        result: {
          'count': data.length,
          'sample': data.isNotEmpty ? data.first : null
        },
      );
    } catch (e) {
      _errorMessage =
          'We could not refresh your gratitude garden. Please try again.';
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

  Future<GratitudeEntry?> addGratitudeEntry(
    String content, {
    String flowerType = 'anemone',
    bool shareToCommunity = false,
    int? gardenIndex,
  }) async {
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) {
      _errorMessage = 'Write one thing you are grateful for before planting.';
      notifyListeners();
      return null;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final targetGarden =
        gardenIndex ?? GardenLayout.automaticPlantingGarden(_entries);
    final unlocked = GardenLayout.unlockedGardenCount(_entries);
    if (targetGarden < 0 || targetGarden >= unlocked) {
      _errorMessage = 'Fill the current garden before opening this one.';
      notifyListeners();
      return null;
    }
    final plotIndex = GardenLayout.firstAvailablePlot(_entries, targetGarden);
    if (plotIndex == -1) {
      _errorMessage = 'This garden is full. Open the newly unlocked garden.';
      notifyListeners();
      return null;
    }

    final flowerTypesList = GratitudeEntry.availableFlowerTypes;
    final chosenType = flowerType == 'random'
        ? flowerTypesList[_entries.length % flowerTypesList.length]
        : flowerType;

    final newEntry = GratitudeEntry(
      id: UuidHelper.generateV4(),
      content: cleanContent,
      flowerType: chosenType,
      gardenIndex: targetGarden,
      plotIndex: plotIndex,
      createdAt: DateTime.now(),
    );

    var saved = false;
    if (SupabaseService.isInitialized &&
        SupabaseService.client.auth.currentUser != null) {
      try {
        final userId = SupabaseService.client.auth.currentUser!.id;
        final map = newEntry.toMap(userId: userId);
        await SupabaseService.client.from('gratitude_entries').insert(map);
        saved = true;

        ApiLogger.logDatabase(
          operation: 'INSERT',
          table: 'gratitude_entries',
          payload: map,
          result: {'status': 'success', 'id': newEntry.id},
        );
      } catch (e) {
        _errorMessage =
            'Your gratitude could not be planted. Please try again.';
        ApiLogger.logDatabase(
          operation: 'INSERT',
          table: 'gratitude_entries',
          error: e.toString(),
        );
      }
    } else {
      _errorMessage =
          'Your gratitude could not be planted because sync is unavailable.';
    }

    if (saved) _entries.add(newEntry);

    _isLoading = false;
    notifyListeners();
    return saved ? newEntry : null;
  }

  Future<bool> updateGratitudeEntry(String id, String newContent) async {
    _errorMessage = null;
    final cleanContent = newContent.trim();
    if (cleanContent.isEmpty) {
      _errorMessage = 'A gratitude note cannot be empty.';
      notifyListeners();
      return false;
    }
    if (!SupabaseService.isInitialized ||
        SupabaseService.client.auth.currentUser == null) {
      _errorMessage =
          'This gratitude could not be updated because sync is unavailable.';
      notifyListeners();
      return false;
    }
    final index = _entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      final previous = _entries[index];
      final updated = _entries[index].copyWith(content: cleanContent);
      _entries[index] = updated;
      notifyListeners();

      if (SupabaseService.isInitialized && UuidHelper.isValidUuid(id)) {
        try {
          final userId = SupabaseService.client.auth.currentUser!.id;
          await SupabaseService.client
              .from('gratitude_entries')
              .update({'content': cleanContent})
              .eq('id', id)
              .eq('user_id', userId)
              .select()
              .single();

          ApiLogger.logDatabase(
            operation: 'UPDATE',
            table: 'gratitude_entries',
            payload: {'id': id, 'content': cleanContent},
            result: {'status': 'success'},
          );
        } catch (e) {
          _entries[index] = previous;
          _errorMessage =
              'This gratitude could not be updated. Please try again.';
          ApiLogger.logDatabase(
            operation: 'UPDATE',
            table: 'gratitude_entries',
            error: e.toString(),
          );
        }
      }
      notifyListeners();
      return _errorMessage == null;
    }
    _errorMessage = 'This gratitude entry is no longer available.';
    notifyListeners();
    return false;
  }

  Future<bool> deleteGratitudeEntry(String id) async {
    _errorMessage = null;
    if (!SupabaseService.isInitialized ||
        SupabaseService.client.auth.currentUser == null) {
      _errorMessage =
          'This flower could not be deleted because sync is unavailable.';
      notifyListeners();
      return false;
    }
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index == -1) return true;
    final removed = _entries.removeAt(index);
    notifyListeners();

    if (SupabaseService.isInitialized && UuidHelper.isValidUuid(id)) {
      try {
        final userId = SupabaseService.client.auth.currentUser!.id;
        await SupabaseService.client
            .from('gratitude_entries')
            .delete()
            .eq('id', id)
            .eq('user_id', userId)
            .select()
            .single();

        ApiLogger.logDatabase(
          operation: 'DELETE',
          table: 'gratitude_entries',
          payload: {'id': id},
          result: {'status': 'success', 'id': id},
        );
      } catch (e) {
        _entries.insert(index.clamp(0, _entries.length), removed);
        _errorMessage =
            'This flower could not be deleted. It has been restored.';
        ApiLogger.logDatabase(
          operation: 'DELETE',
          table: 'gratitude_entries',
          error: e.toString(),
        );
        notifyListeners();
        return false;
      }
    }
    notifyListeners();
    return true;
  }
}
