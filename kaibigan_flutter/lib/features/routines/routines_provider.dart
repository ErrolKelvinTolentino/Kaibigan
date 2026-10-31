import '../insights/wellness_analytics.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/local_record_store.dart';
import '../../core/services/offline_mode.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/uuid_helper.dart';
import '../../core/utils/api_logger.dart';
import 'routine_model.dart';
import 'routine_launch_policy.dart';

class RoutinesProvider extends ChangeNotifier {
  final Map<String, RoutineConfig> _routines = {};
  final List<RoutineLog> _logs = [];
  String? _activeUserId;
  String? _errorMessage;
  bool _isLoading = false;
  bool _didInitializeIdentity = false;
  RoutineSessionState? _activeSession;
  bool? _localIdentity;
  bool _disposed = false;
  int _identityVersion = 0;
  int _sessionVersion = 0;
  final Set<String> _editedRoutineIds = {};
  Future<void> _ready = Future<void>.value();
  Future<void> _historyReady = Future<void>.value();
  bool _hasLoadedHistory = false;
  Future<void> _startupClaims = Future<void>.value();
  final Set<String> _startupOffers = {};
  Future<void> _configurationWrites = Future<void>.value();
  Future<void> _sessionWrites = Future<void>.value();
  int _pendingConfigurationWrites = 0;
  String? _configurationError;
  bool _restorationFailed = false;
  bool _unreadableConfigurations = false;
  final Future<SharedPreferences> Function() _preferences;

