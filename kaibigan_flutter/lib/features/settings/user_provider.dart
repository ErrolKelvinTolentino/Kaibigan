import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  String _displayName = "Errol";
  String _selectedCompanion = "kai"; // 'kai', 'ann', 'bee'
  String _preferredLanguage = "taglish"; // 'taglish', 'filipino', 'english'
  bool _isDarkMode = false;

  String get displayName => _displayName;
  String get selectedCompanion => _selectedCompanion;
  String get preferredLanguage => _preferredLanguage;
  bool get isDarkMode => _isDarkMode;

  UserProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _displayName = prefs.getString('display_name') ?? "Errol";
    _selectedCompanion = prefs.getString('selected_companion') ?? "kai";
    _preferredLanguage = prefs.getString('preferred_language') ?? "taglish";
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    notifyListeners();
  }

  Future<void> setCompanion(String companionId) async {
    _selectedCompanion = companionId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_companion', companionId);
  }

  Future<void> setLanguage(String lang) async {
    _preferredLanguage = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_language', lang);
  }

  Future<void> toggleDarkMode(bool val) async {
    _isDarkMode = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', val);
  }

  Future<void> updateDisplayName(String name) async {
    _displayName = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('display_name', name);
  }
}
