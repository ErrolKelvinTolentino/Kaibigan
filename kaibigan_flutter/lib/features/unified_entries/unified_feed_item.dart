import 'package:flutter/material.dart';

enum EntryCategory {
  all,
  journal,
  gratitude,
  mood,
  sleep,
  breathing,
  grounding,
  highlight,
  focus,
  reflection,
}

class UnifiedFeedItem {
  const UnifiedFeedItem({
    required this.id,
    required this.title,
    required this.content,
    this.subtitle,
    this.aiInsight,
    required this.category,
    required this.categoryTag,
    required this.categoryColor,
    required this.iconAssetOrEmoji,
    required this.timestamp,
    this.rawData,
  });

  final String id;
  final String title;
  final String content;
  final String? subtitle;
  final String? aiInsight;
  final EntryCategory category;
  final String categoryTag;
  final Color categoryColor;
  final String iconAssetOrEmoji;
  final DateTime timestamp;
  final Object? rawData;
}
