import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/uuid_helper.dart';
import 'mood_model.dart';

class MoodProvider extends ChangeNotifier {
  final List<MoodLog> _logs = [];
  bool _isLoading = false;

  List<MoodLog> get logs => List.unmodifiable(_logs);
  bool get isLoading => _isLoading;

  double get averageWeeklyScore {
    if (_logs.isEmpty) return 4.0;
    final recent = _logs.take(7);
    final total = recent.fold(0, (sum, item) => sum + item.moodScore);
    return total / recent.length;
  }

  EmotionalWeatherInfo get currentEmotionalWeather =>
      EmotionalWeatherInfo.getWeatherForScore(averageWeeklyScore);

  MoodProvider() {
    _initSampleData();
    fetchMoodLogs();
  }

  void _initSampleData() {
    final now = DateTime.now();
    _logs.addAll([
      MoodLog(id: UuidHelper.generateV4(), moodScore: 4, moodLabel: 'Good', stressLevel: 2, energyLevel: 4, sleepQuality: 4, anxietyLevel: 2, note: 'Had a smooth day!', createdAt: now.subtract(const Duration(days: 6))),
      MoodLog(id: UuidHelper.generateV4(), moodScore: 3, moodLabel: 'Okay', stressLevel: 3, energyLevel: 3, sleepQuality: 3, anxietyLevel: 3, note: 'School deadlines.', createdAt: now.subtract(const Duration(days: 5))),
      MoodLog(id: UuidHelper.generateV4(), moodScore: 5, moodLabel: 'Awesome', stressLevel: 1, energyLevel: 5, sleepQuality: 5, anxietyLevel: 1, note: 'Great conversation with companion!', createdAt: now.subtract(const Duration(days: 4))),
      MoodLog(id: UuidHelper.generateV4(), moodScore: 4, moodLabel: 'Good', stressLevel: 2, energyLevel: 4, sleepQuality: 4, anxietyLevel: 2, note: 'Gardening time.', createdAt: now.subtract(const Duration(days: 3))),
      MoodLog(id: UuidHelper.generateV4(), moodScore: 3, moodLabel: 'Okay', stressLevel: 3, energyLevel: 3, sleepQuality: 3, anxietyLevel: 3, note: 'Resting early.', createdAt: now.subtract(const Duration(days: 2))),
      MoodLog(id: UuidHelper.generateV4(), moodScore: 4, moodLabel: 'Good', stressLevel: 2, energyLevel: 4, sleepQuality: 4, anxietyLevel: 2, note: 'Felt calm and present.', createdAt: now.subtract(const Duration(days: 1))),
      MoodLog(id: UuidHelper.generateV4(), moodScore: 5, moodLabel: 'Awesome', stressLevel: 1, energyLevel: 5, sleepQuality: 5, anxietyLevel: 1, note: 'Poured heart out in journal.', createdAt: now),
    ]);
  }

  Future<void> fetchMoodLogs() async {
    if (!SupabaseService.isInitialized) return;
    _isLoading = true;
    notifyListeners();

    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      var query = SupabaseService.client.from('mood_logs').select();
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      final response = await query.order('created_at', ascending: false);

      final List data = response as List;
      _logs.clear();
      _logs.addAll(data.map((e) => MoodLog.fromMap(e)).toList());
    } catch (e) {
      print("Error fetching mood logs from Supabase: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<MoodLog> logMood({
    required int score,
    required String label,
    int stress = 3,
    int energy = 3,
    int sleep = 3,
    int anxiety = 3,
    String? note,
  }) async {
    _isLoading = true;
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

    _logs.insert(0, newLog);

    if (SupabaseService.isInitialized) {
      try {
        final userId = SupabaseService.client.auth.currentUser?.id;
        await SupabaseService.client
            .from('mood_logs')
            .insert(newLog.toMap(userId: userId));
      } catch (e) {
        print("Error saving mood log to Supabase: $e");
      }
    }

    _isLoading = false;
    notifyListeners();
    return newLog;
  }

  Future<void> updateMoodLog(MoodLog updated) async {
    final index = _logs.indexWhere((l) => l.id == updated.id);
    if (index != -1) {
      _logs[index] = updated;
      notifyListeners();

      if (SupabaseService.isInitialized && UuidHelper.isValidUuid(updated.id)) {
        try {
          final userId = SupabaseService.client.auth.currentUser?.id;
          await SupabaseService.client
              .from('mood_logs')
              .update(updated.toMap(userId: userId))
              .eq('id', updated.id);
        } catch (e) {
          print("Error updating mood log in Supabase: $e");
        }
      }
    }
  }

  Future<void> deleteMoodLog(String id) async {
    _logs.removeWhere((l) => l.id == id);
    notifyListeners();

    if (SupabaseService.isInitialized && UuidHelper.isValidUuid(id)) {
      try {
        await SupabaseService.client
            .from('mood_logs')
            .delete()
            .eq('id', id);
      } catch (e) {
        print("Error deleting mood log: $e");
      }
    }
  }
}
