import '../insights/wellness_analytics.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _didInitializeIdentity = false;
  RoutineSessionState? _activeSession;

  RoutinesProvider({
    Iterable<RoutineLog> initialLogs = const [],
    bool syncOnCreate = true,
  }) {
    _initDefaultRoutines();
    _logs.addAll(initialLogs);
    if (syncOnCreate) syncForCurrentUser();
  }

  List<RoutineConfig> get allRoutines => _routines.values.toList();
  List<RoutineLog> get logs => List.unmodifiable(
      List<RoutineLog>.of(_logs)
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt)),
  );
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  RoutineSessionState? get activeSession => _activeSession;

  RoutineLog? get todayHighlight {
    final now = DateTime.now();
    final candidates = _logs.where((log) {
      final text = log.focusOrHighlight?.trim() ?? '';
      return text.isNotEmpty &&
          text.toLowerCase() != 'sample' &&
          _isSameDay(log.completedAt, now);
    }).toList()
      ..sort((left, right) => right.completedAt.compareTo(left.completedAt));

    // Highlights saved by the dedicated activity are authoritative. Older
    // versions stored a night-routine highlight on the routine completion log,
    // so keep that as a compatibility fallback without mistaking sleep/focus
    // notes for the home highlight.
    for (final log in candidates) {
      if (log.routineId.startsWith('highlight_')) return log;
    }
    for (final log in candidates) {
      if (log.routineId == 'night' && log.routineType == RoutineType.night) {
        return log;
      }
    }
    return null;
  }

  static bool _isSameDay(DateTime left, DateTime right) {
    final localLeft = left.toLocal();
    final localRight = right.toLocal();
    return localLeft.year == localRight.year &&
        localLeft.month == localRight.month &&
        localLeft.day == localRight.day;
  }

  void syncForCurrentUser() {
    final userId = SupabaseService.isInitialized
        ? SupabaseService.client.auth.currentUser?.id
        : null;
    if (_didInitializeIdentity && userId == _activeUserId) return;
    _didInitializeIdentity = true;
    _activeUserId = userId;
    _activeSession = null;
    _routines.clear();
    _initDefaultRoutines();
    _logs.clear();
    _errorMessage = null;
    notifyListeners();
    unawaited(_restoreRoutineState(userId));
    if (userId != null) fetchRoutineLogs();
  }

  Future<void> _restoreRoutineState(String? userId) async {
    try {
      await _restoreRoutineConfigs(userId);
      await _restoreActiveSession(userId);
    } catch (_) {
      // Platform storage is not available in every host (for example, a
      // provider-only unit test). Routines still work from their defaults.
    }
  }

  String _sessionKey(String? userId) =>
      'routine_active_session_v1_${userId ?? 'local'}';

  String _configKey(String? userId) =>
      'routine_configurations_v1_${userId ?? 'local'}';

  Future<void> _restoreRoutineConfigs(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_configKey(userId));
    if (_activeUserId != userId || raw == null) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final restored = <String, RoutineConfig>{};
      for (final item in decoded) {
        final routine = _routineFromJson(item as Map<String, dynamic>);
        if (routine.id.isNotEmpty) {
          restored[routine.id] = routine;
        }
      }
      if (_activeUserId != userId || restored.isEmpty) return;
      for (final entry in restored.entries) {
        _routines[entry.key] = entry.value;
      }
      notifyListeners();
    } catch (_) {
      await prefs.remove(_configKey(userId));
    }
  }

  Future<void> _persistRoutineConfigs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _configKey(_activeUserId),
        jsonEncode(_routines.values.map(_routineToJson).toList()),
      );
    } catch (_) {
      // Keep in-memory customization usable if local storage is unavailable.
    }
  }

  Map<String, dynamic> _routineToJson(RoutineConfig routine) => {
        'id': routine.id,
        'title': routine.title,
        'subtitle': routine.subtitle,
        'type': routine.type.name,
        'reminderHour': routine.reminderTime.hour,
        'reminderMinute': routine.reminderTime.minute,
        'isEnabled': routine.isEnabled,
        'primaryColor': routine.primaryColor.toARGB32(),
        'steps': routine.steps
            .map(
              (step) => {
                'id': step.id,
                'title': step.title,
                'subtitle': step.subtitle,
                'type': step.type.name,
                'isEnabled': step.isEnabled,
                'estimatedMinutes': step.estimatedMinutes,
                'customPrompt': step.customPrompt,
              },
            )
            .toList(),
      };

  RoutineConfig _routineFromJson(Map<String, dynamic> json) {
    final type = RoutineType.values.firstWhere(
      (value) => value.name == json['type'],
      orElse: () => RoutineType.custom,
    );
    final steps = (json['steps'] as List<dynamic>? ?? const [])
        .map((item) {
          final map = item as Map<String, dynamic>;
          final stepType = StepType.values.firstWhere(
            (value) => value.name == map['type'],
            orElse: () => StepType.custom,
          );
          return RoutineStep(
            id: map['id'] as String? ?? '',
            title: map['title'] as String? ?? 'Activity',
            subtitle: map['subtitle'] as String? ?? '',
            icon: _iconForStepType(stepType),
            type: stepType,
            isEnabled: map['isEnabled'] as bool? ?? true,
            estimatedMinutes: map['estimatedMinutes'] as int? ?? 2,
            customPrompt: map['customPrompt'] as String?,
          );
        })
        .where((step) => step.id.isNotEmpty)
        .toList();
    return RoutineConfig(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Routine',
      subtitle: json['subtitle'] as String? ?? '',
      type: type,
      reminderTime: TimeOfDay(
        hour: (json['reminderHour'] as int? ?? 12).clamp(0, 23),
        minute: (json['reminderMinute'] as int? ?? 0).clamp(0, 59),
      ),
      isEnabled: json['isEnabled'] as bool? ?? true,
      steps: steps,
      primaryColor: Color(
        json['primaryColor'] as int? ?? AppColors.honeyAmber.toARGB32(),
      ),
    );
  }

  IconData _iconForStepType(StepType type) => switch (type) {
        StepType.sleepTracker => Icons.wb_twilight_rounded,
        StepType.journalFocus => Icons.lightbulb_outline_rounded,
        StepType.journalHighlight => Icons.auto_stories_outlined,
        StepType.grounding => Icons.spa_outlined,
        StepType.meditation => Icons.air_rounded,
        StepType.moodTracker => Icons.sentiment_satisfied_alt_outlined,
        StepType.gratitudeGarden => Icons.local_florist_outlined,
        StepType.custom => Icons.star_outline_rounded,
      };

  Future<void> _restoreActiveSession(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey(userId));
    if (_activeUserId != userId || raw == null) return;
    try {
      final restored = RoutineSessionState.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      final routine = _routines[restored.routineId];
      final isToday = _isSameDay(restored.updatedAt, DateTime.now());
      if (!isToday || routine == null || !routine.isEnabled) {
        await prefs.remove(_sessionKey(userId));
        return;
      }
      final stepCount = routine.activeStepsCount;
      _activeSession = RoutineSessionState(
        routineId: restored.routineId,
        nextStepIndex: restored.nextStepIndex.clamp(0, stepCount),
        skippedStepIds: restored.skippedStepIds,
        updatedAt: restored.updatedAt,
      );
      notifyListeners();
    } catch (_) {
      await prefs.remove(_sessionKey(userId));
    }
  }

  Future<void> _persistActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _sessionKey(_activeUserId);
      final session = _activeSession;
      if (session == null) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, jsonEncode(session.toJson()));
      }
    } catch (_) {
      // The current session remains valid in memory for this app run.
    }
  }

  RoutineSessionState? sessionFor(String routineId) {
    final session = _activeSession;
    if (session == null || session.routineId != routineId) return null;
    if (!_isSameDay(session.updatedAt, DateTime.now())) return null;
    return session;
  }

  void startRoutineSession(String routineId) {
    _activeSession = RoutineSessionState(
      routineId: routineId,
      nextStepIndex: 0,
      skippedStepIds: const {},
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    unawaited(_persistActiveSession());
  }

  void updateRoutineSession(
    String routineId,
    int nextStepIndex,
    Set<String> skippedStepIds,
  ) {
    _activeSession = RoutineSessionState(
      routineId: routineId,
      nextStepIndex: nextStepIndex,
      skippedStepIds: Set.unmodifiable(skippedStepIds),
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    unawaited(_persistActiveSession());
  }

  void clearRoutineSession([String? routineId]) {
    if (routineId != null && _activeSession?.routineId != routineId) return;
    _activeSession = null;
    notifyListeners();
    unawaited(_persistActiveSession());
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
        return _availableRoutine('morning');
      case RoutineType.midday:
        return _availableRoutine('midday');
      case RoutineType.night:
        return _availableRoutine('night');
      case RoutineType.custom:
        return _availableRoutine('morning');
    }
  }

  RoutineConfig? _availableRoutine(String id) {
    final routine = getRoutineById(id);
    if (routine != null && routine.isEnabled && routine.activeStepsCount > 0) {
      return routine;
    }
    for (final candidate in _routines.values) {
      if (candidate.isEnabled && candidate.activeStepsCount > 0) {
        return candidate;
      }
    }
    return null;
  }

  RoutineConfig? getRoutineById(String id) => _routines[id];

  int get completedTodayCount {
    final now = DateTime.now();
    return _logs
        .where((log) =>
            _routines.containsKey(log.routineId) && routineActivity(log) == 'routine' &&
            _isSameDay(log.completedAt, now))
        .map((log) => log.routineId)
        .toSet()
        .length;
  }

  int get streakDays => WellnessStreak.fromDates(
    _logs.where((log) => routineActivity(log) == 'routine')
      .map((log) => log.completedAt),
  ).current;
  bool isRoutineCompletedToday(RoutineType type) {
    return isRoutineCompletedTodayById(type.name);
  }

  bool isRoutineCompletedTodayById(String routineId) {
    final now = DateTime.now();
    return _logs.any((log) =>
        log.routineId == routineId && routineActivity(log) == 'routine' && _isSameDay(log.completedAt, now));
  }

  void _initDefaultRoutines() {
    // Morning Routine
    _routines['morning'] = RoutineConfig(
      id: 'morning',
      title: 'Morning Routine',
      subtitle: 'Start your day with clarity & positivity',
      type: RoutineType.morning,
      reminderTime: const TimeOfDay(hour: 7, minute: 30),
      primaryColor: AppColors.honeyAmber,
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
          title: '30-second breathing reset',
          subtitle: 'Three calm breaths before you begin',
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
      primaryColor: AppColors.honeyGold,
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
          title: 'Quick 3-2-1 grounding',
          subtitle: 'A focused sensory reset in about 30 seconds',
          icon: Icons.spa_outlined,
          type: StepType.grounding,
          estimatedMinutes: 1,
        ),
        RoutineStep(
          id: 'md-breath',
          title: '30-second breathing reset',
          subtitle: 'Three calm breaths with a longer exhale',
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
      primaryColor: AppColors.warmHoney,
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
          title: 'Quick 3-2-1 grounding',
          subtitle: 'Return to the room in about 30 seconds',
          icon: Icons.spa_outlined,
          type: StepType.grounding,
          estimatedMinutes: 1,
        ),
        RoutineStep(
          id: 'n-breath',
          title: '30-second breathing reset',
          subtitle: 'Three slower breaths before rest',
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
      _logs.sort((a, b) => b.completedAt.compareTo(a.completedAt));
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
      clearRoutineSession(routineId);
      unawaited(_persistRoutineConfigs());
      notifyListeners();
    }
  }

  void addStepToRoutine(String routineId, RoutineStep step) {
    final routine = _routines[routineId];
    if (routine != null) {
      final updatedSteps = List<RoutineStep>.from(routine.steps)..add(step);
      _routines[routineId] = routine.copyWith(steps: updatedSteps);
      clearRoutineSession(routineId);
      unawaited(_persistRoutineConfigs());
      notifyListeners();
    }
  }

  void removeStepFromRoutine(String routineId, String stepId) {
    final routine = _routines[routineId];
    if (routine != null) {
      final updatedSteps = routine.steps.where((s) => s.id != stepId).toList();
      _routines[routineId] = routine.copyWith(steps: updatedSteps);
      clearRoutineSession(routineId);
      unawaited(_persistRoutineConfigs());
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
      clearRoutineSession(routineId);
      unawaited(_persistRoutineConfigs());
      notifyListeners();
    }
  }

  void updateReminderTime(String routineId, TimeOfDay time) {
    final routine = _routines[routineId];
    if (routine != null) {
      _routines[routineId] = routine.copyWith(reminderTime: time);
      unawaited(_persistRoutineConfigs());
      notifyListeners();
    }
  }

  void toggleRoutineEnabled(String routineId) {
    final routine = _routines[routineId];
    if (routine != null) {
      _routines[routineId] = routine.copyWith(isEnabled: !routine.isEnabled);
      if (routine.isEnabled) clearRoutineSession(routineId);
      unawaited(_persistRoutineConfigs());
      notifyListeners();
    }
  }

  void addCustomRoutine(RoutineConfig routine) {
    _routines[routine.id] = routine;
    unawaited(_persistRoutineConfigs());
    notifyListeners();
  }

  void deleteCustomRoutine(String routineId) {
    if (_routines.containsKey(routineId) &&
        routineId != 'morning' &&
        routineId != 'midday' &&
        routineId != 'night') {
      _routines.remove(routineId);
      clearRoutineSession(routineId);
      unawaited(_persistRoutineConfigs());
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
      _logs.sort((a, b) => b.completedAt.compareTo(a.completedAt));
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
