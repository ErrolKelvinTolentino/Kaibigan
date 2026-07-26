class JournalEntry {
  final String id;
  final String title;
  final String content;
  final String? aiResponse;
  final String companionId;
  final String mood;
  final List<String> tags;
  final bool isFavorite;
  final int reflectionSeedStage; // 1: Seed, 2: Sprout, 3: Bloom
  final DateTime createdAt;

  JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    this.aiResponse,
    required this.companionId,
    this.mood = 'calm',
    this.tags = const [],
    this.isFavorite = false,
    this.reflectionSeedStage = 1,
    required this.createdAt,
  });

  JournalEntry copyWith({
    String? id,
    String? title,
    String? content,
    String? aiResponse,
    String? companionId,
    String? mood,
    List<String>? tags,
    bool? isFavorite,
    int? reflectionSeedStage,
    DateTime? createdAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      aiResponse: aiResponse ?? this.aiResponse,
      companionId: companionId ?? this.companionId,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      reflectionSeedStage: reflectionSeedStage ?? this.reflectionSeedStage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'ai_response': aiResponse,
      'companion_id': companionId,
      'mood': mood,
      'tags': tags,
      'is_favorite': isFavorite,
      'reflection_seed_stage': reflectionSeedStage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      aiResponse: map['ai_response'],
      companionId: map['companion_id'] ?? 'kai',
      mood: map['mood'] ?? 'calm',
      tags: List<String>.from(map['tags'] ?? []),
      isFavorite: map['is_favorite'] ?? false,
      reflectionSeedStage: map['reflection_seed_stage'] ?? 1,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
    );
  }
}
