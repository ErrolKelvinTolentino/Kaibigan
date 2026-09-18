import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/api_logger.dart';
import '../../core/utils/uuid_helper.dart';
import 'mood_model.dart';

class MoodProvider extends ChangeNotifier {
  final List<MoodLog> _logs = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _activeUserId;

  List<MoodLog> get logs => List.unmodifiable(
      List<MoodLog>.of(_logs)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
  );
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// The mean mood of the last seven calendar days, or null when nothing
  /// inside that window was logged.
  ///
  /// Each logged day counts once, matching how the insights screens read the
  /// same data: a day with four check-ins is still one day. Days with
  /// nothing saved are left out rather than counted as low.
  double? get weeklyMoodAverage {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(today.year, today.month, today.day - 6);
    final byDay = <DateTime, List<int>>{};
    for (final log in _logs) {
      if (log.moodScore < 1 || log.moodScore > 5) continue;
      final local = log.createdAt.toLocal();
      if (local.isAfter(now)) continue;
      final day = DateTime(local.year, local.month, local.day);
      if (day.isBefore(start) || day.isAfter(today)) continue;
      byDay.putIfAbsent(day, () => []).add(log.moodScore);
    }
    if (byDay.isEmpty) return null;
    final daily = byDay.values
        .map((scores) => scores.reduce((a, b) => a + b) / scores.length)
        .toList();
    return daily.reduce((a, b) => a + b) / daily.length;
  }

  /// Zero when the window holds nothing, for callers that cannot take a
  /// null. Prefer [weeklyMoodAverage] so an empty week is not drawn as a
  /// terrible one.
  double get averageWeeklyScore => weeklyMoodAverage ?? 0;

  EmotionalWeatherInfo get currentEmotionalWeather =>
      EmotionalWeatherInfo.getWeatherForScore(averageWeeklyScore);

  /// [initialLogs] and [syncOnCreate] mirror [RoutinesProvider], so a screen
  /// or a reading can be exercised against known history without a backend.
  MoodProvider({
    Iterable<MoodLog> initialLogs = const [],
    bool syncOnCreate = true,
  }) {
    _logs.addAll(initialLogs);
    if (syncOnCreate) syncForCurrentUser();
  }

  void syncForCurrentUser() {
    final userId = SupabaseService.isInitialized
        ? SupabaseService.client.auth.currentUser?.id
        : null;
    if (userId == _activeUserId) return;
    _activeUserId = userId;
    _logs.clear();
    _errorMessage = null;
    notifyListeners();
    if (userId != null) fetchMoodLogs();
  }

