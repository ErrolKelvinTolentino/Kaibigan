import 'package:flutter/material.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/supabase_service.dart';
import 'journal_model.dart';

class JournalProvider extends ChangeNotifier {
  final List<JournalEntry> _entries = [];
  bool _isLoading = false;
  String _searchQuery = "";

  List<JournalEntry> get entries {
    if (_searchQuery.isEmpty) return List.unmodifiable(_entries);
    return _entries.where((e) =>
      e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      e.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      e.tags.any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase()))
    ).toList();
  }

  List<JournalEntry> get favoriteEntries =>
      _entries.where((e) => e.isFavorite).toList();

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  JournalProvider() {
    _initSampleData();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void _initSampleData() {
    _entries.addAll([
      JournalEntry(
        id: 'sample-1',
        title: 'Medyo mabigat na araw',
        content: 'Sobrang dami ng deadline ngayon, pakiramdam ko parang hindi ako makahinga. Kahit alam kong kaya ko naman, parang ang bigat pa rin sa dibdib.',
        aiResponse: 'Naiintindihan ko. Kapag sabay-sabay dumadating ang mga bagay, madaling maramdaman na sobra na. Kahit alam kong kaya mo naman, parang ang bigat pa rin sa dibdib. Mas yang pressure siguro. Parang kailangan kong tama lagi, kahit sa sarili ko.',
        companionId: 'kai',
        mood: 'stressed',
        tags: ['School', 'Pressure'],
        isFavorite: true,
        reflectionSeedStage: 3,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      JournalEntry(
        id: 'sample-2',
        title: 'Morning reflection & quiet moment',
        content: 'Woke up feeling peaceful today. Spent 10 minutes watering the plants and breathing slowly. I feel ready to handle whatever comes today.',
        aiResponse: 'Such a calm and beautiful start to your morning! Nurturing green leaves and taking time for yourself is a wonderful act of self-love.',
        companionId: 'ann',
        mood: 'calm',
        tags: ['Peaceful', 'Morning'],
        isFavorite: false,
        reflectionSeedStage: 2,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ]);
  }

  Future<void> fetchJournalEntries() async {
    if (!SupabaseService.isInitialized) return;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await SupabaseService.client
          .from('journal_entries')
          .select()
          .order('created_at', ascending: false);

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
    required String companionId,
    required String language,
    String mood = 'calm',
    List<String> tags = const [],
    bool requestAiReflection = true,
  }) async {
    _isLoading = true;
    notifyListeners();

    String? aiReply;
    int seedStage = 1;

    if (requestAiReflection && content.trim().isNotEmpty) {
      aiReply = await AIService.generateCompanionResponse(
        userText: '$title\n$content',
        companionId: companionId,
        language: language,
        mood: mood,
      );
      seedStage = 2; // Grown into sprout upon companion reflection!
    }

    final newEntry = JournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.isEmpty ? 'Untitled Reflection' : title,
      content: content,
      aiResponse: aiReply,
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
        await SupabaseService.client
            .from('journal_entries')
            .insert(newEntry.toMap());
      } catch (e) {
        print("Error saving entry to Supabase: $e");
      }
    }

    _isLoading = false;
    notifyListeners();
    return newEntry;
  }

  Future<void> toggleFavorite(String id) async {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      final updated = _entries[index].copyWith(isFavorite: !_entries[index].isFavorite);
      _entries[index] = updated;
      notifyListeners();

      if (SupabaseService.isInitialized) {
        try {
          await SupabaseService.client
              .from('journal_entries')
              .update({'is_favorite': updated.isFavorite})
              .eq('id', id);
        } catch (e) {
          print("Error updating favorite: $e");
        }
      }
    }
  }

  // Memory Lane: get entry from same period or past
  JournalEntry? getMemoryLaneEntry() {
    if (_entries.isEmpty) return null;
    return _entries.last; // Returns an earlier reflective entry
  }
}
