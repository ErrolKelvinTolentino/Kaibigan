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
          ? DateTime.parse(map['created_at'])
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

  /// Fetch memories from Supabase database if available
  static Future<void> fetchMemories() async {
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
    if (_memories.isEmpty) return "";

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

  /// Analyzes a journal note to extract key user context automatically
  static Future<void> extractMemoryFromNote(
      String title, String content) async {
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
}
