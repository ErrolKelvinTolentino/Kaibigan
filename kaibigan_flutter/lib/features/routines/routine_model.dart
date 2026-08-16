import 'package:flutter/material.dart';
import '../../core/utils/uuid_helper.dart';

enum RoutineType {
  morning,
  midday,
  night,
  custom,
}

enum SleepFeeling {
  restless,
  groggy,
  moderate,
  wellRested,
  energized,
}

extension SleepFeelingExtension on SleepFeeling {
  String get label {
    switch (this) {
      case SleepFeeling.restless:
        return 'Restless';
      case SleepFeeling.groggy:
        return 'A Bit Groggy';
      case SleepFeeling.moderate:
        return 'Moderate';
      case SleepFeeling.wellRested:
        return 'Well Rested';
      case SleepFeeling.energized:
        return 'Fully Energized';
    }
  }

  String get description {
    switch (this) {
      case SleepFeeling.restless:
        return 'Tossed and turned or slept fitfully';
      case SleepFeeling.groggy:
        return 'Needed a bit more sleep to feel awake';
      case SleepFeeling.moderate:
        return 'Slept okay, ready for the day';
      case SleepFeeling.wellRested:
        return 'Woke up feeling peaceful and clear';
      case SleepFeeling.energized:
        return 'Fully recharged and excited';
    }
  }

  IconData get icon {
    switch (this) {
      case SleepFeeling.restless:
        return Icons.nights_stay_outlined;
      case SleepFeeling.groggy:
        return Icons.bedtime_outlined;
      case SleepFeeling.moderate:
        return Icons.wb_twilight;
      case SleepFeeling.wellRested:
        return Icons.wb_sunny_outlined;
      case SleepFeeling.energized:
        return Icons.light_mode_outlined;
    }
  }

  String get assetPath {
    switch (this) {
      case SleepFeeling.restless:
        return 'assets/sleep log/Deprived.png';
      case SleepFeeling.groggy:
        return 'assets/sleep log/Bad.png';
      case SleepFeeling.moderate:
        return 'assets/sleep log/Okay.png';
      case SleepFeeling.wellRested:
        return 'assets/sleep log/Great.png';
      case SleepFeeling.energized:
        return 'assets/sleep log/Energized.png';
    }
  }

  int get score {
    switch (this) {
      case SleepFeeling.restless:
        return 1;
      case SleepFeeling.groggy:
        return 2;
      case SleepFeeling.moderate:
        return 3;
      case SleepFeeling.wellRested:
        return 4;
      case SleepFeeling.energized:
        return 5;
    }
  }
}

enum StepType {
  sleepTracker,
  journalFocus,
  journalHighlight,
  grounding,
  meditation,
  moodTracker,
  gratitudeGarden,
  custom,
}

class RoutineStep {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final StepType type;
  bool isEnabled;
  final int estimatedMinutes;
  final String? customPrompt;

  RoutineStep({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
    this.isEnabled = true,
    this.estimatedMinutes = 2,
    this.customPrompt,
  });

  RoutineStep copyWith({
    String? id,
    String? title,
    String? subtitle,
    IconData? icon,
    StepType? type,
    bool? isEnabled,
    int? estimatedMinutes,
    String? customPrompt,
  }) {
    return RoutineStep(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      isEnabled: isEnabled ?? this.isEnabled,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      customPrompt: customPrompt ?? this.customPrompt,
    );
  }
}

class RoutineConfig {
  final String id;
  final String title;
  final String subtitle;
  final RoutineType type;
  final TimeOfDay reminderTime;
  final bool isEnabled;
  final List<RoutineStep> steps;
  final Color primaryColor;

  RoutineConfig({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.reminderTime,
    this.isEnabled = true,
    required this.steps,
    required this.primaryColor,
  });

  RoutineConfig copyWith({
    String? id,
    String? title,
    String? subtitle,
    RoutineType? type,
    TimeOfDay? reminderTime,
    bool? isEnabled,
    List<RoutineStep>? steps,
    Color? primaryColor,
  }) {
    return RoutineConfig(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      type: type ?? this.type,
      reminderTime: reminderTime ?? this.reminderTime,
      isEnabled: isEnabled ?? this.isEnabled,
      steps: steps ?? this.steps,
      primaryColor: primaryColor ?? this.primaryColor,
    );
  }

  int get activeStepsCount => steps.where((s) => s.isEnabled).length;
  int get totalMinutes => steps.where((s) => s.isEnabled).fold(0, (sum, s) => sum + s.estimatedMinutes);
}

class RoutineLog {
  final String id;
  final String routineId;
  final RoutineType routineType;
  final DateTime completedAt;
  final SleepFeeling? sleepFeeling;
  final String? focusOrHighlight;
  final int? moodScore;
  final String? moodNote;
  final String? gratitudeContent;

  RoutineLog({
    required this.id,
    required this.routineId,
    required this.routineType,
    required this.completedAt,
    this.sleepFeeling,
    this.focusOrHighlight,
    this.moodScore,
    this.moodNote,
    this.gratitudeContent,
  });

  Map<String, dynamic> toMap({String? userId}) {
    final validId = UuidHelper.isValidUuid(id) ? id : UuidHelper.generateV4();
    final map = <String, dynamic>{
      'id': validId,
      'routine_id': routineId,
      'routine_type': routineType.name,
      'sleep_feeling': sleepFeeling?.name,
      'focus_or_highlight': focusOrHighlight,
      'mood_score': moodScore,
      'mood_note': moodNote,
      'gratitude_content': gratitudeContent,
      'completed_at': completedAt.toIso8601String(),
    };
    if (userId != null && userId.isNotEmpty) {
      map['user_id'] = userId;
    }
    return map;
  }

  factory RoutineLog.fromMap(Map<String, dynamic> map) {
    return RoutineLog(
      id: map['id'] ?? '',
      routineId: map['routine_id'] ?? 'morning',
      routineType: RoutineType.values.firstWhere(
        (e) => e.name == map['routine_type'],
        orElse: () => RoutineType.morning,
      ),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'])
          : DateTime.now(),
      sleepFeeling: map['sleep_feeling'] != null
          ? SleepFeeling.values.firstWhere(
              (e) => e.name == map['sleep_feeling'],
              orElse: () => SleepFeeling.moderate,
            )
          : null,
      focusOrHighlight: map['focus_or_highlight'],
      moodScore: map['mood_score'],
      moodNote: map['mood_note'],
      gratitudeContent: map['gratitude_content'],
    );
  }
}
