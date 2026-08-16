import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/uuid_helper.dart';
import 'routine_model.dart';

class RoutinesProvider extends ChangeNotifier {
  final Map<String, RoutineConfig> _routines = {};
  final List<RoutineLog> _logs = [];

  RoutinesProvider() {
    _initDefaultRoutines();
    _initSampleLogs();
    fetchRoutineLogs();
  }

  List<RoutineConfig> get allRoutines => _routines.values.toList();
  List<RoutineLog> get logs => List.unmodifiable(_logs);

  RoutineType get currentPhase {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return RoutineType.morning;
    } else if (hour >= 12 && hour < 17) {
      return RoutineType.midday;
    } else {
      return RoutineType.night;
    }
  }

  RoutineConfig? get recommendedRoutine {
    final phase = currentPhase;
    switch (phase) {
      case RoutineType.morning:
        return getRoutineById('morning');
      case RoutineType.midday:
        return getRoutineById('midday');
      case RoutineType.night:
        return getRoutineById('night');
      case RoutineType.custom:
        return getRoutineById('morning');
    }
  }

  RoutineConfig? getRoutineById(String id) => _routines[id];

  int get completedTodayCount {
    final now = DateTime.now();
    return _logs.where((log) =>
        log.completedAt.year == now.year &&
        log.completedAt.month == now.month &&
        log.completedAt.day == now.day).length;
  }

  int get streakDays {
    if (_logs.isEmpty) return 3; // Friendly default streak count
    return 4;
  }

  bool isRoutineCompletedToday(RoutineType type) {
    final now = DateTime.now();
    return _logs.any((log) =>
        log.routineType == type &&
        log.completedAt.year == now.year &&
        log.completedAt.month == now.month &&
        log.completedAt.day == now.day);
  }

  void _initDefaultRoutines() {
    // Morning Routine
    _routines['morning'] = RoutineConfig(
      id: 'morning',
      title: 'Morning Routine',
      subtitle: 'Start your day with clarity & positivity',
      type: RoutineType.morning,
      reminderTime: const TimeOfDay(hour: 7, minute: 30),
      primaryColor: AppColors.sageGreen,
      steps: [
        RoutineStep(
          id: 'm-gratitude',
          title: 'Gratitude Garden',
          subtitle: 'Record gratitude & plant a flower',
          icon: Icons.local_florist_outlined,
          type: StepType.gratitudeGarden,
          estimatedMinutes: 2,
        ),
        RoutineStep(
          id: 'm-focus',
          title: 'Today\'s Focus',
          subtitle: 'Identify 1-2 key priorities for today',
          icon: Icons.lightbulb_outline,
          type: StepType.journalFocus,
          estimatedMinutes: 2,
        ),
        RoutineStep(
          id: 'm-mood',
          title: 'Mood Tracker',
          subtitle: 'Check in with your morning feelings',
          icon: Icons.sentiment_satisfied_alt_outlined,
          type: StepType.moodTracker,
          estimatedMinutes: 1,
        ),
        RoutineStep(
          id: 'm-breath',
          title: 'Quick Breathing Exercise',
          subtitle: '1-minute morning breathing pause',
          icon: Icons.air,
          type: StepType.meditation,
          estimatedMinutes: 1,
        ),
      ],
    );

    // Mid-Day Routine
    _routines['midday'] = RoutineConfig(
      id: 'midday',
      title: 'Mid-day Routine',
      subtitle: 'Pause, check in, and reset your day',
      type: RoutineType.midday,
      reminderTime: const TimeOfDay(hour: 13, minute: 0),
      primaryColor: AppColors.softRose,
      steps: [
        RoutineStep(
          id: 'md-mood',
          title: 'Mood Tracker',
          subtitle: 'Check in with your mid-day feelings',
          icon: Icons.sentiment_satisfied_alt_outlined,
          type: StepType.moodTracker,
          estimatedMinutes: 1,
        ),
        RoutineStep(
          id: 'md-focus',
          title: 'Today\'s Focus',
          subtitle: 'Re-center on what matters most today',
          icon: Icons.lightbulb_outline,
          type: StepType.journalFocus,
          estimatedMinutes: 2,
        ),
        RoutineStep(
          id: 'md-grounding',
          title: '5-4-3-2-1 Grounding',
          subtitle: 'Anchor your senses to the present moment',
          icon: Icons.spa_outlined,
          type: StepType.grounding,
          estimatedMinutes: 3,
        ),
        RoutineStep(
          id: 'md-breath',
          title: 'Quick Breathing Exercise',
          subtitle: '1-minute calming box breathing',
          icon: Icons.air,
          type: StepType.meditation,
          estimatedMinutes: 1,
        ),
      ],
    );

    // Night Routine
    _routines['night'] = RoutineConfig(
      id: 'night',
      title: 'Night Routine',
      subtitle: 'Reflect on your day & transition toward rest',
      type: RoutineType.night,
      reminderTime: const TimeOfDay(hour: 21, minute: 30),
      primaryColor: AppColors.lavenderMist,
      steps: [
        RoutineStep(
          id: 'n-highlight',
          title: 'Today\'s Highlight',
          subtitle: 'Reflect on one positive moment from your day',
          icon: Icons.auto_stories_outlined,
          type: StepType.journalHighlight,
          estimatedMinutes: 2,
        ),
        RoutineStep(
          id: 'n-gratitude',
          title: 'Gratitude Garden',
          subtitle: 'Plant a flower for something you\'re grateful for',
          icon: Icons.local_florist_outlined,
          type: StepType.gratitudeGarden,
          estimatedMinutes: 2,
        ),
        RoutineStep(
          id: 'n-mood',
          title: 'Mood Tracker',
          subtitle: 'Record how you feel tonight',
          icon: Icons.sentiment_satisfied_alt_outlined,
          type: StepType.moodTracker,
          estimatedMinutes: 1,
        ),
        RoutineStep(
          id: 'n-grounding',
          title: '5-4-3-2-1 Grounding',
          subtitle: 'Unwind and bring attention back to present',
          icon: Icons.spa_outlined,
          type: StepType.grounding,
          estimatedMinutes: 3,
        ),
        RoutineStep(
          id: 'n-breath',
          title: 'Quick Breathing Exercise',
          subtitle: 'Gentle evening breathing reset',
          icon: Icons.air,
          type: StepType.meditation,
          estimatedMinutes: 1,
        ),
      ],
    );
  }

  void _initSampleLogs() {
    final now = DateTime.now();
    _logs.addAll([
      RoutineLog(
        id: UuidHelper.generateV4(),
        routineId: 'morning',
        routineType: RoutineType.morning,
        completedAt: now.subtract(const Duration(days: 1, hours: 12)),
        sleepFeeling: SleepFeeling.wellRested,
        focusOrHighlight: 'Finish design prototype with calm mindset',
      ),
      RoutineLog(
        id: UuidHelper.generateV4(),
        routineId: 'night',
        routineType: RoutineType.night,
        completedAt: now.subtract(const Duration(days: 1)),
        moodScore: 4,
        moodNote: 'Peaceful walk around evening',
        gratitudeContent: 'Grateful for rainy breeze',
      ),
    ]);
  }

  Future<void> fetchRoutineLogs() async {
    if (!SupabaseService.isInitialized) return;

    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      var query = SupabaseService.client.from('routine_logs').select();
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      final response = await query.order('completed_at', ascending: false);

      final List data = response as List;
      _logs.clear();
      _logs.addAll(data.map((e) => RoutineLog.fromMap(e)).toList());
      notifyListeners();
    } catch (e) {
      print("Error fetching routine logs: $e");
    }
  }

  void toggleStep(String routineId, String stepId) {
    final routine = _routines[routineId];
    if (routine != null) {
      final updatedSteps = routine.steps.map((step) {
        if (step.id == stepId) {
          return step.copyWith(isEnabled: !step.isEnabled);
        }
        return step;
      }).toList();
      _routines[routineId] = routine.copyWith(steps: updatedSteps);
      notifyListeners();
    }
  }

  void addStepToRoutine(String routineId, RoutineStep step) {
    final routine = _routines[routineId];
    if (routine != null) {
      final updatedSteps = List<RoutineStep>.from(routine.steps)..add(step);
      _routines[routineId] = routine.copyWith(steps: updatedSteps);
      notifyListeners();
    }
  }

  void removeStepFromRoutine(String routineId, String stepId) {
    final routine = _routines[routineId];
    if (routine != null) {
      final updatedSteps = routine.steps.where((s) => s.id != stepId).toList();
      _routines[routineId] = routine.copyWith(steps: updatedSteps);
      notifyListeners();
    }
  }

  void reorderSteps(String routineId, int oldIndex, int newIndex) {
    final routine = _routines[routineId];
    if (routine != null) {
      if (newIndex > oldIndex) newIndex -= 1;
      final updatedSteps = List<RoutineStep>.from(routine.steps);
      final item = updatedSteps.removeAt(oldIndex);
      updatedSteps.insert(newIndex, item);
      _routines[routineId] = routine.copyWith(steps: updatedSteps);
      notifyListeners();
    }
  }

  void updateReminderTime(String routineId, TimeOfDay time) {
    final routine = _routines[routineId];
    if (routine != null) {
      _routines[routineId] = routine.copyWith(reminderTime: time);
      notifyListeners();
    }
  }

  void toggleRoutineEnabled(String routineId) {
    final routine = _routines[routineId];
    if (routine != null) {
      _routines[routineId] = routine.copyWith(isEnabled: !routine.isEnabled);
      notifyListeners();
    }
  }

  void addCustomRoutine(RoutineConfig routine) {
    _routines[routine.id] = routine;
    notifyListeners();
  }

  void deleteCustomRoutine(String routineId) {
    if (_routines.containsKey(routineId) &&
        routineId != 'morning' &&
        routineId != 'midday' &&
        routineId != 'night') {
      _routines.remove(routineId);
      notifyListeners();
    }
  }

  Future<void> addLog(RoutineLog log) async {
    final finalLog = log.id.startsWith('log-') || log.id.isEmpty
        ? RoutineLog(
            id: UuidHelper.generateV4(),
            routineId: log.routineId,
            routineType: log.routineType,
            completedAt: log.completedAt,
            sleepFeeling: log.sleepFeeling,
            focusOrHighlight: log.focusOrHighlight,
            moodScore: log.moodScore,
            moodNote: log.moodNote,
            gratitudeContent: log.gratitudeContent,
          )
        : log;

    _logs.insert(0, finalLog);
    notifyListeners();

    if (SupabaseService.isInitialized) {
      try {
        final userId = SupabaseService.client.auth.currentUser?.id;
        await SupabaseService.client
            .from('routine_logs')
            .insert(finalLog.toMap(userId: userId));
      } catch (e) {
        print("Error saving routine log to Supabase: $e");
      }
    }
  }

  Future<void> completeRoutine(RoutineType type, {String? focusOrHighlight, SleepFeeling? sleepFeeling, int? moodScore, String? moodNote, String? gratitudeContent}) async {
    final log = RoutineLog(
      id: UuidHelper.generateV4(),
      routineId: type.name,
      routineType: type,
      completedAt: DateTime.now(),
      focusOrHighlight: focusOrHighlight,
      sleepFeeling: sleepFeeling,
      moodScore: moodScore,
      moodNote: moodNote,
      gratitudeContent: gratitudeContent,
    );
    await addLog(log);
  }

  Future<void> deleteLog(String id) async {
    _logs.removeWhere((l) => l.id == id);
    notifyListeners();

    if (SupabaseService.isInitialized && UuidHelper.isValidUuid(id)) {
      try {
        await SupabaseService.client
            .from('routine_logs')
            .delete()
            .eq('id', id);
      } catch (e) {
        print("Error deleting routine log: $e");
      }
    }
  }
}
