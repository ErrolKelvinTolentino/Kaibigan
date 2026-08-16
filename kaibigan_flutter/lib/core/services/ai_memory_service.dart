import 'supabase_service.dart';
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
  static final List<UserMemory> _memories = [
    UserMemory(
      id: UuidHelper.generateV4(),
      category: 'coping_strategy',
      summary: 'Responds well to morning quiet time, breathing pauses, and gardening.',
      relevanceScore: 8,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    UserMemory(
      id: UuidHelper.generateV4(),
      category: 'trigger',
      summary: 'Academic deadlines and multiple overlapping tasks cause feeling overwhelmed.',
      relevanceScore: 7,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  /// Fetch memories from Supabase database if available
  static Future<void> fetchMemories() async {
    if (!SupabaseService.isInitialized) return;

    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      var query = SupabaseService.client.from('user_memories').select();
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      final response = await query
          .order('relevance_score', ascending: false)
          .limit(10);

      final List data = response as List;
      if (data.isNotEmpty) {
        _memories.clear();
        _memories.addAll(data.map((m) => UserMemory.fromMap(m)).toList());
      }
    } catch (e) {
      print("Error fetching AI memories: $e");
    }
  }

  /// Add a memory summary to the AI memory bank
  static Future<void> addMemory(String summary, {String category = 'theme', int relevance = 5}) async {
    if (summary.trim().isEmpty) return;

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
        final userId = SupabaseService.client.auth.currentUser?.id;
        await SupabaseService.client.from('user_memories').insert(newMemory.toMap(userId: userId));
      } catch (e) {
        print("Error saving AI memory to Supabase: $e");
      }
    }
  }

  /// Formats memories into a clean context prompt string for the AI Assistant
  static String getMemoryContextPrompt() {
    if (_memories.isEmpty) return "";

    final topMemories = _memories.take(5);
    final buffer = StringBuffer();
    buffer.writeln("USER MEMORY CONTEXT & RECURRING PATTERNS:");
    for (final m in topMemories) {
      buffer.writeln("• ${m.summary}");
    }
    return buffer.toString().trim();
  }

  /// Analyzes a journal note to extract key user context automatically
  static Future<void> extractMemoryFromNote(String title, String content) async {
    final combined = "$title $content".toLowerCase();
    if (combined.contains('deadline') || combined.contains('exam') || combined.contains('school')) {
      if (!_memories.any((m) => m.summary.contains('deadline') || m.summary.contains('school'))) {
        await addMemory('User is currently balancing school projects and deadline pressure.', category: 'trigger', relevance: 6);
      }
    }
    if (combined.contains('breathing') || combined.contains('himala') || combined.contains('pahinga')) {
      if (!_memories.any((m) => m.summary.contains('breathing') || m.summary.contains('pahinga'))) {
        await addMemory('Values quiet breathing breaks to restore focus.', category: 'coping_strategy', relevance: 7);
      }
    }
  }
}
