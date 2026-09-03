import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_service.dart';
import '../utils/api_logger.dart';
import '../utils/uuid_helper.dart';

class UserMemory {
  final String id;
  final String category; // 'theme', 'coping_strategy', 'milestone', 'trigger'
  final String summary;
  final int relevanceScore;
  final DateTime createdAt;

  UserMemory({
    required this.id,
    required this.category,
    required this.summary,
    this.relevanceScore = 5,
    required this.createdAt,
  });

  factory UserMemory.fromMap(Map<String, dynamic> map) {
    return UserMemory(
      id: map['id']?.toString() ?? '',
      category: map['memory_category'] ?? 'theme',
      summary: map['memory_summary'] ?? '',
      relevanceScore: map['relevance_score'] ?? 5,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at']).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap({String? userId}) {
    final validId = UuidHelper.isValidUuid(id) ? id : UuidHelper.generateV4();
    final map = <String, dynamic>{
      'id': validId,
      'memory_category': category,
      'memory_summary': summary,
      'relevance_score': relevanceScore,
    };
    if (userId != null && userId.isNotEmpty) {
      map['user_id'] = userId;
    }
    return map;
  }
}

class AIMemoryService {
  // Never seed fabricated memories. Personalization starts empty and only uses
  // broad, user-specific themes learned from that signed-in user's entries.
  static final List<UserMemory> _memories = [];
  static String? _loadedUserId;
  static const String _enabledPreferenceKey = 'ai_memory_enabled';
  static bool _isEnabled = true;
  static bool _preferenceLoaded = false;

  static List<UserMemory> get memories => List.unmodifiable(_memories);
  static bool get isEnabled => _isEnabled;

  /// Loads the user's personalization choice. Existing memories remain
  /// visible when memory is paused, but they are not learned from or sent to
  /// the AI until the user turns it on again.
  static Future<bool> loadPreference() async {
    final preferences = await SharedPreferences.getInstance();
    _isEnabled = preferences.getBool(_enabledPreferenceKey) ?? true;
    _preferenceLoaded = true;
    return _isEnabled;
  }

