import 'package:flutter/material.dart';
import '../../core/utils/uuid_helper.dart';

class GratitudeEntry {
  final String id;
  final String content;
  final String
      flowerType; // 'sunflower', 'sampaguita', 'tulip', 'orchid', 'rose'
  final int waterCount;
  final int gardenIndex;
  final int plotIndex;
  final DateTime createdAt;

  GratitudeEntry({
    required this.id,
    required this.content,
    this.flowerType = 'sunflower',
    this.waterCount = 1,
    this.gardenIndex = 0,
    this.plotIndex = 0,
    required this.createdAt,
  });

  GratitudeEntry copyWith({
    String? id,
    String? content,
    String? flowerType,
    int? waterCount,
    int? gardenIndex,
    int? plotIndex,
    DateTime? createdAt,
  }) {
    return GratitudeEntry(
      id: id ?? this.id,
      content: content ?? this.content,
      flowerType: flowerType ?? this.flowerType,
      waterCount: waterCount ?? this.waterCount,
      gardenIndex: gardenIndex ?? this.gardenIndex,
      plotIndex: plotIndex ?? this.plotIndex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap({String? userId}) {
    final validId = UuidHelper.isValidUuid(id) ? id : UuidHelper.generateV4();
    final map = <String, dynamic>{
      'id': validId,
      'content': content,
      'flower_type': flowerType,
      'water_count': waterCount,
      'garden_index': gardenIndex,
      'plot_index': plotIndex,
      'created_at': createdAt.toIso8601String(),
    };
    if (userId != null && userId.isNotEmpty) {
      map['user_id'] = userId;
    }
    return map;
  }

  factory GratitudeEntry.fromMap(Map<String, dynamic> map) {
    return GratitudeEntry(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      flowerType: map['flower_type'] ?? 'sunflower',
      waterCount: map['water_count'] ?? 1,
      gardenIndex: map['garden_index'] ?? 0,
      plotIndex: map['plot_index'] ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at']).toLocal()
          : DateTime.now(),
    );
  }

  static String getFlowerName(String flowerType) {
    switch (flowerType) {
      case 'anemone':
        return 'Anemone';
      case 'bluebell':
        return 'Bluebell';
      case 'chrysanthemum':
        return 'Chrysanthemum';
      case 'geranium':
        return 'Geranium';
      case 'lavender':
        return 'Lavender';
      case 'lily':
        return 'Lily';
      case 'purple_aster':
        return 'Purple Aster';
      case 'ranunculus':
        return 'Ranunculus';
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
      case 'anemone':
        return 'Hope & Gentle Anticipation';
      case 'bluebell':
        return 'Humility & Lasting Care';
      case 'chrysanthemum':
        return 'Joy & Loyal Friendship';
      case 'geranium':
        return 'Comfort & True Connection';
      case 'lavender':
        return 'Calm & Quiet Devotion';
      case 'lily':
        return 'Renewal & Tender Hope';
      case 'purple_aster':
        return 'Patience & Gentle Wisdom';
      case 'ranunculus':
        return 'Warmth & Radiant Appreciation';
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
      case 'anemone':
        return const Color(0xFF6671C9);
      case 'bluebell':
        return const Color(0xFF87B6D9);
      case 'chrysanthemum':
        return const Color(0xFFE9B85D);
      case 'geranium':
        return const Color(0xFFE78891);
      case 'lavender':
        return const Color(0xFF9A83C7);
      case 'lily':
        return const Color(0xFFF1B6C3);
      case 'purple_aster':
        return const Color(0xFF8C75BF);
      case 'ranunculus':
        return const Color(0xFFF0A574);
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

  static IconData getFlowerMaterialIcon(String flowerType) {
    switch (flowerType) {
      case 'sampaguita':
        return Icons.filter_vintage;
      case 'tulip':
        return Icons.local_florist;
      case 'orchid':
        return Icons.spa;
      case 'rose':
        return Icons.favorite;
      case 'sunflower':
      default:
        return Icons.wb_sunny;
    }
  }

  static const availableFlowerTypes = <String>[
    'anemone',
    'bluebell',
    'chrysanthemum',
    'geranium',
    'lavender',
    'lily',
    'purple_aster',
    'ranunculus',
    'rose',
    'sunflower',
  ];

  static String getFlowerAssetPath(String flowerType) {
    final assetName = switch (flowerType) {
      'anemone' => 'Anemone.png',
      'bluebell' => 'Bluebell.png',
      'chrysanthemum' => 'Chrysanthemum.png',
      'geranium' => 'Geranium.png',
      'lavender' => 'Lavender.png',
      'lily' || 'sampaguita' => 'Lily.png',
      'purple_aster' || 'orchid' => 'Purple Aster.png',
      'ranunculus' || 'tulip' => 'Ranunculus.png',
      'rose' => 'Rose.png',
      _ => 'Sunflower.png',
    };
    return 'assets/gratitude garden assets/$assetName';
  }

  /// Corrects for the different visual mass of each full-canvas flower asset.
  static double getFlowerScale(String flowerType) => switch (flowerType) {
        'sunflower' => 0.84,
        'chrysanthemum' => 0.88,
        'geranium' => 0.9,
        'lavender' => 0.94,
        'lily' || 'sampaguita' => 0.86,
        'purple_aster' || 'orchid' => 0.92,
        'bluebell' => 0.9,
        'rose' => 0.9,
        'anemone' => 0.92,
        _ => 0.96,
      };
}
