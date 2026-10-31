import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// On-device persistence for a list of records, in the same shape the
/// backend uses.
///
/// Every model in the app already has a `toMap`/`fromMap` pair written for
/// Supabase. Reusing them means offline records are byte-for-byte the rows
/// the server would have stored, so nothing has to be translated twice and
/// a future import can hand them straight over.
class LocalRecordStore<T> {
  const LocalRecordStore({
    required this.collection,
    required this.encode,
    required this.decode,
    required this.idOf,
  });

  /// Matches the backend table name, so the two stay recognisably the same
  /// data.
  final String collection;

  final Map<String, dynamic> Function(T value) encode;
  final T Function(Map<String, dynamic> map) decode;
  final String Function(T value) idOf;

  /// Records are namespaced by scope so a guest's entries and a signed-in
  /// account's entries never read each other, even on a shared phone.
  String keyFor(String scope) => 'kaibigan_local_${collection}_$scope';

  Future<List<T>> load(String scope, {bool strict = false}) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(keyFor(scope));
      if (raw == null || raw.trim().isEmpty) return <T>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        if (strict) throw const FormatException('Record history is not a list');
        return <T>[];
      }
      final records = <T>[];
      for (final item in decoded) {
        if (item is! Map) {
          if (strict) {
            throw const FormatException(
                'Record history contains an invalid item');
          }
          continue;
        }
        try {
          records.add(decode(Map<String, dynamic>.from(item)));
        } catch (error) {
          if (strict) rethrow;
          // One unreadable row must not take the rest of the history with
          // it; a person's journal is worth more than strictness here.
          debugPrint('Skipped an unreadable $collection record: $error');
        }
      }
      return records;
    } catch (error) {
      if (strict) rethrow;
      debugPrint('Could not read local $collection: $error');
      return <T>[];
    }
  }

  Future<bool> replaceAll(String scope, Iterable<T> records) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final payload = jsonEncode(
        records.map((record) => encode(record)).toList(growable: false),
      );
      return preferences.setString(keyFor(scope), payload);
    } catch (error) {
      debugPrint('Could not write local $collection: $error');
      return false;
    }
  }

  /// Inserts or replaces one record by id, leaving the rest untouched.
  Future<bool> upsert(String scope, T record) async {
    final records = await load(scope);
    final id = idOf(record);
    final index = records.indexWhere((existing) => idOf(existing) == id);
    if (index == -1) {
      records.add(record);
    } else {
      records[index] = record;
    }
    return replaceAll(scope, records);
  }

  Future<bool> remove(String scope, String id) async {
    final records = await load(scope);
    final remaining =
        records.where((record) => idOf(record) != id).toList(growable: false);
    if (remaining.length == records.length) return true;
    return replaceAll(scope, remaining);
  }

  Future<bool> clear(String scope) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.remove(keyFor(scope));
    } catch (error) {
      debugPrint('Could not clear local $collection: $error');
      return false;
    }
  }

  /// Everything held for a scope, as the raw maps, for export.
  Future<List<Map<String, dynamic>>> exportRaw(String scope) async {
    final records = await load(scope);
    return records.map((record) => encode(record)).toList(growable: false);
  }
}
