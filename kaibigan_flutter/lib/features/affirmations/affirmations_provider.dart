import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'affirmation_model.dart';

class AffirmationsProvider extends ChangeNotifier {
  static const _categoryKey = 'affirmation_category_id';

  String? _selectedCategoryId;
  bool _isLoaded = false;
  late final Future<void> ready;

  AffirmationsProvider() {
    ready = _load();
  }

  bool get isLoaded => _isLoaded;
  String? get selectedCategoryId => _selectedCategoryId;
  AffirmationCategory? get selectedCategory =>
      AffirmationCatalog.byId(_selectedCategoryId);

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_categoryKey);
    _selectedCategoryId = AffirmationCatalog.byId(stored)?.id;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> selectCategory(String categoryId) async {
    final category = AffirmationCatalog.byId(categoryId);
    if (category == null || category.id == _selectedCategoryId) return;
    _selectedCategoryId = category.id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_categoryKey, category.id);
  }

  String? affirmationForDay(
    DateTime date, {
    String language = 'english',
  }) {
    final category = selectedCategory;
    if (category == null) return null;
    return _affirmationFor(category, date, language);
  }

  String homeAffirmationForDay(
    DateTime date, {
    String language = 'english',
  }) {
    final category = selectedCategory ?? AffirmationCatalog.categories.first;
    return _affirmationFor(category, date, language);
  }

  String _affirmationFor(
    AffirmationCategory category,
    DateTime date,
    String language,
  ) {
    final localDay = DateTime(date.year, date.month, date.day);
    final dayNumber =
        localDay.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    final salt = AffirmationCatalog.categories.indexOf(category) * 7;
    final affirmations = category.affirmationsFor(language);
    return affirmations[(dayNumber + salt) % affirmations.length];
  }
}
