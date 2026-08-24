import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/uuid_helper.dart';
import '../../core/utils/api_logger.dart';
import 'routine_model.dart';

class RoutinesProvider extends ChangeNotifier {
  final Map<String, RoutineConfig> _routines = {};
  final List<RoutineLog> _logs = [];
  String? _activeUserId;
  String? _errorMessage;
  bool _isLoading = false;

  RoutinesProvider() {
    _initDefaultRoutines();
    syncForCurrentUser();
  }

  List<RoutineConfig> get allRoutines => _routines.values.toList();
  List<RoutineLog> get logs => List.unmodifiable(_logs);
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  RoutineLog? get todayHighlight {
    final now = DateTime.now();
    for (final log in _logs) {
      final text = log.focusOrHighlight?.trim() ?? '';
      if (log.routineType == RoutineType.night &&
          text.isNotEmpty &&
          _isSameDay(log.completedAt, now)) {
        return log;
      }
    }
    return null;
  }

  static bool _isSameDay(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  void syncForCurrentUser() {
    final userId = SupabaseService.isInitialized
        ? SupabaseService.client.auth.currentUser?.id
        : null;
    if (userId == _activeUserId) return;
    _activeUserId = userId;
    _logs.clear();
    _errorMessage = null;
    notifyListeners();
    if (userId != null) fetchRoutineLogs();
  }

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
    return _logs
        .where((log) =>
            log.routineId == log.routineType.name &&
            _isSameDay(log.completedAt, now))
        .length;
  }

  int get streakDays {
    final completedDays = _logs
        .where((log) => log.routineId == log.routineType.name)
        .map((log) => DateTime(
              log.completedAt.year,
              log.completedAt.month,
              log.completedAt.day,
            ))
        .toSet();
    if (completedDays.isEmpty) return 0;

    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    if (!completedDays.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (completedDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  bool isRoutineCompletedToday(RoutineType type) {
    final now = DateTime.now();
    return _logs.any((log) =>
        log.routineId == type.name &&
        log.routineType == type &&
        _isSameDay(log.completedAt, now));
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

  Future<void> fetchRoutineLogs() async {
    _errorMessage = null;
    if (!SupabaseService.isInitialized) {
      _errorMessage =
          'Routine sync is unavailable. Check your connection and try again.';
      notifyListeners();
      return;
    }
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final query = SupabaseService.client
          .from('routine_logs')
          .select()
          .eq('user_id', userId);
      final response = await query.order('completed_at', ascending: false);

      final List data = response as List;
      _logs.clear();
      _logs.addAll(data.map((e) => RoutineLog.fromMap(e)).toList());
      notifyListeners();
    } catch (e) {
      _errorMessage = 'We could not refresh routine history.';
      ApiLogger.logDatabase(
        operation: 'SELECT',
        table: 'routine_logs',
        error: e.toString(),
      );
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
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

  Future<bool> addLog(RoutineLog log) async {
    _errorMessage = null;
    if (log.routineId.trim().isEmpty ||
        (log.moodScore != null && (log.moodScore! < 1 || log.moodScore! > 5))) {
      _errorMessage = 'This routine contains invalid data and was not saved.';
      notifyListeners();
      return false;
    }
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

    if (!SupabaseService.isInitialized ||
        SupabaseService.client.auth.currentUser == null) {
      _errorMessage =
          'Routine completion could not be saved because sync is unavailable.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();
    try {
      final userId = SupabaseService.client.auth.currentUser!.id;
      final response = await SupabaseService.client
          .from('routine_logs')
          .insert(finalLog.toMap(userId: userId))
          .select()
          .single();
      final savedLog = RoutineLog.fromMap(response);
      _logs.removeWhere((item) => item.id == savedLog.id);
      _logs.insert(0, savedLog);
      ApiLogger.logDatabase(
        operation: 'INSERT',
        table: 'routine_logs',
        payload: finalLog.toMap(userId: userId),
        result: {'status': 'success', 'id': savedLog.id},
      );
      return true;
    } catch (e) {
      _errorMessage =
          'Routine completion could not be saved. Please try again.';
      ApiLogger.logDatabase(
        operation: 'INSERT',
        table: 'routine_logs',
        error: e.toString(),
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> completeRoutine(RoutineType type,
      {String? focusOrHighlight,
      SleepFeeling? sleepFeeling,
      int? moodScore,
      String? moodNote,
      String? gratitudeContent}) async {
    if (isRoutineCompletedToday(type)) return true;
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
    return addLog(log);
  }

  Future<bool> updateLog(RoutineLog updated) async {
    _errorMessage = null;
    final userId = SupabaseService.isInitialized
        ? SupabaseService.client.auth.currentUser?.id
        : null;
    if (userId == null || !UuidHelper.isValidUuid(updated.id)) {
      _errorMessage =
          'This saved item cannot be updated because sync is unavailable.';
      notifyListeners();
      return false;
    }

    final index = _logs.indexWhere((log) => log.id == updated.id);
    if (index == -1) {
      _errorMessage = 'This saved item is no longer available.';
      notifyListeners();
      return false;
    }

    final previous = _logs[index];
    _logs[index] = updated;
    _isLoading = true;
    notifyListeners();
    try {
      final response = await SupabaseService.client
          .from('routine_logs')
          .update(updated.toMap(userId: userId))
          .eq('id', updated.id)
          .eq('user_id', userId)
          .select()
          .single();
      _logs[index] = RoutineLog.fromMap(response);
      return true;
    } catch (e) {
      _logs[index] = previous;
      _errorMessage = 'Your changes could not be saved. Please try again.';
      ApiLogger.logDatabase(
        operation: 'UPDATE',
        table: 'routine_logs',
        error: e.toString(),
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteLog(String id) async {
    _errorMessage = null;
    if (!SupabaseService.isInitialized ||
        SupabaseService.client.auth.currentUser == null) {
      _errorMessage =
          'The routine log could not be deleted because sync is unavailable.';
      notifyListeners();
      return false;
    }
    final index = _logs.indexWhere((log) => log.id == id);
    if (index == -1) return true;
    final removed = _logs.removeAt(index);
    notifyListeners();

    if (SupabaseService.isInitialized && UuidHelper.isValidUuid(id)) {
      try {
        final userId = SupabaseService.client.auth.currentUser!.id;
        await SupabaseService.client
            .from('routine_logs')
            .delete()
            .eq('id', id)
            .eq('user_id', userId)
            .select()
            .single();
        notifyListeners();
        return true;
      } catch (e) {
        _logs.insert(index.clamp(0, _logs.length), removed);
        _errorMessage =
            'The routine log could not be deleted. It has been restored.';
        ApiLogger.logDatabase(
          operation: 'DELETE',
          table: 'routine_logs',
          error: e.toString(),
        );
        notifyListeners();
        return false;
      }
    }
    notifyListeners();
    return true;
  }
}