  Future<void> fetchMoodLogs() async {
    _errorMessage = null;
    if (!SupabaseService.isInitialized) {
      _errorMessage =
          'Mood sync is unavailable. Check the app configuration and try again.';
      notifyListeners();
      return;
    }
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final query = SupabaseService.client
          .from('mood_logs')
          .select()
          .eq('user_id', userId);
      final response = await query.order('created_at', ascending: false);

      final List data = response as List;
      _logs.clear();
      _logs.addAll(data.map((e) => MoodLog.fromMap(e)).toList());
      _logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      ApiLogger.logDatabase(
        operation: 'SELECT',
        table: 'mood_logs',
        payload: {'user_id': userId, 'order': 'created_at DESC'},
        result: {
          'count': data.length,
          'sample': data.isNotEmpty ? data.first : null
        },
      );
    } catch (e) {
      _errorMessage =
          'We could not refresh your mood history. Please try again.';
      ApiLogger.logDatabase(
        operation: 'SELECT',
        table: 'mood_logs',
        error: e.toString(),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<MoodLog?> logMood({
    required int score,
    required String label,
    int stress = 3,
    int energy = 3,
    int sleep = 3,
    int anxiety = 3,
    String? note,
  }) async {
    if (score < 1 || score > 5 || label.trim().isEmpty) {
      _errorMessage = 'Choose a valid mood before saving your check-in.';
      notifyListeners();
      return null;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final newLog = MoodLog(
      id: UuidHelper.generateV4(),
      moodScore: score,
      moodLabel: label,
      stressLevel: stress,
      energyLevel: energy,
      sleepQuality: sleep,
      anxietyLevel: anxiety,
      note: note,
      createdAt: DateTime.now(),
    );

    var saved = false;
    if (SupabaseService.isInitialized &&
        SupabaseService.client.auth.currentUser != null) {
      try {
        final userId = SupabaseService.client.auth.currentUser!.id;
        final map = newLog.toMap(userId: userId);
        await SupabaseService.client.from('mood_logs').insert(map);
        saved = true;

        ApiLogger.logDatabase(
          operation: 'INSERT',
          table: 'mood_logs',
          payload: map,
          result: {'status': 'success', 'id': newLog.id},
        );
      } catch (e) {
        _errorMessage =
            'Your mood check-in could not be saved. Please try again.';
        ApiLogger.logDatabase(
          operation: 'INSERT',
          table: 'mood_logs',
          error: e.toString(),
        );
      }
    } else {
      _errorMessage =
          'Your mood check-in could not be saved because sync is unavailable.';
    }

    if (saved) {
      _logs.removeWhere((l) => l.id == newLog.id);
      _logs.insert(0, newLog);
      _logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    _isLoading = false;
    notifyListeners();
    return saved ? newLog : null;
  }

  Future<bool> updateMoodLog(MoodLog updated) async {
    _errorMessage = null;
    if (updated.moodScore < 1 ||
        updated.moodScore > 5 ||
        updated.moodLabel.trim().isEmpty) {
      _errorMessage = 'This mood check-in contains invalid values.';
      notifyListeners();
      return false;
    }
    if (!SupabaseService.isInitialized ||
        SupabaseService.client.auth.currentUser == null) {
      _errorMessage =
          'Your mood update could not be saved because sync is unavailable.';
      notifyListeners();
      return false;
    }
    final index = _logs.indexWhere((l) => l.id == updated.id);
    if (index != -1) {
      final previous = _logs[index];
      _logs[index] = updated;
      _logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();

      if (SupabaseService.isInitialized && UuidHelper.isValidUuid(updated.id)) {
        try {
          final userId = SupabaseService.client.auth.currentUser?.id;
          final map = updated.toMap(userId: userId);
          await SupabaseService.client
              .from('mood_logs')
              .update(map)
              .eq('id', updated.id)
              .eq('user_id', userId!)
              .select()
              .single();

          ApiLogger.logDatabase(
            operation: 'UPDATE',
            table: 'mood_logs',
            payload: map,
            result: {'status': 'success', 'id': updated.id},
          );
        } catch (e) {
          _logs[index] = previous;
          _errorMessage = 'Your mood update could not be saved.';
          ApiLogger.logDatabase(
            operation: 'UPDATE',
            table: 'mood_logs',
            error: e.toString(),
          );
        }
      }
      notifyListeners();
      return _errorMessage == null;
    }
    _errorMessage = 'This mood check-in is no longer available.';
    notifyListeners();
    return false;
  }

  Future<bool> deleteMoodLog(String id) async {
    _errorMessage = null;
    if (!SupabaseService.isInitialized ||
        SupabaseService.client.auth.currentUser == null) {
      _errorMessage =
          'The mood log could not be deleted because sync is unavailable.';
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
            .from('mood_logs')
            .delete()
            .eq('id', id)
            .eq('user_id', userId)
            .select()
            .single();

        ApiLogger.logDatabase(
          operation: 'DELETE',
          table: 'mood_logs',
          payload: {'id': id},
          result: {'status': 'success', 'id': id},
        );
      } catch (e) {
        _logs.insert(index.clamp(0, _logs.length), removed);
        _errorMessage =
            'The mood log could not be deleted. It has been restored.';
        ApiLogger.logDatabase(
          operation: 'DELETE',
          table: 'mood_logs',
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
