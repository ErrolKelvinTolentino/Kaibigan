import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/supabase_service.dart';

typedef LessonRecords = Map<String, Map<String, dynamic>>;

abstract class LearningProgressCloud {
  Future<List<Map<String, dynamic>>> fetch(String userId);
  Future<void> save(String userId, String lessonId, Map<String, dynamic> patch);
}

class SupabaseLearningProgressCloud implements LearningProgressCloud {
  void _checkOwner(String userId) {
    if (!SupabaseService.isInitialized ||
        SupabaseService.client.auth.currentUser?.id != userId) {
      throw StateError('Learning progress owner changed.');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetch(String userId) async {
    _checkOwner(userId);
    final rows = await SupabaseService.client
        .from('learning_progress')
        .select()
        .eq('user_id', userId);
    _checkOwner(userId);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<void> save(
    String userId,
    String lessonId,
    Map<String, dynamic> patch,
  ) async {
    _checkOwner(userId);
    await SupabaseService.client.from('learning_progress').upsert({
      ...patch,
      'user_id': userId,
      'lesson_id': lessonId,
    }, onConflict: 'user_id,lesson_id');
  }
}

/// Account-scoped cache with a durable retry queue. Old unscoped preferences
/// are never uploaded: their owner cannot be established safely.
class LearningProgressSync {
  LearningProgressSync({
    LearningProgressCloud? cloud,
    String? Function()? currentUserId,
  })  : _cloud = cloud ?? SupabaseLearningProgressCloud(),
        _currentUserId = currentUserId ?? _signedInUser;

  final LearningProgressCloud _cloud;
  final String? Function() _currentUserId;
  String? _loadedUser;
  static Future<void> _queue = Future<void>.value();

  static String? _signedInUser() => SupabaseService.isInitialized
      ? SupabaseService.client.auth.currentUser?.id
      : null;

  String? get userId => _currentUserId();

  Future<T> _serial<T>(Future<T> Function() operation) {
    final next = _queue.then((_) => operation());
    _queue = next.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return next;
  }

  LessonRecords _decode(String? raw) {
    if (raw == null) return {};
    try {
      final value = jsonDecode(raw) as Map<String, dynamic>;
      return value.map(
          (key, row) => MapEntry(key, Map<String, dynamic>.from(row as Map)));
    } catch (_) {
      return {};
    }
  }

  Future<LessonRecords> load(String owner) => _serial(() => _load(owner));

  Future<LessonRecords> _load(String owner) async {
    if (userId != owner) return {};
    final prefs = await SharedPreferences.getInstance();
    var records = _decode(prefs.getString('learning_progress_v1_$owner'));
    final pending =
        _decode(prefs.getString('learning_progress_pending_v1_$owner'));
    for (final item in pending.entries) {
      records[item.key] = {...?records[item.key], ...item.value};
    }
    if (_loadedUser != owner) {
      try {
        final rows =
            await _cloud.fetch(owner).timeout(const Duration(seconds: 8));
        if (userId != owner) return {};
        records = {
          for (final row in rows) row['lesson_id'] as String: row,
        };
        for (final item in pending.entries) {
          records[item.key] = {...?records[item.key], ...item.value};
        }
        _loadedUser = owner;
      } catch (_) {
        // Offline and not-yet-migrated databases retain local progress.
      }
    }
    if (userId != owner) return {};
    // Recover a pending-first write even when its cache write was interrupted.
    await prefs.setString('learning_progress_v1_$owner', jsonEncode(records));
    await _flush(owner, prefs, pending);
    return userId == owner ? records : {};
  }

  Future<LessonRecords> change(
    String owner,
    String lessonId,
    Map<String, dynamic> Function(Map<String, dynamic> current) update,
  ) =>
      _serial(() async {
        final records = await _load(owner);
        if (userId != owner) return <String, Map<String, dynamic>>{};
        final patch = update(records[lessonId] ?? {});
        final prefs = await SharedPreferences.getInstance();
        final pending = _decode(
          prefs.getString('learning_progress_pending_v1_$owner'),
        );
        records[lessonId] = {...?records[lessonId], ...patch};
        pending[lessonId] = {...?pending[lessonId], ...patch};
        // Persist pending changes first so an interrupted write can be retried.
        await prefs.setString(
          'learning_progress_pending_v1_$owner',
          jsonEncode(pending),
        );
        await prefs.setString(
          'learning_progress_v1_$owner',
          jsonEncode(records),
        );
        await _flush(owner, prefs, pending);
        return userId == owner ? records : <String, Map<String, dynamic>>{};
      });

  Future<void> _flush(
    String owner,
    SharedPreferences prefs,
    LessonRecords pending,
  ) async {
    for (final lessonId in pending.keys.toList()) {
      if (userId != owner) return;
      try {
        await _cloud
            .save(owner, lessonId, pending[lessonId]!)
            .timeout(const Duration(seconds: 8));
        pending.remove(lessonId);
        await prefs.setString(
          'learning_progress_pending_v1_$owner',
          jsonEncode(pending),
        );
      } catch (_) {
        return;
      }
    }
  }
}
