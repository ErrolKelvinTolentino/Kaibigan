import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/supabase_service.dart';

class ActivityUsageStore {
  static const _loginDatesKey = 'user_daily_login_dates_v1';
  static const _activityCountsKey = 'user_activity_usage_counts_v1';
  static const _pinnedFavoritesKey = 'user_pinned_favorites_v1';
  static const _maxStoredDays = 90;

  /// Records today's login in SharedPreferences and synchronizes with Supabase if online.
  static Future<void> recordTodayLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _formatDate(DateTime.now());
    final raw = prefs.getStringList(_loginDatesKey) ?? [];
    final set = raw.toSet()..add(todayStr);
    final sorted = set.toList()..sort();
    final trimmed = sorted.length > _maxStoredDays
        ? sorted.sublist(sorted.length - _maxStoredDays)
        : sorted;
    await prefs.setStringList(_loginDatesKey, trimmed);
    _syncToSupabase();
  }

  /// Loads all stored login dates as [DateTime] normalized to year-month-day.
  static Future<Set<DateTime>> loadLoginDates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_loginDatesKey) ?? [];
    final dates = <DateTime>{};
    for (final str in raw) {
      final parsed = _parseDate(str);
      if (parsed != null) {
        dates.add(parsed);
      }
    }
    // Also include today's date
    final now = DateTime.now();
    dates.add(DateTime(now.year, now.month, now.day));
    return dates;
  }

  /// Increments the usage count for a given activity ID and synchronizes with Supabase.
  static Future<void> incrementActivityUsage(String activityId) async {
    final prefs = await SharedPreferences.getInstance();
    final counts = await loadActivityCounts();
    counts[activityId] = (counts[activityId] ?? 0) + 1;
    await prefs.setString(_activityCountsKey, jsonEncode(counts));
    _syncToSupabase();
  }

  /// Loads the activity click counts.
  static Future<Map<String, int>> loadActivityCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activityCountsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      );
    } catch (_) {
      return {};
    }
  }

  /// Loads pinned favorite activity IDs.
  static Future<List<String>> loadPinnedFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_pinnedFavoritesKey) ?? [];
  }

  /// Saves pinned favorite activity IDs.
  static Future<void> savePinnedFavorites(List<String> pinned) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_pinnedFavoritesKey, pinned);
    _syncToSupabase();
  }

  /// Synchronizes local activity stats with Supabase database (bi-directional merge).
  static Future<void> syncWithSupabase() async {
    if (!SupabaseService.isInitialized) return;
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      final res = await SupabaseService.client
          .from('user_activity_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      final prefs = await SharedPreferences.getInstance();

      // Local data
      final localLoginDates = prefs.getStringList(_loginDatesKey) ?? [];
      final localCounts = await loadActivityCounts();
      final localPinned = await loadPinnedFavorites();

      if (res != null) {
        // Merge remote login dates
        final remoteDates = List<String>.from(res['login_dates'] ?? []);
        final mergedDates = (localLoginDates.toSet()..addAll(remoteDates)).toList()..sort();
        final trimmedDates = mergedDates.length > _maxStoredDays
            ? mergedDates.sublist(mergedDates.length - _maxStoredDays)
            : mergedDates;
        await prefs.setStringList(_loginDatesKey, trimmedDates);

        // Merge activity counts (max of local and remote count)
        final remoteCounts = Map<String, dynamic>.from(res['activity_counts'] ?? {});
        final mergedCounts = Map<String, int>.from(localCounts);
        for (final entry in remoteCounts.entries) {
          final count = (entry.value as num?)?.toInt() ?? 0;
          mergedCounts[entry.key] = (mergedCounts[entry.key] ?? 0) > count
              ? mergedCounts[entry.key]!
              : count;
        }
        await prefs.setString(_activityCountsKey, jsonEncode(mergedCounts));

        // Merge pinned favorites
        final remotePinned = List<String>.from(res['pinned_favorites'] ?? []);
        if (localPinned.isEmpty && remotePinned.isNotEmpty) {
          await prefs.setStringList(_pinnedFavoritesKey, remotePinned);
        }

        // Push merged state back to remote
        await SupabaseService.client.from('user_activity_stats').upsert({
          'user_id': userId,
          'login_dates': trimmedDates,
          'activity_counts': mergedCounts,
          'pinned_favorites': localPinned.isNotEmpty ? localPinned : remotePinned,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        // No remote row yet: insert local stats
        await SupabaseService.client.from('user_activity_stats').insert({
          'user_id': userId,
          'login_dates': localLoginDates,
          'activity_counts': localCounts,
          'pinned_favorites': localPinned,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error syncing activity stats with Supabase: $e');
    }
  }

  static void _syncToSupabase() {
    syncWithSupabase().catchError((e) {
      debugPrint('Background activity stats sync error: $e');
    });
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime? _parseDate(String str) {
    final parts = str.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }
}
