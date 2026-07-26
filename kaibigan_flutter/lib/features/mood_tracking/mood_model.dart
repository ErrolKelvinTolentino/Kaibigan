import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MoodLog {
  final String id;
  final int moodScore; // 1 to 5
  final String moodLabel;
  final int stressLevel; // 1 to 5
  final int energyLevel; // 1 to 5
  final int sleepQuality; // 1 to 5
  final int anxietyLevel; // 1 to 5
  final String? note;
  final DateTime createdAt;

  MoodLog({
    required this.id,
    required this.moodScore,
    required this.moodLabel,
    this.stressLevel = 3,
    this.energyLevel = 3,
    this.sleepQuality = 3,
    this.anxietyLevel = 3,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mood_score': moodScore,
      'mood_label': moodLabel,
      'stress_level': stressLevel,
      'energy_level': energyLevel,
      'sleep_quality': sleepQuality,
      'anxiety_level': anxietyLevel,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MoodLog.fromMap(Map<String, dynamic> map) {
    return MoodLog(
      id: map['id'] ?? '',
      moodScore: map['mood_score'] ?? 3,
      moodLabel: map['mood_label'] ?? 'Okay',
      stressLevel: map['stress_level'] ?? 3,
      energyLevel: map['energy_level'] ?? 3,
      sleepQuality: map['sleep_quality'] ?? 3,
      anxietyLevel: map['anxiety_level'] ?? 3,
      note: map['note'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  static Color getMoodColor(int score) {
    switch (score) {
      case 1:
        return AppColors.moodAwful;
      case 2:
        return AppColors.moodLow;
      case 3:
        return AppColors.moodOkay;
      case 4:
        return AppColors.moodGood;
      case 5:
      default:
        return AppColors.moodAwesome;
    }
  }

  static String getMoodEmoji(int score) {
    switch (score) {
      case 1:
        return '😔';
      case 2:
        return '🙁';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
      default:
        return '😊';
    }
  }
}

enum EmotionalWeatherType {
  sunny,
  goldenSunset,
  gentleRain,
  starryNight,
}

class EmotionalWeatherInfo {
  final EmotionalWeatherType type;
  final String title;
  final String description;
  final String icon;
  final List<Color> gradientColors;

  const EmotionalWeatherInfo({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
  });

  static EmotionalWeatherInfo getWeatherForScore(double averageScore) {
    if (averageScore >= 4.2) {
      return const EmotionalWeatherInfo(
        type: EmotionalWeatherType.sunny,
        title: 'Sunny & Bright Sky',
        description: 'Your emotional atmosphere has been radiant and clear this week.',
        icon: '☀️',
        gradientColors: [Color(0xFFFFF3B0), Color(0xFFE9C46A)],
      );
    } else if (averageScore >= 3.4) {
      return const EmotionalWeatherInfo(
        type: EmotionalWeatherType.goldenSunset,
        title: 'Golden Sunset',
        description: 'A warm, calm atmosphere with mild passing clouds of reflection.',
        icon: '🌤️',
        gradientColors: [Color(0xFFF8C8BA), Color(0xFFE8AEB7)],
      );
    } else if (averageScore >= 2.5) {
      return const EmotionalWeatherInfo(
        type: EmotionalWeatherType.gentleRain,
        title: 'Gentle Calming Rain',
        description: 'Rain brings nourishment and growth. Take time for slow, quiet care.',
        icon: '🌧️',
        gradientColors: [Color(0xFFA8DADC), Color(0xFF457B9D)],
      );
    } else {
      return const EmotionalWeatherInfo(
        type: EmotionalWeatherType.starryNight,
        title: 'Peaceful Starry Night',
        description: 'Rest in the quiet stillness. Every night gives way to a new dawn.',
        icon: '🌌',
        gradientColors: [Color(0xFF2B2D42), Color(0xFF1D3557)],
      );
    }
  }
}
