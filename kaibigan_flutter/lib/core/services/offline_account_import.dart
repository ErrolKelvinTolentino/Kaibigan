import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/uuid_helper.dart';
import 'supabase_service.dart';

abstract class OfflineImportCloud {
  Future<List<Map<String, dynamic>>> fetch(String table, String owner);
  Future<void> save(String table, List<Map<String, dynamic>> rows);
}

class SupabaseOfflineImportCloud implements OfflineImportCloud {
  void _check(String owner) {
    if (!SupabaseService.isInitialized ||
        SupabaseService.client.auth.currentUser?.id != owner) {
      throw StateError('The signed-in account changed.');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetch(String table, String owner) async {
    _check(owner);
    final rows = await SupabaseService.client
        .from(table)
        .select()
        .eq('user_id', owner)
        .timeout(const Duration(seconds: 8));
    _check(owner);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<void> save(String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    final owner = rows.first['user_id'] as String;
    _check(owner);
    await SupabaseService.client
        .from(table)
        .upsert(
          rows,
          onConflict: table == 'learning_progress' ? 'user_id,lesson_id' : 'id',
          // A retry must not overwrite a journal edited after its first upload.
          ignoreDuplicates: table != 'learning_progress',
        )
        .timeout(const Duration(seconds: 8));
    _check(owner);
  }
}

/// An explicit device-to-account transfer. The durable snapshot binds to the
/// first successful sign-in, so interrupted uploads cannot go to another user.
/// Original device records remain a backup; claimed IDs are never imported twice.
class OfflineAccountImport {
  OfflineAccountImport(
      {OfflineImportCloud? cloud, String? Function()? currentUserId})
      : _cloud = cloud ?? SupabaseOfflineImportCloud(),
        _currentUserId = currentUserId ?? _signedInUser;

  static const jobKey = 'offline_account_import_v1';
  static const _claimsKey = 'offline_account_import_claims_v1';
  static const collections = [
    'journal_entries',
    'gratitude_entries',
    'mood_logs',
    'future_letters',
    'routine_logs'
  ];
  final OfflineImportCloud _cloud;
  final String? Function() _currentUserId;
  Future<bool>? _work;

  static String? _signedInUser() => SupabaseService.isInitialized
      ? SupabaseService.client.auth.currentUser?.id
      : null;

  Map<String, dynamic>? _job(SharedPreferences prefs) {
    final raw = prefs.getString(jobKey);
    return raw == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<bool> pendingFor(String? owner) async {
    final job = _job(await SharedPreferences.getInstance());
    return job != null && (job['owner'] == null || job['owner'] == owner);
  }

  Future<void> cancelPrepared() async {
    final prefs = await SharedPreferences.getInstance();
    if (_job(prefs)?['owner'] == null) await prefs.remove(jobKey);
  }

  Future<void> _write(SharedPreferences prefs, Map<String, dynamic> job) async {
    if (!await prefs.setString(jobKey, jsonEncode(job))) {
      throw StateError('The local backup could not be prepared.');
    }
  }

  /// Called only from the offline user's "back up" action, before auth changes.
  Future<void> prepare(String sourceScope) async {
    final prefs = await SharedPreferences.getInstance();
    // Preserve an in-progress transfer, including its original owner/snapshot.
    if (_job(prefs) != null) return;
    final claims = jsonDecode(prefs.getString(_claimsKey) ?? '{}') as Map;
    final tables = <String, List<Map<String, dynamic>>>{};
    for (final table in collections) {
      final raw = prefs.getString('kaibigan_local_${table}_$sourceScope');
      final rows = raw == null ? <dynamic>[] : jsonDecode(raw) as List;
      tables[table] = [];
      for (final value in rows) {
        final row = Map<String, dynamic>.from(value as Map);
        final sourceId = row['id'] as String?;
        if (sourceId == null || sourceId.isEmpty) {
          throw const FormatException('A local entry has no ID.');
        }
        if (claims.containsKey('$table/$sourceId')) continue;
        tables[table]!.add({
          ...row,
          'id': UuidHelper.isValidUuid(sourceId)
              ? sourceId
              : UuidHelper.generateV4(),
          '_source_id': sourceId
        });
      }
    }
    final lessons = _localLessons(prefs);
    tables['learning_progress'] = [
      for (final row in lessons.values)
        if (!claims.containsKey('learning_progress/${row['lesson_id']}')) row
    ];
    final configRaw = prefs.getString('routine_configurations_v1_local');
    if (tables.values.every((rows) => rows.isEmpty) && configRaw == null) {
      return;
    }
    await _write(prefs, {
      'owner': null,
      'source': sourceScope,
      'tables': tables,
      'routine_configs': configRaw == null ? null : jsonDecode(configRaw)
    });
  }

  Map<String, Map<String, dynamic>> _localLessons(SharedPreferences prefs) {
    final rows = <String, Map<String, dynamic>>{};
    Map<String, dynamic> lesson(String id) =>
        rows.putIfAbsent(id, () => {'lesson_id': id});
    for (final id
        in prefs.getStringList('mental_health_learning_completed_ids') ??
            <String>[]) {
      lesson(id)['completed'] = true;
    }
    for (final field in ['helpful', 'viewed']) {
      for (final ref
          in prefs.getStringList('mental_health_learning_${field}_ideas') ??
              <String>[]) {
        final separator = ref.lastIndexOf(':');
        if (separator < 1) continue;
        final index = int.tryParse(ref.substring(separator + 1));
        if (index == null || index < 0) continue;
        (lesson(ref.substring(0, separator))
                .putIfAbsent('${field}_ideas', () => <int>[]) as List)
            .add(index);
      }
    }
    for (final key in prefs.getKeys()) {
      const position = 'mental_health_learning_idea_position_';
      const quiz = 'friend_support_quiz_score_';
      const practice = 'friend_support_practice_count_';
      if (key.startsWith(position)) {
        lesson(key.substring(position.length))['last_idea_index'] =
            prefs.getInt(key);
      }
      if (key.startsWith(quiz)) {
        final id = key.substring(quiz.length);
        final total = prefs.getInt('friend_support_quiz_total_$id');
        final score = prefs.getInt(key);
        if (total != null &&
            score != null &&
            total > 0 &&
            score >= 0 &&
            score <= total) {
          lesson(id).addAll({'quiz_score': score, 'quiz_total': total});
        }
      }
      if (key.startsWith(practice)) {
        lesson(key.substring(practice.length))['practice_count'] =
            prefs.getInt(key);
      }
    }
    return rows;
  }

  Future<bool> sync() => _work ??= _sync().whenComplete(() => _work = null);

  Future<bool> _sync() async {
    final owner = _currentUserId();
    if (owner == null) return false;
    final prefs = await SharedPreferences.getInstance();
    final job = _job(prefs);
    if (job == null) return true;
    if (job['owner'] != null && job['owner'] != owner) return false;
    try {
      job['owner'] = owner;
      await _write(prefs, job);
      final tables = Map<String, dynamic>.from(job['tables'] as Map);
      final claims = Map<String, dynamic>.from(
          jsonDecode(prefs.getString(_claimsKey) ?? '{}') as Map);
      for (final table in tables.entries) {
        for (final value in table.value as List) {
          final row = value as Map;
          claims['${table.key}/${row['_source_id'] ?? row['lesson_id']}'] =
              owner;
        }
      }
      if (!await prefs.setString(_claimsKey, jsonEncode(claims))) {
        throw StateError('Could not bind this backup.');
      }
      for (final table in tables.keys) {
        if (_currentUserId() != owner) return false;
        final rows = [
          for (final value in tables[table] as List)
            {...Map<String, dynamic>.from(value as Map), 'user_id': owner}
              ..remove('_source_id')
        ];
        if (rows.isEmpty) continue;
        if (table == 'gratitude_entries') {
          _placeFlowers(rows, await _cloud.fetch(table, owner));
        } else if (table == 'learning_progress') {
          _mergeLessons(rows, await _cloud.fetch(table, owner));
        }
        if (_currentUserId() != owner) return false;
        await _cloud.save(table, rows);
        if (_currentUserId() != owner) return false;
        // Acknowledged tables leave the queue only after confirmed upload.
        tables[table] = <dynamic>[];
        job['tables'] = tables;
        await _write(prefs, job);
      }
      if (_currentUserId() != owner) return false;
      final config = job['routine_configs'] as List?;
      if (config != null) {
        final key = 'routine_configurations_v1_$owner';
        final existing = jsonDecode(prefs.getString(key) ?? '[]') as List;
        final ids = existing.map((row) => (row as Map)['id']).toSet();
        final merged = [
          ...existing,
          ...config.where((row) => !ids.contains((row as Map)['id']))
        ];
        if (!await prefs.setString(key, jsonEncode(merged))) return false;
      }
      return prefs.remove(jobKey);
    } catch (_) {
      // The snapshot and original records stay intact for a retry. No wellness
      // content or raw backend error is logged or put in the interface.
      return false;
    }
  }

  void _placeFlowers(
      List<Map<String, dynamic>> rows, List<Map<String, dynamic>> cloud) {
    final ids = cloud.map((row) => row['id']).toSet();
    final occupied = cloud
        .map((row) => '${row['garden_index']}:${row['plot_index']}')
        .toSet();
    for (final row in rows) {
      if (ids.contains(row['id'])) continue;
      var garden = row['garden_index'] as int? ?? 0;
      var plot = row['plot_index'] as int? ?? 0;
      if (occupied.contains('$garden:$plot')) {
        var position = 0;
        while (occupied.contains('${position ~/ 10}:${position % 10}')) {
          position++;
        }
        garden = position ~/ 10;
        plot = position % 10;
      }
      row['garden_index'] = garden;
      row['plot_index'] = plot;
      occupied.add('$garden:$plot');
    }
  }

  void _mergeLessons(
      List<Map<String, dynamic>> rows, List<Map<String, dynamic>> cloud) {
    for (final row in rows) {
      final existing = cloud
          .where((value) => value['lesson_id'] == row['lesson_id'])
          .firstOrNull;
      if (existing == null) continue;
      row['completed'] =
          row['completed'] == true || existing['completed'] == true;
      for (final field in ['viewed_ideas', 'helpful_ideas']) {
        row[field] =
            {...?row[field] as List?, ...?existing[field] as List?}.toList();
      }
      // Existing account reading position and quiz/practice results take
      // precedence; importing must not rewind or inflate prior achievements.
      for (final field in [
        'last_idea_index',
        'last_opened_at',
        'quiz_score',
        'quiz_total',
        'practice_count',
        'last_practice_scenario',
        'last_practiced_at',
        'practice_reply_count',
        'practice_supportive_count'
      ]) {
        if (existing[field] != null) row[field] = existing[field];
      }
    }
  }
}
