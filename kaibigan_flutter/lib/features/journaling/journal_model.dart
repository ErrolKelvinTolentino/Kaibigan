import 'dart:convert';

import '../../core/utils/uuid_helper.dart';

class JournalConversationTurn {
  final String userText;
  final String? aiResponse;
  final String? companionId;

  const JournalConversationTurn({
    required this.userText,
    this.aiResponse,
    this.companionId,
  });

  Map<String, dynamic> toJson() => {
        'user': userText,
        'assistant': aiResponse,
        'companion': companionId,
      };

  factory JournalConversationTurn.fromJson(Map<String, dynamic> json) {
    return JournalConversationTurn(
      userText: json['user'] as String? ?? '',
      aiResponse: json['assistant'] as String?,
      companionId: json['companion'] as String?,
    );
  }
}

class JournalEntry {
  static const String warmUntitledTitle = 'A moment in your life';
  static const String _conversationPrefix = '__KAIBIGAN_TURNS_V1__';
  final String id;
  final String title;
  final String content;
  final String? aiResponse;
  final String companionId;
  final String mood;
  final String
      reflectionMode; // 'auto' for new entries; legacy explicit modes still load
  final List<String> tags;
  final bool isFavorite;
  final int reflectionSeedStage; // 1: Seed, 2: Sprout, 3: Bloom
  final DateTime createdAt;
  final List<JournalConversationTurn> conversationTurns;

  JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    this.aiResponse,
    required this.companionId,
    this.mood = '',
    this.reflectionMode = 'auto',
    this.tags = const [],
    this.isFavorite = false,
    this.reflectionSeedStage = 1,
    required this.createdAt,
    this.conversationTurns = const [],
  });

  JournalEntry copyWith({
    String? id,
    String? title,
    String? content,
    String? aiResponse,
    String? companionId,
    String? mood,
    String? reflectionMode,
    List<String>? tags,
    bool? isFavorite,
    int? reflectionSeedStage,
    DateTime? createdAt,
    List<JournalConversationTurn>? conversationTurns,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      aiResponse: aiResponse ?? this.aiResponse,
      companionId: companionId ?? this.companionId,
      mood: mood ?? this.mood,
      reflectionMode: reflectionMode ?? this.reflectionMode,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      reflectionSeedStage: reflectionSeedStage ?? this.reflectionSeedStage,
      createdAt: createdAt ?? this.createdAt,
      conversationTurns: conversationTurns ?? this.conversationTurns,
    );
  }

  Map<String, dynamic> toMap({String? userId}) {
    final validId = UuidHelper.isValidUuid(id) ? id : UuidHelper.generateV4();
    final map = <String, dynamic>{
      'id': validId,
      'title': title,
      'content': content,
      'ai_response': conversationTurns.isEmpty
          ? aiResponse
          : '$_conversationPrefix${jsonEncode(
              conversationTurns.map((turn) => turn.toJson()).toList(),
            )}',
      'companion_id': companionId,
      'mood': mood,
      'reflection_mode': reflectionMode,
      'tags': tags,
      'is_favorite': isFavorite,
      'reflection_seed_stage': reflectionSeedStage,
      'created_at': createdAt.toIso8601String(),
    };
    if (userId != null && userId.isNotEmpty) {
      map['user_id'] = userId;
    }
    return map;
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    final storedResponse = map['ai_response'] as String?;
    final decodedTurns = _decodeConversation(storedResponse);
    return JournalEntry(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      aiResponse:
          decodedTurns.isEmpty ? storedResponse : _joinResponses(decodedTurns),
      companionId: map['companion_id'] ?? 'kai',
      mood: map['mood'] ?? '',
      reflectionMode: map['reflection_mode'] ?? 'auto',
      tags: List<String>.from(map['tags'] ?? []),
      isFavorite: map['is_favorite'] ?? false,
      reflectionSeedStage: map['reflection_seed_stage'] ?? 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at']).toLocal()
          : DateTime.now(),
      conversationTurns: decodedTurns,
    );
  }

  /// Returns true turn-by-turn data for new records and conservatively
  /// reconstructs older records only when user/reply segment counts match.
  List<JournalConversationTurn> get turnsForDisplay {
    if (conversationTurns.isNotEmpty) return conversationTurns;
    final cleanContent = content.trim();
    final cleanResponse = aiResponse?.trim() ?? '';
    if (cleanContent.isEmpty) return const [];
    if (cleanResponse.isEmpty) {
      return [JournalConversationTurn(userText: cleanContent)];
    }

    final responses = cleanResponse
        .split(RegExp(r'\n\s*\n---\n\s*\n'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    final messages = cleanContent
        .split(RegExp(r'\n\s*\n'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);

    if (responses.length > 1 && messages.length == responses.length) {
      return List.generate(
        messages.length,
        (index) => JournalConversationTurn(
          userText: messages[index],
          aiResponse: responses[index],
          companionId: companionId,
        ),
        growable: false,
      );
    }
    return [
      JournalConversationTurn(
        userText: cleanContent,
        aiResponse: cleanResponse,
        companionId: companionId,
      ),
    ];
  }

  static List<JournalConversationTurn> _decodeConversation(String? stored) {
    if (stored == null || !stored.startsWith(_conversationPrefix)) {
      return const [];
    }
    try {
      final value = jsonDecode(stored.substring(_conversationPrefix.length));
      if (value is! List) return const [];
      return value
          .whereType<Map<String, dynamic>>()
          .map(JournalConversationTurn.fromJson)
          .where((turn) =>
              turn.userText.trim().isNotEmpty ||
              (turn.aiResponse?.trim().isNotEmpty ?? false))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  static String? _joinResponses(List<JournalConversationTurn> turns) {
    final responses = turns
        .map((turn) => turn.aiResponse?.trim() ?? '')
        .where((response) => response.isNotEmpty)
        .join('\n\n---\n\n');
    return responses.isEmpty ? null : responses;
  }

  bool get hasGeneratedTitle {
    final normalized = title.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized == 'untitled' ||
        normalized == 'untitled entry' ||
        normalized == 'untitled reflection' ||
        normalized == 'walang pamagat';
  }

  String displayTitle(String language) {
    if (!hasGeneratedTitle) return title.trim();
    return language == 'filipino'
        ? 'Isang sandali sa iyong buhay'
        : warmUntitledTitle;
  }
}