  static Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    _preferenceLoaded = true;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledPreferenceKey, enabled);
  }

  /// Fetch memories from Supabase database if available
  static Future<void> fetchMemories() async {
    if (!_preferenceLoaded) await loadPreference();
    _memories.clear();
    _loadedUserId = null;
    if (!SupabaseService.isInitialized) return;

    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) return;
      _loadedUserId = userId;
      final response = await SupabaseService.client
          .from('user_memories')
          .select()
          .eq('user_id', userId)
          .order('relevance_score', ascending: false)
          .limit(10);

      final List data = response as List;
      _memories.addAll(data.map((m) => UserMemory.fromMap(m)).toList());
    } catch (e) {
      ApiLogger.logDatabase(
        operation: 'SELECT',
        table: 'user_memories',
        error: e.toString(),
      );
    }
  }

  /// Add a memory summary to the AI memory bank
  static Future<void> addMemory(String summary,
      {String category = 'theme', int relevance = 5}) async {
    if (summary.trim().isEmpty) return;
    if (!_preferenceLoaded) await loadPreference();
    if (!_isEnabled) return;

    final currentUserId = SupabaseService.isInitialized
        ? SupabaseService.client.auth.currentUser?.id
        : null;
    if (_loadedUserId != null && _loadedUserId != currentUserId) {
      _memories.clear();
    }
    _loadedUserId = currentUserId;

    final newMemory = UserMemory(
      id: UuidHelper.generateV4(),
      category: category,
      summary: summary.trim(),
      relevanceScore: relevance,
      createdAt: DateTime.now(),
    );

    _memories.insert(0, newMemory);

    if (SupabaseService.isInitialized) {
      try {
        if (currentUserId == null) return;
        await SupabaseService.client
            .from('user_memories')
            .insert(newMemory.toMap(userId: currentUserId));
      } catch (e) {
        ApiLogger.logDatabase(
          operation: 'INSERT',
          table: 'user_memories',
          error: e.toString(),
        );
      }
    }
  }

  /// Formats memories into a clean context prompt string for the AI Assistant
  static String getMemoryContextPrompt() {
    if (!_isEnabled || _memories.isEmpty) return "";

    if (SupabaseService.isInitialized) {
      final currentUserId = SupabaseService.client.auth.currentUser?.id;
      if (_loadedUserId != currentUserId) {
        _memories.clear();
        _loadedUserId = currentUserId;
        return "";
      }
    }

    final topMemories = _memories.take(4);
    final buffer = StringBuffer();
    buffer.writeln(
        "GENTLE CONTEXT & RECURRING PATTERNS (Use only when directly relevant; never quote verbatim):");
    for (final m in topMemories) {
      buffer.writeln("• ${m.summary}");
    }
    return buffer.toString().trim();
  }

  /// Returns memory only when the current entry shares a meaningful keyword.
  /// This prevents broad old themes from pulling a reply away from what the
  /// user is actually saying now.
  static String getRelevantMemoryContextPrompt(String currentText) {
    if (!_isEnabled || _memories.isEmpty || currentText.trim().isEmpty) {
      return '';
    }

    final currentTokens = _meaningfulTokens(currentText);
    if (currentTokens.isEmpty) return '';
    final relevant = selectRelevantMemories(
      currentText,
      memories: _memories,
    ).take(2);
    if (relevant.isEmpty) return '';

    final buffer = StringBuffer(
      'OPTIONAL RELEVANT CONTEXT (Use only if it clearly helps the latest '
      'message; never force or quote it):',
    );
    for (final memory in relevant) {
      final summary = memory.summary.length <= 240
          ? memory.summary
          : '${memory.summary.substring(0, 237).trimRight()}…';
      buffer.writeln();
      buffer.write('• $summary');
    }
    return buffer.toString();
  }

  /// Ranks memories by concrete overlap first, then user-assigned relevance
  /// and recency. This prevents a merely newer broad theme from displacing a
  /// more useful coping strategy or recurring situation.
  static List<UserMemory> selectRelevantMemories(
    String currentText, {
    required Iterable<UserMemory> memories,
  }) {
    final currentTokens = _meaningfulTokens(currentText);
    if (currentTokens.isEmpty) return const [];
    final now = DateTime.now();
    final scored = <({UserMemory memory, int score})>[];
    for (final memory in memories) {
      final overlap =
          _meaningfulTokens(memory.summary).intersection(currentTokens).length;
      if (overlap == 0) continue;
      final age = now.difference(memory.createdAt).inDays;
      final recencyBonus = age <= 30 ? 2 : (age <= 180 ? 1 : 0);
      scored.add((
        memory: memory,
        score: overlap * 10 + memory.relevanceScore + recencyBonus,
      ));
    }
    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return b.memory.createdAt.compareTo(a.memory.createdAt);
    });
    return scored.map((item) => item.memory).toList(growable: false);
  }

  static Set<String> _meaningfulTokens(String text) {
    const ignored = {
      'about',
      'after',
      'again',
      'being',
      'could',
      'from',
      'have',
      'into',
      'just',
      'more',
      'really',
      'that',
      'their',
      'there',
      'these',
      'this',
      'today',
      'with',
      'your',
      'ako',
      'ang',
      'kung',
      'lang',
      'mga',
      'nang',
      'para',
      'pero',
      'talaga',
      'yung',
    };
    return RegExp(r'[a-zA-ZÀ-ÿ]+')
        .allMatches(text.toLowerCase())
        .map((match) => match.group(0) ?? '')
        .where((token) => token.length >= 5 && !ignored.contains(token))
        .toSet();
  }

  /// Analyzes a journal note to extract key user context automatically
  static Future<void> extractMemoryFromNote(
      String title, String content) async {
    if (!_preferenceLoaded) await loadPreference();
    if (!_isEnabled) return;
    final combined = "$title $content".toLowerCase();

    // 1. Academic & work deadlines
    if (combined.contains('deadline') ||
        combined.contains('exam') ||
        combined.contains('school') ||
        combined.contains('thesis') ||
        combined.contains('capstone')) {
      if (!_memories.any((m) =>
          m.summary.toLowerCase().contains('deadline') ||
          m.summary.toLowerCase().contains('school'))) {
        await addMemory(
            'Currently navigating academic projects and deadline demands.',
            category: 'trigger',
            relevance: 6);
      }
    }

    // 2. Restorative & grounding habits
    if (combined.contains('breathing') ||
        combined.contains('himala') ||
        combined.contains('pahinga') ||
        combined.contains('walk') ||
        combined.contains('lakad') ||
        combined.contains('meditation')) {
      if (!_memories.any((m) =>
          m.summary.toLowerCase().contains('breathing') ||
          m.summary.toLowerCase().contains('walk'))) {
        await addMemory(
            'Values intentional pauses, breathing, and short walks to restore mental clarity.',
            category: 'coping_strategy',
            relevance: 7);
      }
    }

    // 3. Family & social connections
    if (combined.contains('pamilya') ||
        combined.contains('family') ||
        combined.contains('magulang') ||
        combined.contains('kaibigan') ||
        combined.contains('friend')) {
      if (!_memories.any((m) =>
          m.summary.toLowerCase().contains('family') ||
          m.summary.toLowerCase().contains('friends'))) {
        await addMemory(
            'Draws comfort and meaning from close family and authentic friendships.',
            category: 'theme',
            relevance: 6);
      }
    }
  }

  static Future<bool> deleteMemory(String id) async {
    final index = _memories.indexWhere((memory) => memory.id == id);
    if (index == -1) return true;
    final removed = _memories.removeAt(index);

    if (!SupabaseService.isInitialized) return true;
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return true;

    try {
      await SupabaseService.client
          .from('user_memories')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
      return true;
    } catch (error) {
      _memories.insert(index.clamp(0, _memories.length), removed);
      ApiLogger.logDatabase(
        operation: 'DELETE',
        table: 'user_memories',
        error: error.toString(),
      );
      return false;
    }
  }

  static Future<bool> clearMemories() async {
    final previous = List<UserMemory>.from(_memories);
    _memories.clear();

    if (!SupabaseService.isInitialized) return true;
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return true;

    try {
      await SupabaseService.client
          .from('user_memories')
          .delete()
          .eq('user_id', userId);
      return true;
    } catch (error) {
      _memories
        ..clear()
        ..addAll(previous);
      ApiLogger.logDatabase(
        operation: 'DELETE',
        table: 'user_memories',
        error: error.toString(),
      );
      return false;
    }
  }
}
