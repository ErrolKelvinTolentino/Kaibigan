import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Centralized visual logger for API requests, responses, and database transactions in debug console.
class ApiLogger {
  static const JsonEncoder _prettyEncoder = JsonEncoder.withIndent('  ');
  static const Set<String> _privateKeys = {
    'content',
    'title',
    'ai_response',
    'memory_summary',
    'note',
    'mood_note',
    'gratitude_content',
    'focus_or_highlight',
    'systemprompt',
    'usertext',
    'messages',
    'email',
  };

  static dynamic _safeForLog(dynamic value, {String? key}) {
    if (key != null && _privateKeys.contains(key.toLowerCase())) {
      final length = value?.toString().length ?? 0;
      return '[PRIVATE CONTENT REDACTED; $length chars]';
    }
    if (value is Map) {
      return value.map(
        (mapKey, mapValue) => MapEntry(
          mapKey.toString(),
          _safeForLog(mapValue, key: mapKey.toString()),
        ),
      );
    }
    if (value is Iterable) {
      return value.map((item) => _safeForLog(item)).toList();
    }
    if (value is String && value.length > 500) {
      return '[LONG STRING REDACTED; ${value.length} chars]';
    }
    return value;
  }

  /// 1. Logs API Request Implementation
  static void logApiRequest({
    required String apiName,
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    dynamic body,
  }) {
    if (!kDebugMode) return;
    final buffer = StringBuffer();
    buffer.writeln(
        '\n====================================================================');
    buffer.writeln('=== API REQUEST IMPLEMENTATION ===');
    buffer.writeln(
        '====================================================================');
    buffer.writeln('API Service  : $apiName');
    buffer.writeln('Method & URL : $method $url');
    if (headers != null && headers.isNotEmpty) {
      final sanitizedHeaders = Map<String, dynamic>.from(headers);
      sanitizedHeaders.updateAll((key, value) {
        final normalizedKey = key.toLowerCase();
        if (normalizedKey == 'authorization' || normalizedKey == 'apikey') {
          return '[HIDDEN_CREDENTIAL]';
        }
        return value;
      });
      buffer.writeln('Headers      : ${jsonEncode(sanitizedHeaders)}');
    }
    if (body != null) {
      String formattedBody;
      try {
        if (body is String) {
          final decoded = jsonDecode(body);
          formattedBody = _prettyEncoder.convert(_safeForLog(decoded));
        } else {
          formattedBody = _prettyEncoder.convert(_safeForLog(body));
        }
      } catch (_) {
        formattedBody = _safeForLog(body).toString();
      }
      buffer.writeln('Request Body :\n$formattedBody');
    }
    buffer.writeln(
        '====================================================================\n');
    debugPrint(buffer.toString());
  }

  /// 2. Logs JSON Response Sample
  static void logJsonResponseSample({
    required String apiName,
    required int statusCode,
    required String url,
    dynamic body,
    String? reasonPhrase,
  }) {
    if (!kDebugMode) return;
    final buffer = StringBuffer();
    final isSuccess = statusCode >= 200 && statusCode < 300;
    final statusIcon = isSuccess ? '✅' : '❌';

    buffer.writeln(
        '\n====================================================================');
    buffer.writeln('=== JSON RESPONSE SAMPLE ===');
    buffer.writeln(
        '====================================================================');
    buffer.writeln('API Service   : $apiName');
    buffer.writeln(
        'Status Code   : $statusIcon $statusCode ${reasonPhrase ?? ''}');
    buffer.writeln('Endpoint      : $url');
    if (body != null) {
      String formattedBody;
      try {
        if (body is String) {
          final decoded = jsonDecode(body);
          formattedBody = _prettyEncoder.convert(_safeForLog(decoded));
        } else {
          formattedBody = _prettyEncoder.convert(_safeForLog(body));
        }
      } catch (_) {
        formattedBody = _safeForLog(body).toString();
      }
      buffer.writeln('Response JSON :\n$formattedBody');
    }
    buffer.writeln(
        '====================================================================\n');
    debugPrint(buffer.toString());
  }

  /// 3. Logs Retrieved Data Displayed In The Application
  static void logRetrievedDataDisplayed({
    required String screenName,
    required String componentName,
    required dynamic displayedData,
    String? note,
  }) {
    if (!kDebugMode) return;
    final buffer = StringBuffer();
    buffer.writeln(
        '\n====================================================================');
    buffer.writeln('=== RETRIEVED DATA DISPLAYED IN THE APPLICATION ===');
    buffer.writeln(
        '====================================================================');
    buffer.writeln('Target Screen : $screenName');
    buffer.writeln('UI Component  : $componentName');
    if (note != null && note.isNotEmpty) {
      buffer.writeln('Presentation  : $note');
    }
    if (displayedData != null) {
      String formattedData;
      try {
        if (displayedData is String) {
          formattedData =
              '[PRIVATE DISPLAY CONTENT REDACTED; ${displayedData.length} chars]';
        } else {
          formattedData = _prettyEncoder.convert(_safeForLog(displayedData));
        }
      } catch (_) {
        formattedData = _safeForLog(displayedData).toString();
      }
      buffer.writeln('Displayed Content :\n$formattedData');
    }
    buffer.writeln(
        '====================================================================\n');
    debugPrint(buffer.toString());
  }

  // Backwards compatibility aliases
  static void logRequest({
    required String apiName,
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    dynamic body,
  }) =>
      logApiRequest(
          apiName: apiName,
          method: method,
          url: url,
          headers: headers,
          body: body);

  static void logResponse({
    required String apiName,
    required int statusCode,
    required String url,
    dynamic body,
    String? reasonPhrase,
  }) =>
      logJsonResponseSample(
          apiName: apiName,
          statusCode: statusCode,
          url: url,
          body: body,
          reasonPhrase: reasonPhrase);

  /// Logs Supabase Database CRUD actions
  static void logDatabase({
    required String operation, // SELECT, INSERT, UPDATE, DELETE
    required String table,
    dynamic payload,
    dynamic result,
    String? error,
  }) {
    if (!kDebugMode) return;
    final buffer = StringBuffer();
    buffer.writeln(
        '\n====================================================================');
    buffer.writeln('=== API REQUEST IMPLEMENTATION (Supabase PostgREST) ===');
    buffer.writeln(
        '====================================================================');
    buffer.writeln('Operation : $operation');
    buffer.writeln('Table     : $table');
    if (payload != null) {
      final safePayload = _safeForLog(payload);
      buffer.writeln(
          'Payload   : ${safePayload is Map || safePayload is List ? _prettyEncoder.convert(safePayload) : safePayload}');
    }
    if (error != null) {
      buffer.writeln('Error     : [REDACTED; ${error.length} chars]');
    }
    buffer.writeln(
        '====================================================================');

    if (result != null) {
      buffer.writeln('=== JSON RESPONSE SAMPLE (Supabase PostgREST) ===');
      buffer.writeln(
          '====================================================================');
      final safeResult = _safeForLog(result);
      buffer.writeln(
          'Result    : ${safeResult is Map || safeResult is List ? _prettyEncoder.convert(safeResult) : safeResult}');
      buffer.writeln(
          '====================================================================');
      buffer.writeln('=== RETRIEVED DATA DISPLAYED IN THE APPLICATION ===');
      buffer.writeln(
          '====================================================================');
      buffer.writeln('Updated state in Provider & rendered in UI');
      buffer.writeln(
          '====================================================================\n');
    }
    debugPrint(buffer.toString());
  }
}
