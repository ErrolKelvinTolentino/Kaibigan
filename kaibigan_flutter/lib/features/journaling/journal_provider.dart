import 'package:flutter/material.dart';
import '../../core/services/ai_memory_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/api_logger.dart';
import '../../core/utils/uuid_helper.dart';
import 'journal_model.dart';

class JournalProvider extends ChangeNotifier {
  final List<JournalEntry> _entries = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedCategoryFilter;
  String? _activeUserId;

  List<JournalEntry> get entries {
    return _entries.where((entry) {
      final matchesSearch = _searchQuery.isEmpty ||
          entry.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          entry.content.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategoryFilter == null ||
          entry.tags.contains(_selectedCategoryFilter);

      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<JournalEntry> get favoriteEntries =>
      _entries.where((e) => e.isFavorite).toList();

  JournalEntry? getMemoryLaneEntry() {
    if (_entries.isEmpty) return null;
    final pastEntries = _entries
        .where((e) => DateTime.now().difference(e.createdAt).inDays >= 1)
        .toList();
    if (pastEntries.isNotEmpty) return pastEntries.first;
    return _entries.first;
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedCategoryFilter => _selectedCategoryFilter;

  JournalProvider() {
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
    if (userId != null) fetchJournalEntries();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _selectedCategoryFilter = category;
    notifyListeners();
  }

  Future<void> fetchJournalEntries() async {
    _errorMessage = null;
    if (!SupabaseService.isInitialized) {
      _errorMessage =
          'Journal sync is unavailable. Check the app configuration and try again.';
      notifyListeners();
      return;
    }
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      await AIMemoryService.fetchMemories();
      final query = SupabaseService.client
          .from('journal_entries')
          .select()
          .eq('user_id', userId);
      final response = await query.order('created_at', ascending: false);

      final List data = response as List;
      _entries.clear();
      _entries.addAll(data.map((e) => JournalEntry.fromMap(e)).toList());

      ApiLogger.logDatabase(
        operation: 'SELECT',
        table: 'journal_entries',
        payload: {'user_id': userId, 'order': 'created_at DESC'},
        result: {
          'count': data.length,
          'sample': data.isNotEmpty ? data.first : null
        },
      );
    } catch (e) {
      _errorMessage =
          'We could not refresh your journal. Your existing entries are still shown.';
      ApiLogger.logDatabase(
        operation: 'SELECT',
        table: 'journal_entries',
        error: e.toString(),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<JournalEntry?> addJournalEntry({
    required String title,
    required String content,
    String? aiReply,
    String? aiResponse,
    required String companionId,
    required String mood,
    String reflectionMode = 'companion',
    List<String> tags = const [],
    int seedStage = 1,
  }) async {
    final cleanTitle = title.trim();
    final cleanContent = content.trim();
    if (cleanTitle.isEmpty && cleanContent.isEmpty) {
      _errorMessage = 'Add a title or a reflection before saving.';
      notifyListeners();
      return null;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final newEntry = JournalEntry(
      id: UuidHelper.generateV4(),
      title: cleanTitle.isEmpty ? 'Untitled Entry' : cleanTitle,
      content: cleanContent,
      aiResponse: aiResponse ?? aiReply,
      companionId: companionId,
      mood: mood,
      reflectionMode: reflectionMode,
      tags: tags,
      isFavorite: false,
      reflectionSeedStage: seedStage,
      createdAt: DateTime.now(),
    );

    var saved = false;
    if (SupabaseService.isInitialized &&
        SupabaseService.client.auth.currentUser != null) {
      try {
        final userId = SupabaseService.client.auth.currentUser!.id;
        final map = newEntry.toMap(userId: userId);
        await SupabaseService.client.from('journal_entries').insert(map);
        saved = true;

        ApiLogger.logDatabase(
          operation: 'INSERT',
          table: 'journal_entries',
          payload: map,
          result: {'status': 'success', 'id': newEntry.id},
        );
      } catch (e) {
        _errorMessage =
            'This entry could not be saved. Please try again before leaving.';
        ApiLogger.logDatabase(
          operation: 'INSERT',
          table: 'journal_entries',
          error: e.toString(),
        );
      }
    } else {
      _errorMessage =
          'This entry could not be saved because journal sync is unavailable.';
    }

    if (saved) {
      _entries.insert(0, newEntry);
      AIMemoryService.extractMemoryFromNote(title, content);
    }

    _isLoading = false;
    notifyListeners();
    return saved ? newEntry : null;
  }

  Future<bool> toggleFavorite(String id) async {
    _errorMessage = null;
    if (!SupabaseService.isInitialized ||
        SupabaseService.client.auth.currentUser == null) {
      _errorMessage =
          'The favorite change could not be saved because sync is unavailable.';
      notifyListeners();
      return false;
    }
    final index = _entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      final updated =
          _entries[index].copyWith(isFavorite: !_entries[index].isFavorite);
      final previous = _entries[index];
      _entries[index] = updated;
      notifyListeners();

      if (SupabaseService.isInitialized && UuidHelper.isValidUuid(id)) {
        try {
          final userId = SupabaseService.client.auth.currentUser!.id;
          await SupabaseService.client
              .from('journal_entries')
              .update({'is_favorite': updated.isFavorite})
              .eq('id', id)
              .eq('user_id', userId)
              .select()
              .single();

          ApiLogger.logDatabase(
            operation: 'UPDATE',
            table: 'journal_entries (favorite)',
            payload: {'id': id, 'is_favorite': updated.isFavorite},
            result: {'status': 'success'},
          );
        } catch (e) {
          _entries[index] = previous;
          _errorMessage = 'The favorite change could not be synced.';
          ApiLogger.logDatabase(
            operation: 'UPDATE',
            table: 'journal_entries (favorite)',
            error: e.toString(),
          );
        }
      }
      notifyListeners();
      return _errorMessage == null;
    }
    _errorMessage = 'This journal entry is no longer available.';
    notifyListeners();
    return false;
  }

  Future<bool> updateJournalEntry(JournalEntry entry) async {
    _errorMessage = null;
    if (entry.title.trim().isEmpty && entry.content.trim().isEmpty) {
      _errorMessage = 'A journal entry cannot be completely empty.';
      notifyListeners();
      return false;
    }
    if (!SupabaseService.isInitialized ||
        SupabaseService.client.auth.currentUser == null) {
      _errorMessage =
          'Your changes could not be saved because sync is unavailable.';
      notifyListeners();
      return false;
    }
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      final previous = _entries[index];
      _entries[index] = entry;
      notifyListeners();

      if (SupabaseService.isInitialized && UuidHelper.isValidUuid(entry.id)) {
        try {
          final userId = SupabaseService.client.auth.currentUser?.id;
          final map = entry.toMap(userId: userId);
          map['updated_at'] = DateTime.now().toUtc().toIso8601String();
          await SupabaseService.client
              .from('journal_entries')
              .update(map)
              .eq('id', entry.id)
              .eq('user_id', userId!)
              .select()
              .single();

          ApiLogger.logDatabase(
            operation: 'UPDATE',
            table: 'journal_entries',
            payload: map,
            result: {'status': 'success', 'id': entry.id},
          );
        } catch (e) {
          _entries[index] = previous;
          _errorMessage = 'Your changes could not be saved. Please try again.';
          ApiLogger.logDatabase(
            operation: 'UPDATE',
            table: 'journal_entries',
            error: e.toString(),
          );
        }
      }

      if (_errorMessage == null) {
        AIMemoryService.extractMemoryFromNote(entry.title, entry.content);
      }
      notifyListeners();
      return _errorMessage == null;
    }
    _errorMessage = 'This journal entry is no longer available.';
    notifyListeners();
    return false;
  }

  Future<bool> deleteJournalEntry(String id) async {
    _errorMessage = null;
    if (!SupabaseService.isInitialized ||
        SupabaseService.client.auth.currentUser == null) {
      _errorMessage =
          'The entry could not be deleted because sync is unavailable.';
      notifyListeners();
      return false;
    }
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) return true;
    final removed = _entries.removeAt(index);
    notifyListeners();

    if (SupabaseService.isInitialized && UuidHelper.isValidUuid(id)) {
      try {
        final userId = SupabaseService.client.auth.currentUser!.id;
        await SupabaseService.client
            .from('journal_entries')
            .delete()
            .eq('id', id)
            .eq('user_id', userId)
            .select()
            .single();

        ApiLogger.logDatabase(
          operation: 'DELETE',
          table: 'journal_entries',
          payload: {'id': id},
          result: {'status': 'success', 'id': id},
        );
      } catch (e) {
        _entries.insert(index.clamp(0, _entries.length), removed);
        _errorMessage = 'The entry could not be deleted. It has been restored.';
        ApiLogger.logDatabase(
          operation: 'DELETE',
          table: 'journal_entries',
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
