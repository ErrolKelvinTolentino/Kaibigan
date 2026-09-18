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

  /// Memory is meant to be a handful of things worth remembering, not a
  /// transcript. Past this, the weakest and oldest note is dropped.
  static const int maximumMemories = 12;
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

    final clean = summary.trim();
    // Seeing the same thing again is evidence it matters, not a reason to
    // store a second near-identical note.
    final duplicate = _memories.indexWhere(
      (existing) =>
          existing.category == category && isSameObservation(existing.summary, clean),
    );
    if (duplicate != -1) {
      final existing = _memories[duplicate];
      final strengthened = UserMemory(
        id: existing.id,
        category: existing.category,
        summary: existing.summary,
        relevanceScore: (existing.relevanceScore + 1).clamp(1, 10),
        createdAt: existing.createdAt,
      );
      _memories[duplicate] = strengthened;
      await _persistRelevance(strengthened, currentUserId);
      return;
    }

    final newMemory = UserMemory(
      id: UuidHelper.generateV4(),
      category: category,
      summary: clean,
      relevanceScore: relevance,
      createdAt: DateTime.now(),
    );

    _memories.insert(0, newMemory);
    await _pruneToCapacity(currentUserId);

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

  /// Two notes describe the same thing when most of their meaningful words
  /// overlap. Catches rephrasings without merging genuinely different themes.
  static bool isSameObservation(String a, String b) {
    if (a.trim().toLowerCase() == b.trim().toLowerCase()) return true;
    final first = _meaningfulTokens(a);
    final second = _meaningfulTokens(b);
    if (first.isEmpty || second.isEmpty) return false;
    final shared = first.intersection(second).length;
    return shared / (first.length + second.length - shared) >= 0.6;
  }

  static Future<void> _persistRelevance(
    UserMemory memory,
    String? userId,
  ) async {
    if (!SupabaseService.isInitialized || userId == null) return;
    if (!UuidHelper.isValidUuid(memory.id)) return;
    try {
      await SupabaseService.client
          .from('user_memories')
          .update({'relevance_score': memory.relevanceScore})
          .eq('id', memory.id)
          .eq('user_id', userId);
    } catch (e) {
      ApiLogger.logDatabase(
        operation: 'UPDATE',
        table: 'user_memories',
        error: e.toString(),
      );
    }
  }

  /// Drops the least useful note once the list is full: weakest relevance
  /// first, oldest as the tie-break.
  static Future<void> _pruneToCapacity(String? userId) async {
    while (_memories.length > maximumMemories) {
      var weakest = 0;
      for (var index = 1; index < _memories.length; index++) {
        final candidate = _memories[index];
        final current = _memories[weakest];
        if (candidate.relevanceScore < current.relevanceScore ||
            (candidate.relevanceScore == current.relevanceScore &&
                candidate.createdAt.isBefore(current.createdAt))) {
          weakest = index;
        }
      }
      final removed = _memories.removeAt(weakest);
      if (!SupabaseService.isInitialized || userId == null) continue;
      if (!UuidHelper.isValidUuid(removed.id)) continue;
      try {
        await SupabaseService.client
            .from('user_memories')
            .delete()
            .eq('id', removed.id)
            .eq('user_id', userId);
      } catch (e) {
        ApiLogger.logDatabase(
          operation: 'DELETE',
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

  /// One recognisable life theme and the note stored when it appears.
  ///
  /// Replaces what used to be three hard-coded `if` branches. The point is not
  /// breadth for its own sake: a companion that can say "this is the third week
  /// you have mentioned the thesis" is useful, one that only ever learned
  /// "values intentional pauses" is not.
  static const List<({
    String id,
    List<String> keywords,
    String summary,
    String category,
    int relevance,
  })> observableThemes = [
    (
      id: 'academic_pressure',
      keywords: [
        'deadline', 'exam', 'thesis', 'capstone', 'defense', 'requirements',
        'school', 'semester', 'enrollment', 'grades', 'professor', 'quiz',
        'pasado', 'bagsak', 'pasahan', 'proyekto',
      ],
      summary: 'Carries recurring pressure from school deadlines and academic '
          'requirements.',
      category: 'trigger',
      relevance: 6,
    ),
    (
      id: 'work_pressure',
      keywords: [
        'overtime', 'shift', 'workload', 'manager', 'client', 'quota',
        'resign', 'promotion', 'trabaho', 'boss', 'sahod', 'duty',
      ],
      summary: 'Work demands — hours, workload, or a difficult manager — come '
          'up repeatedly.',
      category: 'trigger',
      relevance: 6,
    ),
    (
      id: 'money_pressure',
      keywords: [
        'budget', 'bills', 'tuition', 'rent', 'utang', 'bayarin', 'gastos',
        'kulang', 'baon', 'allowance', 'sweldo',
      ],
      summary: 'Money and household expenses are an ongoing source of worry.',
      category: 'trigger',
      relevance: 7,
    ),
    (
      id: 'sleep_difficulty',
      keywords: [
        'insomnia', 'puyat', 'hindi makatulog', 'cannot sleep', 'awake',
        'tossing', 'nightmares', 'bangungot', 'walang tulog',
      ],
      summary: 'Struggles with sleep, and notices the difference it makes.',
      category: 'trigger',
      relevance: 7,
    ),
    (
      id: 'restorative_habits',
      keywords: [
        'breathing', 'meditation', 'pahinga', 'walk', 'lakad', 'journal',
        'stretch', 'prayer', 'dasal', 'music', 'kanta', 'hiking',
      ],
      summary: 'Uses deliberate pauses — breathing, walking, music, or prayer — '
          'to steady themselves.',
      category: 'coping_strategy',
      relevance: 7,
    ),
    (
      id: 'close_relationships',
      keywords: [
        'pamilya', 'family', 'magulang', 'nanay', 'tatay', 'kapatid',
        'kaibigan', 'friend', 'barkada', 'tropa', 'partner', 'asawa',
      ],
      summary: 'Draws meaning and steadiness from close family and friendships.',
      category: 'theme',
      relevance: 6,
    ),
    (
      id: 'social_strain',
      keywords: [
        'lonely', 'alone', 'mag-isa', 'nag-away', 'argument', 'fight',
        'ghosted', 'ignored', 'left out', 'walang kausap', 'hiwalay',
      ],
      summary: 'Conflict or loneliness in relationships is a recurring weight.',
      category: 'trigger',
      relevance: 7,
    ),
    (
      id: 'self_criticism',
      keywords: [
        'not good enough', 'failure', 'palpak', 'kasalanan ko', 'stupid',
        'useless', 'walang silbi', 'disappointing', 'ashamed', 'hiya',
      ],
      summary: 'Tends toward harsh self-judgement when something goes wrong.',
      category: 'theme',
      relevance: 8,
    ),
    (
      id: 'health_concern',
      keywords: [
        'sakit', 'sick', 'hospital', 'checkup', 'diagnosis', 'medication',
        'gamot', 'therapy', 'doctor', 'lagnat', 'ospital',
      ],
      summary: 'Health — their own or a loved one\'s — is part of what they are '
          'carrying.',
      category: 'trigger',
      relevance: 7,
    ),
    (
      id: 'caregiving',
      keywords: [
        'taking care of', 'nag-aalaga', 'inaalagaan', 'responsible for',
        'breadwinner', 'panganay', 'my lolo', 'my lola', 'my anak',
      ],
      summary: 'Carries caregiving or provider responsibility for someone else.',
      category: 'theme',
      relevance: 8,
    ),
  ];

  /// Reads a saved entry for recurring life themes.
  ///
  /// This is keyword matching, and it is deliberately conservative: a theme is
  /// only stored when the entry names it plainly, because a wrong memory is
  /// worse than no memory when it is fed back into a reply later.
  static Future<void> extractMemoryFromNote(
    String title,
    String content,
  ) async {
    if (!_preferenceLoaded) await loadPreference();
    if (!_isEnabled) return;
    final combined = '$title $content'.toLowerCase();
    if (combined.trim().length < 25) return;

    for (final theme in observableThemes) {
      if (!theme.keywords.any(combined.contains)) continue;
      await addMemory(
        theme.summary,
        category: theme.category,
        relevance: theme.relevance,
      );
    }
  }

  /// Stores what the companion itself observed during a reply.
  ///
  /// The model has already read the entry properly and returned the emotions
  /// it recognised and the moments that stood out. Reusing that costs nothing
  /// extra and is far more accurate than re-deriving themes from keywords.
  static Future<void> noteCompanionObservation({
    required List<String> detectedEmotions,
    required List<String> standoutMoments,
  }) async {
    if (!_preferenceLoaded) await loadPreference();
    if (!_isEnabled) return;

    // A single reading of one entry is not a pattern. Only emotions that carry
    // real weight are worth remembering at all.
    const weighty = {
      'anxious', 'overwhelmed', 'lonely', 'sad', 'frustrated', 'tired',
      'uncertain', 'proud', 'hopeful', 'grateful', 'relieved',
    };
    final notable =
        detectedEmotions.where(weighty.contains).take(2).toList(growable: false);
    for (final emotion in notable) {
      await addMemory(
        'Has written from a place of feeling $emotion more than once.',
        category: 'theme',
        // Low on purpose: this is a soft signal and should be the first thing
        // dropped when memory fills up.
        relevance: 4,
      );
    }

    for (final moment in standoutMoments.take(1)) {
      final clean = moment.trim();
      if (clean.length < 8 || clean.length > 120) continue;
      await addMemory(
        'Something that mattered to them recently: $clean',
        category: 'milestone',
        relevance: 5,
      );
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
