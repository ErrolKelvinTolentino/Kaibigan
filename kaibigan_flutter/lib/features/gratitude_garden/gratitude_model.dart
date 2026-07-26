import 'package:flutter/material.dart';

class GratitudeEntry {
  final String id;
  final String content;
  final String flowerType; // 'sunflower', 'sampaguita', 'tulip', 'orchid', 'rose'
  final int growthStage; // 1: Seedling, 2: Bud, 3: Full Bloom
  final int waterCount;
  final DateTime createdAt;

  GratitudeEntry({
    required this.id,
    required this.content,
    this.flowerType = 'sunflower',
    this.growthStage = 3,
    this.waterCount = 1,
    required this.createdAt,
  });

  GratitudeEntry copyWith({
    String? id,
    String? content,
    String? flowerType,
    int? growthStage,
    int? waterCount,
    DateTime? createdAt,
  }) {
    return GratitudeEntry(
      id: id ?? this.id,
      content: content ?? this.content,
      flowerType: flowerType ?? this.flowerType,
      growthStage: growthStage ?? this.growthStage,
      waterCount: waterCount ?? this.waterCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'flower_type': flowerType,
      'growth_stage': growthStage,
      'water_count': waterCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GratitudeEntry.fromMap(Map<String, dynamic> map) {
    return GratitudeEntry(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      flowerType: map['flower_type'] ?? 'sunflower',
      growthStage: map['growth_stage'] ?? 3,
      waterCount: map['water_count'] ?? 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  static String getFlowerName(String flowerType) {
    switch (flowerType) {
      case 'sampaguita':
        return 'Sampaguita';
      case 'tulip':
        return 'Tulip';
      case 'orchid':
        return 'Orchid';
      case 'rose':
        return 'Rose';
      case 'sunflower':
      default:
        return 'Sunflower';
    }
  }

  static String getFlowerMeaning(String flowerType) {
    switch (flowerType) {
      case 'sampaguita':
        return 'Purity, Simplicity & Everyday Love';
      case 'tulip':
        return 'Peaceful Heart & Fresh Beginnings';
      case 'orchid':
        return 'Quiet Reflection & Elegance';
      case 'rose':
        return 'Deep Gratitude & Connection';
      case 'sunflower':
      default:
        return 'Joy, Warmth & Hope';
    }
  }

  static Color getFlowerColor(String flowerType) {
    switch (flowerType) {
      case 'sampaguita':
        return const Color(0xFFF7F7F7); // Warm Ivory
      case 'tulip':
        return const Color(0xFFE8AEB7); // Pastel Pink
      case 'orchid':
        return const Color(0xFFD4C1EC); // Lavender Purple
      case 'rose':
        return const Color(0xFFE07A5F); // Warm Coral
      case 'sunflower':
      default:
        return const Color(0xFFF9DC5C); // Golden Sun
    }
  }

  static String getFlowerIcon(String flowerType) {
    switch (flowerType) {
      case 'sampaguita':
        return '🌼';
      case 'tulip':
        return '🌷';
      case 'orchid':
        return '🪻';
      case 'rose':
        return '🌹';
      case 'sunflower':
      default:
        return '🌻';
    }
  }
}
