import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/uuid_helper.dart';

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

  MoodLog copyWith({
    String? id,
    int? moodScore,
    String? moodLabel,
    int? stressLevel,
    int? energyLevel,
    int? sleepQuality,
    int? anxietyLevel,
    String? note,
    DateTime? createdAt,
  }) {
    return MoodLog(
      id: id ?? this.id,
      moodScore: moodScore ?? this.moodScore,
      moodLabel: moodLabel ?? this.moodLabel,
      stressLevel: stressLevel ?? this.stressLevel,
      energyLevel: energyLevel ?? this.energyLevel,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      anxietyLevel: anxietyLevel ?? this.anxietyLevel,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap({String? userId}) {
    final validId = UuidHelper.isValidUuid(id) ? id : UuidHelper.generateV4();
    final map = <String, dynamic>{
      'id': validId,
      'mood_score': moodScore,
      'mood_label': moodLabel,
      'stress_level': stressLevel,
      'energy_level': energyLevel,
      'sleep_quality': sleepQuality,
      'anxiety_level': anxietyLevel,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
    if (userId != null && userId.isNotEmpty) {
      map['user_id'] = userId;
    }
    return map;
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
          ? DateTime.parse(map['created_at']).toLocal()
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

  static String getMoodName(int score) {
    switch (score) {
      case 1:
        return 'Struggling';
      case 2:
        return 'Low';
      case 3:
        return 'Okay';
      case 4:
        return 'Good';
      case 5:
      default:
        return 'Great';
    }
  }

  static String getMoodLabel(int score) => getMoodName(score);

  static String getMoodAssetPath(int score) {
    switch (score) {
      case 1:
        return 'assets/mood tracker/Very Sad.png';
      case 2:
        return 'assets/mood tracker/Sad.png';
      case 3:
        return 'assets/mood tracker/OK.png';
      case 4:
        return 'assets/mood tracker/Good.png';
      case 5:
      default:
        return 'assets/mood tracker/Very Good.png';
    }
  }
}

class SleepAssetHelper {
  static String getSleepAssetPath(int quality) {
    switch (quality) {
      case 1:
        return 'assets/sleep log/Deprived.png';
      case 2:
        return 'assets/sleep log/Bad.png';
      case 3:
        return 'assets/sleep log/Okay.png';
      case 4:
        return 'assets/sleep log/Great.png';
      case 5:
      default:
        return 'assets/sleep log/Energized.png';
    }
  }

  static String getSleepLabel(int quality) {
    switch (quality) {
      case 1:
        return 'Deprived';
      case 2:
        return 'Bad';
      case 3:
        return 'Okay';
      case 4:
        return 'Great';
      case 5:
      default:
        return 'Energized';
    }
  }
}

class FeatureIconHelper {
  static const String affirmations =
      'assets/feature icons/Affirmations.png';
  static const String breathing = 'assets/feature icons/Breathing.png';
  static const String dailyReflection =
      'assets/feature icons/Daily Reflection.png';
  static const String entries = 'assets/feature icons/Entries.png';
  static const String gratitudeGarden =
      'assets/feature icons/Gratitude Garden.png';
  static const String grounding =
      'assets/feature icons/5-4-3-2-1 Grounding.png';
  static const String journal = 'assets/feature icons/Journal.png';
  static const String learn = 'assets/feature icons/Learn.png';
  static const String midDayRoutine =
      'assets/feature icons/Mid-day routine.png';
  static const String moodTracker = 'assets/feature icons/Mood Tracker.png';
  static const String morningRoutine =
      'assets/feature icons/Morning Routine.png';
  static const String nightRoutine = 'assets/feature icons/Night Routine.png';
  static const String routines = 'assets/feature icons/Routines.png';
  static const String sleepLog = 'assets/feature icons/Sleep log.png';
  static const String todaysFocus = 'assets/feature icons/Today\'s Focus.png';
  static const String todaysHighlight =
      'assets/feature icons/Today\'s Higlight.png';
  static const String weeklyInsights =
      'assets/feature icons/Weekly Insights.png';
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
        description:
            'Your emotional atmosphere has been radiant and clear this week.',
        icon: '☀️',
        gradientColors: [Color(0xFFFFF3B0), Color(0xFFE9C46A)],
      );
    } else if (averageScore >= 3.4) {
      return const EmotionalWeatherInfo(
        type: EmotionalWeatherType.goldenSunset,
        title: 'Golden Sunset',
        description:
            'A warm, calm atmosphere with mild passing clouds of reflection.',
        icon: '🌤️',
        gradientColors: [Color(0xFFF8C8BA), Color(0xFFE8AEB7)],
      );
    } else if (averageScore >= 2.5) {
      return const EmotionalWeatherInfo(
        type: EmotionalWeatherType.gentleRain,
        title: 'Gentle Calming Rain',
        description:
            'Rain brings nourishment and growth. Take time for slow, quiet care.',
        icon: '🌧️',
        gradientColors: [Color(0xFFA8DADC), Color(0xFF457B9D)],
      );
    } else {
      return const EmotionalWeatherInfo(
        type: EmotionalWeatherType.starryNight,
        title: 'Peaceful Starry Night',
        description:
            'Rest in the quiet stillness. Every night gives way to a new dawn.',
        icon: '🌌',
        gradientColors: [Color(0xFF2B2D42), Color(0xFF1D3557)],
      );
    }
  }
}
