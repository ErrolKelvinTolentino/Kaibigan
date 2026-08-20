import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class JournalDraftService {
  JournalDraftService._();

  static const _storage = FlutterSecureStorage();
  static const _prefix = 'journal_draft_v1_';

  static Future<Map<String, dynamic>?> read(String userId) async {
    final value = await _storage.read(key: '$_prefix$userId');
    if (value == null || value.isEmpty) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } on FormatException {
      await clear(userId);
      return null;
    }
  }

  static Future<void> write(
    String userId,
    Map<String, dynamic> draft,
  ) async {
    await _storage.write(key: '$_prefix$userId', value: jsonEncode(draft));
  }

  static Future<void> clear(String userId) =>
      _storage.delete(key: '$_prefix$userId');
}
