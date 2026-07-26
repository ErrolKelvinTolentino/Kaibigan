import 'package:flutter/material.dart';

class DailyGoalItem {
  final String id;
  final String title;
  final String icon;
  final String goalType;
  bool isCompleted;

  DailyGoalItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.goalType,
    this.isCompleted = false,
  });
}

class DailyGoalsProvider extends ChangeNotifier {
  final List<DailyGoalItem> _goals = [
    DailyGoalItem(id: 'g-1', title: 'Drink a glass of water', icon: '💧', goalType: 'hydration', isCompleted: true),
    DailyGoalItem(id: 'g-2', title: 'Spend 5 minutes outside in sunlight', icon: '☀️', goalType: 'sunlight', isCompleted: false),
    DailyGoalItem(id: 'g-3', title: 'Write 3 things you\'re grateful for', icon: '🌸', goalType: 'gratitude', isCompleted: true),
    DailyGoalItem(id: 'g-4', title: 'Take 5 gentle deep breaths', icon: '🌬️', goalType: 'breathing', isCompleted: false),
  ];

  List<DailyGoalItem> get goals => List.unmodifiable(_goals);

  int get completedCount => _goals.where((g) => g.isCompleted).length;
  double get completionRate => _goals.isEmpty ? 0.0 : completedCount / _goals.length;

  void toggleGoal(String id) {
    final index = _goals.indexWhere((g) => g.id == id);
    if (index != -1) {
      _goals[index].isCompleted = !_goals[index].isCompleted;
      notifyListeners();
    }
  }

  void addGoal(String title, String icon) {
    _goals.add(DailyGoalItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      icon: icon,
      goalType: 'custom',
      isCompleted: false,
    ));
    notifyListeners();
  }

  void resetGoals() {
    for (var goal in _goals) {
      goal.isCompleted = false;
    }
    notifyListeners();
  }
}
