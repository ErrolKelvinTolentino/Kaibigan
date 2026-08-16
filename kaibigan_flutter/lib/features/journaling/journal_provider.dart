import 'package:flutter/material.dart';
import '../../core/services/ai_memory_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/uuid_helper.dart';
import 'journal_model.dart';

class JournalProvider extends ChangeNotifier {
  final List<JournalEntry> _entries = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedCategoryFilter;

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
  String get searchQuery => _searchQuery;
  String? get selectedCategoryFilter => _selectedCategoryFilter;

  JournalProvider() {
    _initSampleData();
    fetchJournalEntries();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _selectedCategoryFilter = category;
    notifyListeners();
  }

  void _initSampleData() {
    _entries.addAll([
      JournalEntry(
        id: UuidHelper.generateV4(),
        title: 'Breathe and Reset',
        content:
            'Today was full of tasks, but taking a short walk helped clear my mind.',
        aiResponse:
            'Ang ganda ng desisyon mo na maglakad-lakad kahit sandali. Minsan, akala natin kailangan tuloy-tuloy ang trabaho, pero ang totoo, ang paghinga at pagbagal ang nagbibigay sa atin ng lakas para magpatuloy.\n\n*Anong isang magandang tanawin o pakiramdam ang napansin mo kanina habang naglalakad ka?*',
        companionId: 'kai',
        mood: 'calm',
        tags: ['Daily', 'Reflection'],
        isFavorite: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      JournalEntry(
        id: UuidHelper.generateV4(),
        title: 'Reflections on Gratitude',
        content: 'Grateful for rainy weather and hot soup with family tonight.',
        aiResponse:
            'Ang sarap sa puso ng mga ganitong simpleng sandali—mainit na sabaw sa malamig na gabi kasama ang mga taong mahalaga sa\'yo. Ang mga ganitong payapang alaala ang nagsisilbing kanlungan natin sa gitna ng abalang linggo.\n\n*Paano mo pa kaya maipapadama ang pasasalamat na ito sa kanila bukas?*',
        companionId: 'ann',
        mood: 'happy',
        tags: ['Gratitude'],
        isFavorite: false,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ]);
  }

  Future<void> fetchJournalEntries() async {
    if (!SupabaseService.isInitialized) return;
    _isLoading = true;
    notifyListeners();

    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      var query = SupabaseService.client.from('journal_entries').select();
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      final response = await query.order('created_at', ascending: false);

      final List data = response as List;
      _entries.clear();
      _entries.addAll(data.map((e) => JournalEntry.fromMap(e)).toList());
    } catch (e) {
      print("Error fetching journal entries from Supabase: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<JournalEntry> addJournalEntry({
    required String title,
    required String content,
    String? aiReply,
    String? aiResponse,
    required String companionId,
    required String mood,
    List<String> tags = const [],
    int seedStage = 1,
  }) async {
    _isLoading = true;
    notifyListeners();

    final newEntry = JournalEntry(
      id: UuidHelper.generateV4(),
      title: title,
      content: content,
      aiResponse: aiResponse ?? aiReply,
      companionId: companionId,
      mood: mood,
      tags: tags,
      isFavorite: false,
      reflectionSeedStage: seedStage,
      createdAt: DateTime.now(),
    );

    _entries.insert(0, newEntry);

    if (SupabaseService.isInitialized) {
      try {
        final userId = SupabaseService.client.auth.currentUser?.id;
        await SupabaseService.client
            .from('journal_entries')
            .insert(newEntry.toMap(userId: userId));
      } catch (e) {
        print("Error saving entry to Supabase: $e");
      }
    }

    AIMemoryService.extractMemoryFromNote(title, content);

    _isLoading = false;
    notifyListeners();
    return newEntry;
  }

  Future<void> toggleFavorite(String id) async {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      final updated =
          _entries[index].copyWith(isFavorite: !_entries[index].isFavorite);
      _entries[index] = updated;
      notifyListeners();

      if (SupabaseService.isInitialized && UuidHelper.isValidUuid(id)) {
        try {
          await SupabaseService.client
              .from('journal_entries')
              .update({'is_favorite': updated.isFavorite}).eq('id', id);
        } catch (e) {
          print("Error updating favorite status: $e");
        }
      }
    }
  }

  Future<void> updateJournalEntry(JournalEntry entry) async {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _entries[index] = entry;
      notifyListeners();

      if (SupabaseService.isInitialized && UuidHelper.isValidUuid(entry.id)) {
        try {
          final userId = SupabaseService.client.auth.currentUser?.id;
          await SupabaseService.client
              .from('journal_entries')
              .update(entry.toMap(userId: userId))
              .eq('id', entry.id);
        } catch (e) {
          print("Error updating entry in Supabase: $e");
        }
      }

      AIMemoryService.extractMemoryFromNote(entry.title, entry.content);
    }
  }

  Future<void> deleteJournalEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();

    if (SupabaseService.isInitialized && UuidHelper.isValidUuid(id)) {
      try {
        await SupabaseService.client
            .from('journal_entries')
            .delete()
            .eq('id', id);
      } catch (e) {
        print("Error deleting entry from Supabase: $e");
      }
    }
  }
}