  Future<void> get ready => _ready;
  Future<void> get startupReady =>
      Future.wait([_ready, _historyReady]).then((_) {});
  bool get isSavingConfigurations => _pendingConfigurationWrites > 0;
  String? get configurationError => _configurationError;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  RoutinesProvider({
    Iterable<RoutineLog> initialLogs = const [],
    bool syncOnCreate = true,
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _preferences = preferencesLoader ?? SharedPreferences.getInstance {
    _initDefaultRoutines();
    _logs.addAll(initialLogs);
    _hasLoadedHistory = !syncOnCreate;
    if (syncOnCreate) syncForCurrentUser();
  }

  List<RoutineConfig> get allRoutines => _routines.values.toList();
  List<RoutineLog> get logs => List.unmodifiable(
        List<RoutineLog>.of(_logs)
          ..sort((a, b) => b.completedAt.compareTo(a.completedAt)),
      );
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  RoutineSessionState? get activeSession => resumableSessionAt(DateTime.now());

  RoutineSessionState? resumableSessionAt(DateTime now,
      {RoutineConfig? config}) {
    final session = _activeSession;
    final routine =
        config ?? (session == null ? null : _routines[session.routineId]);
    if (session == null ||
        routine == null ||
        routine.id != session.routineId ||
        !RoutineLaunchPolicy.sessionIsCurrent(session, routine, now)) {
      return null;
    }
    final alreadySaved = _logs.any((log) =>
        log.routineId == routine.id &&
        routineActivity(log) == 'routine' &&
        !log.completedAt.isBefore(session.updatedAt) &&
        !log.completedAt.isAfter(now));
    return alreadySaved ? null : session;
  }

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

  /// Offline routine logs are stored in the same shape the table uses, so
  /// the sleep analytics read them without knowing the difference.
  static final LocalRecordStore<RoutineLog> _local =
      LocalRecordStore<RoutineLog>(
    collection: 'routine_logs',
    encode: (log) => log.toMap(),
    decode: RoutineLog.fromMap,
    idOf: (log) => log.id,
  );

  void syncForCurrentUser() {
    final locally = OfflineMode.storesLocally;
    final userId = SupabaseService.isInitialized
        ? SupabaseService.client.auth.currentUser?.id
        : null;
    if (_didInitializeIdentity &&
        userId == _activeUserId &&
        locally == _localIdentity) {
      return;
    }
    final firstInitialization = !_didInitializeIdentity;
    _didInitializeIdentity = true;
    _activeUserId = userId;
    _localIdentity = locally;
    final version = ++_identityVersion;
    _activeSession = null;
    _sessionVersion++;
    _editedRoutineIds.clear();
    _startupOffers.clear();
    _configurationError = null;
    _restorationFailed = false;
    _unreadableConfigurations = false;
    _routines.clear();
    _initDefaultRoutines();
    if (!firstInitialization) _logs.clear();
    _errorMessage = null;
    _hasLoadedHistory = false;
    _ready = _restoreRoutineState(userId, version);
    notifyListeners();
    if (locally || userId != null) _historyReady = fetchRoutineLogs();
  }

  Future<void> _restoreRoutineState(String? userId, int version) async {
    final sessionVersion = _sessionVersion;
    try {
      await _restoreRoutineConfigs(userId, version);
      final prefs = await _preferences();
      if (version == _identityVersion) {
        _startupOffers
            .addAll(prefs.getStringList(_startupKey(userId)) ?? const []);
      }
      if (version == _identityVersion && sessionVersion == _sessionVersion) {
        await _restoreActiveSession(userId, version, sessionVersion);
      }
      if (version == _identityVersion) {
        _restorationFailed = false;
        _configurationError = _unreadableConfigurations
            ? 'Saved routine settings could not be read. Review them and save again.'
            : null;
        notifyListeners();
      }
    } catch (_) {
      if (version == _identityVersion) {
        _restorationFailed = true;
        _configurationError =
            'Saved routines could not be loaded on this device.';
        notifyListeners();
      }
    }
  }

  String _sessionKey(String? userId) =>
      'routine_active_session_v1_${userId ?? 'local'}';

  String _configKey(String? userId) =>
      'routine_configurations_v1_${userId ?? 'local'}';
  String _startupKey(String? userId) =>
      'routine_startup_offers_v1_${userId ?? 'local'}';

  Future<void> _restoreRoutineConfigs(String? userId, int version) async {
    final prefs = await _preferences();
    final raw = prefs.getString(_configKey(userId));
    if (version != _identityVersion || _disposed || raw == null) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final restored = <String, RoutineConfig>{};
      for (final item in decoded) {
        final routine = _routineFromJson(item as Map<String, dynamic>);
        if (routine.id.isNotEmpty) {
          restored[routine.id] = routine;
        }
      }
      if (version != _identityVersion || _disposed || restored.isEmpty) return;
      for (final entry in restored.entries) {
        if (!_editedRoutineIds.contains(entry.key)) {
          _routines[entry.key] = entry.value;
        }
      }
      notifyListeners();
    } catch (_) {
      _unreadableConfigurations = true;
      // Preserve the unreadable original until the person explicitly reviews
      // and resaves their settings. Never autoplay unverified defaults.
      final backupKey = '${_configKey(userId)}_unreadable';
      if (!prefs.containsKey(backupKey)) await prefs.setString(backupKey, raw);
    }
  }

  Future<void> _persistRoutineConfigs() async {
    final version = _identityVersion;
    final key = _configKey(_activeUserId);
    final restoration = _ready;
    _pendingConfigurationWrites++;
    notifyListeners();
    final write = _configurationWrites.then((_) async {
      await restoration;
      if (version != _identityVersion || _restorationFailed) return;
      // Capture after restoration has merged untouched saved routines, and
      // serialize writes so an older operation cannot overwrite a newer edit.
      final value = jsonEncode(_routines.values.map(_routineToJson).toList());
      try {
        final prefs = await _preferences();
        if (!await prefs.setString(key, value)) {
          throw StateError('Configuration storage rejected the write');
        }
        if (version == _identityVersion) {
          _unreadableConfigurations = false;
          _configurationError = null;
        }
      } catch (_) {
        if (version == _identityVersion) {
          _configurationError =
              'Your routine changes could not be saved. Please retry.';
        }
      }
    });
    _configurationWrites = write;
    try {
      await write;
    } finally {
      _pendingConfigurationWrites--;
      notifyListeners();
    }
  }

  Future<void> saveConfigurations() async {
    if (_restorationFailed) {
      _ready = _restoreRoutineState(_activeUserId, _identityVersion);
      await _ready;
      if (_restorationFailed) return;
    }
    await _persistRoutineConfigs();
  }

  Future<void> flushConfigurationWrites() => _configurationWrites;

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

  Future<void> _restoreActiveSession(
      String? userId, int version, int sessionVersion) async {
    final prefs = await _preferences();
    final raw = prefs.getString(_sessionKey(userId));
    if (version != _identityVersion ||
        sessionVersion != _sessionVersion ||
        _disposed ||
        raw == null) {
      return;
    }
    try {
      final restored = RoutineSessionState.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      final routine = _routines[restored.routineId];
      if (routine == null ||
          !RoutineLaunchPolicy.sessionIsCurrent(
              restored, routine, DateTime.now())) {
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
    final key = _sessionKey(_activeUserId);
    final session = _activeSession;
    final value = session == null ? null : jsonEncode(session.toJson());
    final write = _sessionWrites.then((_) async {
      try {
        final prefs = await _preferences();
        if (value == null) {
          await prefs.remove(key);
        } else {
          await prefs.setString(key, value);
        }
      } catch (_) {
        // The current session remains valid in memory for this app run.
      }
    });
    _sessionWrites = write;
    await write;
  }

  RoutineSessionState? sessionFor(String routineId, {RoutineConfig? config}) {
    final session = resumableSessionAt(DateTime.now(), config: config);
    if (session == null || session.routineId != routineId) return null;
    return session;
  }

  bool isCompletedForPeriod(RoutineConfig config, DateTime now) {
    final start = RoutineLaunchPolicy.periodStart(now, config.type);
    final end = RoutineLaunchPolicy.periodEnd(now, config.type);
    return _logs.any((log) =>
        log.routineId == config.id &&
        routineActivity(log) == 'routine' &&
        !log.completedAt.isBefore(start) &&
        log.completedAt.isBefore(end) &&
        !log.completedAt.isAfter(now));
  }

  RoutineLaunch? eligibleRoutineAt(DateTime now, {bool scheduledOnly = true}) =>
      RoutineLaunchPolicy.choose(
          now: now,
          routines: allRoutines,
          session: resumableSessionAt(now),
          completed: (config) => isCompletedForPeriod(config, now),
          scheduledOnly: scheduledOnly);

  Future<RoutineLaunch?> claimStartupRoutine({DateTime? now}) async {
    final version = _identityVersion;
    final userId = _activeUserId;
    RoutineLaunch? result;
    final claim = _startupClaims.then((_) async {
      await startupReady;
      if (version != _identityVersion ||
          _disposed ||
          !_hasLoadedHistory ||
          _configurationError != null ||
          _errorMessage != null) {
        return;
      }
      final time = now ?? DateTime.now();
      final key = RoutineLaunchPolicy.offerKey(time);
      if (_startupOffers.contains(key)) return;
      final launch = eligibleRoutineAt(time);
      if (launch == null) return;
      try {
        final prefs = await _preferences();
        if (version != _identityVersion) return;
        final offers = [..._startupOffers, key];
        final kept =
            offers.skip((offers.length - 12).clamp(0, offers.length)).toList();
        if (!await prefs.setStringList(_startupKey(userId), kept)) return;
        if (version != _identityVersion) return;
        _startupOffers
          ..clear()
          ..addAll(kept);
        result = launch;
      } catch (_) {
        // Home remains usable if offer tracking cannot be persisted.
      }
    });
    _startupClaims = claim;
    await claim;
    return result;
  }

  void startRoutineSession(String routineId) {
    _sessionVersion++;
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
    _sessionVersion++;
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
    _sessionVersion++;
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
            _routines.containsKey(log.routineId) &&
            routineActivity(log) == 'routine' &&
            _isSameDay(log.completedAt, now))
        .map((log) => log.routineId)
        .toSet()
        .length;
  }

  int get streakDays => WellnessStreak.fromDates(
        _logs
            .where((log) => routineActivity(log) == 'routine')
            .map((log) => log.completedAt),
      ).current;
  bool isRoutineCompletedToday(RoutineType type) {
    return isRoutineCompletedTodayById(type.name);
  }

  bool isRoutineCompletedTodayById(String routineId) {
    final now = DateTime.now();
    return _logs.any((log) =>
        log.routineId == routineId &&
        routineActivity(log) == 'routine' &&
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

  Future<void> fetchRoutineLogs() {
    _historyReady = _fetchRoutineLogs();
    return _historyReady;
  }

  Future<void> _fetchRoutineLogs() async {
    final version = _identityVersion;
    _hasLoadedHistory = false;
    _errorMessage = null;
    if (OfflineMode.storesLocally) {
      try {
        final stored = await _local.load(OfflineMode.scope, strict: true);
        if (version != _identityVersion || _disposed) return;
        _logs
          ..clear()
          ..addAll(stored)
          ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
        _hasLoadedHistory = true;
      } catch (_) {
        if (version == _identityVersion) {
          _errorMessage = 'We could not refresh routine history.';
        }
      } finally {
        if (version == _identityVersion) {
          _isLoading = false;
          notifyListeners();
        }
      }
      return;
    }
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
      if (version != _identityVersion || _disposed) return;

      final List data = response as List;
      _logs.clear();
      _logs.addAll(data.map((e) => RoutineLog.fromMap(e)).toList());
      _logs.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      _hasLoadedHistory = true;
      notifyListeners();
    } catch (e) {
      if (version != _identityVersion || _disposed) return;
      _errorMessage = 'We could not refresh routine history.';
      ApiLogger.logDatabase(
        operation: 'SELECT',
        table: 'routine_logs',
        error: e.toString(),
      );
      notifyListeners();
    } finally {
      if (version == _identityVersion) {
        _isLoading = false;
        notifyListeners();
      }
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
      _editedRoutineIds.add(routineId);
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
      _editedRoutineIds.add(routineId);
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
      _editedRoutineIds.add(routineId);
      final updatedSteps = routine.steps.where((s) => s.id != stepId).toList();
      _routines[routineId] = routine.copyWith(steps: updatedSteps);
      clearRoutineSession(routineId);
      unawaited(_persistRoutineConfigs());
      notifyListeners();
    }
  }

  void reorderSteps(String routineId, int oldIndex, int newIndex) {
    final routine = _routines[routineId];
    if (routine != null &&
        oldIndex >= 0 &&
        oldIndex < routine.steps.length &&
        newIndex >= 0 &&
        newIndex < routine.steps.length) {
      _editedRoutineIds.add(routineId);
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
      _editedRoutineIds.add(routineId);
      _routines[routineId] = routine.copyWith(reminderTime: time);
      unawaited(_persistRoutineConfigs());
      notifyListeners();
    }
  }

  void toggleRoutineEnabled(String routineId) {
    final routine = _routines[routineId];
    if (routine != null) {
      _editedRoutineIds.add(routineId);
      _routines[routineId] = routine.copyWith(isEnabled: !routine.isEnabled);
      if (routine.isEnabled) clearRoutineSession(routineId);
      unawaited(_persistRoutineConfigs());
      notifyListeners();
    }
  }

  void addCustomRoutine(RoutineConfig routine) {
    _editedRoutineIds.add(routine.id);
    _routines[routine.id] = routine;
    unawaited(_persistRoutineConfigs());
    notifyListeners();
  }

  void deleteCustomRoutine(String routineId) {
    if (_routines.containsKey(routineId) &&
        routineId != 'morning' &&
        routineId != 'midday' &&
        routineId != 'night') {
      _editedRoutineIds.add(routineId);
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

    if (OfflineMode.storesLocally) {
      _isLoading = true;
      notifyListeners();
      final stored = await _local.upsert(OfflineMode.scope, finalLog);
      if (stored) {
        _logs.removeWhere((item) => item.id == finalLog.id);
        _logs.insert(0, finalLog);
        _logs.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      } else {
        _errorMessage = 'Routine completion could not be saved to this device.';
      }
      _isLoading = false;
      notifyListeners();
      return stored;
    }

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
    if (OfflineMode.storesLocally) {
      final index = _logs.indexWhere((log) => log.id == updated.id);
      if (index == -1) {
        _errorMessage = 'This saved item is no longer available.';
        notifyListeners();
        return false;
      }
      final previous = _logs[index];
      _logs[index] = updated;
      _logs.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      final stored = await _local.upsert(OfflineMode.scope, updated);
      if (!stored) {
        final restored = _logs.indexWhere((log) => log.id == updated.id);
        if (restored != -1) _logs[restored] = previous;
        _errorMessage = 'Your changes could not be saved to this device.';
      }
      notifyListeners();
      return stored;
    }
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
    if (OfflineMode.storesLocally) {
      final index = _logs.indexWhere((log) => log.id == id);
      if (index == -1) return true;
      final removed = _logs.removeAt(index);
      notifyListeners();
      final cleared = await _local.remove(OfflineMode.scope, id);
      if (!cleared) {
        _logs.insert(index.clamp(0, _logs.length), removed);
        _errorMessage =
            'The routine log could not be deleted. It has been restored.';
        notifyListeners();
      }
      return cleared;
    }
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
