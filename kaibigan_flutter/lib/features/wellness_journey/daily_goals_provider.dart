import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/supabase_service.dart';

class DailyGoalItem {
  final String id;
  final String title;
  final String icon;
  final String goalType;
  bool isCompleted;

  DailyGoalItem(
      {required this.id,
      required this.title,
      required this.icon,
      required this.goalType,
      this.isCompleted = false});

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'icon': icon,
        'goalType': goalType,
        'isCompleted': isCompleted
      };

  factory DailyGoalItem.fromMap(Map<String, dynamic> map) => DailyGoalItem(
        id: map['id'] as String,
        title: map['title'] as String,
        icon: map['icon'] as String,
        goalType: map['goalType'] as String,
        isCompleted: map['isCompleted'] as bool? ?? false,
      );
}

class DailyGoalsProvider extends ChangeNotifier {
  final List<DailyGoalItem> _goals = [];
  String? _activeUserId;

  DailyGoalsProvider() {
    syncForCurrentUser();
  }

  List<DailyGoalItem> get goals => List.unmodifiable(_goals);
  int get completedCount => _goals.where((g) => g.isCompleted).length;
  double get completionRate =>
      _goals.isEmpty ? 0.0 : completedCount / _goals.length;

  List<DailyGoalItem> _defaultGoals() => [
        DailyGoalItem(
            id: 'g-1',
            title: 'Drink a glass of water',
            icon: '💧',
            goalType: 'hydration'),
        DailyGoalItem(
            id: 'g-2',
            title: 'Spend 5 minutes outside in sunlight',
            icon: '☀️',
            goalType: 'sunlight'),
        DailyGoalItem(
            id: 'g-3',
            title: 'Write 3 things you\'re grateful for',
            icon: '🌸',
            goalType: 'gratitude'),
        DailyGoalItem(
            id: 'g-4',
            title: 'Take 5 gentle deep breaths',
            icon: '🌬️',
            goalType: 'breathing'),
      ];

  String _storageKey(String userId) {
    final now = DateTime.now();
    final day =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'daily_goals_${userId}_$day';
  }

  void syncForCurrentUser() {
    final userId = SupabaseService.isInitialized
        ? SupabaseService.client.auth.currentUser?.id
        : null;
    if (userId == _activeUserId) return;
    _activeUserId = userId;
    _goals.clear();
    notifyListeners();
    if (userId != null) _loadGoals(userId);
  }

  Future<void> _loadGoals(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey(userId));
    if (_activeUserId != userId) return;
    _goals
      ..clear()
      ..addAll(saved == null
          ? _defaultGoals()
          : (jsonDecode(saved) as List<dynamic>).map(
              (item) => DailyGoalItem.fromMap(item as Map<String, dynamic>)));
    notifyListeners();
  }

  Future<void> _saveGoals() async {
    final userId = _activeUserId;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey(userId),
        jsonEncode(_goals.map((goal) => goal.toMap()).toList()));
  }

  void toggleGoal(String id) {
    final index = _goals.indexWhere((g) => g.id == id);
    if (index == -1) return;
    _goals[index].isCompleted = !_goals[index].isCompleted;
    notifyListeners();
    _saveGoals();
  }

  void addGoal(String title, String icon) {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return;
    _goals.add(DailyGoalItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: cleanTitle,
        icon: icon,
        goalType: 'custom'));
    notifyListeners();
    _saveGoals();
  }

  void resetGoals() {
    for (final goal in _goals) {
      goal.isCompleted = false;
    }
    notifyListeners();
    _saveGoals();
  }
}
