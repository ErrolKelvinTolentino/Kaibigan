import 'dart:convert';

/// Centralized visual logger for API requests, responses, and database transactions in debug console.
class ApiLogger {
  static const JsonEncoder _prettyEncoder = JsonEncoder.withIndent('  ');

  /// 1. Logs API Request Implementation
  static void logApiRequest({
    required String apiName,
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    dynamic body,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('\n====================================================================');
    buffer.writeln('=== API REQUEST IMPLEMENTATION ===');
    buffer.writeln('====================================================================');
    buffer.writeln('API Service  : $apiName');
    buffer.writeln('Method & URL : $method $url');
    if (headers != null && headers.isNotEmpty) {
      final sanitizedHeaders = Map<String, dynamic>.from(headers);
      if (sanitizedHeaders.containsKey('Authorization')) {
        sanitizedHeaders['Authorization'] = 'Bearer [HIDDEN_API_KEY]';
      }
      buffer.writeln('Headers      : ${jsonEncode(sanitizedHeaders)}');
    }
    if (body != null) {
      String formattedBody;
      try {
        if (body is String) {
          final decoded = jsonDecode(body);
          formattedBody = _prettyEncoder.convert(decoded);
        } else {
          formattedBody = _prettyEncoder.convert(body);
        }
      } catch (_) {
        formattedBody = body.toString();
      }
      buffer.writeln('Request Body :\n$formattedBody');
    }
    buffer.writeln('====================================================================\n');
    print(buffer.toString());
  }

  /// 2. Logs JSON Response Sample
  static void logJsonResponseSample({
    required String apiName,
    required int statusCode,
    required String url,
    dynamic body,
    String? reasonPhrase,
  }) {
    final buffer = StringBuffer();
    final isSuccess = statusCode >= 200 && statusCode < 300;
    final statusIcon = isSuccess ? '✅' : '❌';

    buffer.writeln('\n====================================================================');
    buffer.writeln('=== JSON RESPONSE SAMPLE ===');
    buffer.writeln('====================================================================');
    buffer.writeln('API Service   : $apiName');
    buffer.writeln('Status Code   : $statusIcon $statusCode ${reasonPhrase ?? ''}');
    buffer.writeln('Endpoint      : $url');
    if (body != null) {
      String formattedBody;
      try {
        if (body is String) {
          final decoded = jsonDecode(body);
          formattedBody = _prettyEncoder.convert(decoded);
        } else {
          formattedBody = _prettyEncoder.convert(body);
        }
      } catch (_) {
        formattedBody = body.toString();
      }
      buffer.writeln('Response JSON :\n$formattedBody');
    }
    buffer.writeln('====================================================================\n');
    print(buffer.toString());
  }

  /// 3. Logs Retrieved Data Displayed In The Application
  static void logRetrievedDataDisplayed({
    required String screenName,
    required String componentName,
    required dynamic displayedData,
    String? note,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('\n====================================================================');
    buffer.writeln('=== RETRIEVED DATA DISPLAYED IN THE APPLICATION ===');
    buffer.writeln('====================================================================');
    buffer.writeln('Target Screen : $screenName');
    buffer.writeln('UI Component  : $componentName');
    if (note != null && note.isNotEmpty) {
      buffer.writeln('Presentation  : $note');
    }
    if (displayedData != null) {
      String formattedData;
      try {
        if (displayedData is String) {
          formattedData = displayedData;
        } else {
          formattedData = _prettyEncoder.convert(displayedData);
        }
      } catch (_) {
        formattedData = displayedData.toString();
      }
      buffer.writeln('Displayed Content :\n$formattedData');
    }
    buffer.writeln('====================================================================\n');
    print(buffer.toString());
  }

  // Backwards compatibility aliases
  static void logRequest({
    required String apiName,
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    dynamic body,
  }) => logApiRequest(apiName: apiName, method: method, url: url, headers: headers, body: body);

  static void logResponse({
    required String apiName,
    required int statusCode,
    required String url,
    dynamic body,
    String? reasonPhrase,
  }) => logJsonResponseSample(apiName: apiName, statusCode: statusCode, url: url, body: body, reasonPhrase: reasonPhrase);

  /// Logs Supabase Database CRUD actions
  static void logDatabase({
    required String operation, // SELECT, INSERT, UPDATE, DELETE
    required String table,
    dynamic payload,
    dynamic result,
    String? error,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('\n====================================================================');
    buffer.writeln('=== API REQUEST IMPLEMENTATION (Supabase PostgREST) ===');
    buffer.writeln('====================================================================');
    buffer.writeln('Operation : $operation');
    buffer.writeln('Table     : $table');
    if (payload != null) {
      buffer.writeln('Payload   : ${payload is Map || payload is List ? _prettyEncoder.convert(payload) : payload}');
    }
    if (error != null) {
      buffer.writeln('Error     : $error');
    }
    buffer.writeln('====================================================================');
    
    if (result != null) {
      buffer.writeln('=== JSON RESPONSE SAMPLE (Supabase PostgREST) ===');
      buffer.writeln('====================================================================');
      buffer.writeln('Result    : ${result is Map || result is List ? _prettyEncoder.convert(result) : result}');
      buffer.writeln('====================================================================');
      buffer.writeln('=== RETRIEVED DATA DISPLAYED IN THE APPLICATION ===');
      buffer.writeln('====================================================================');
      buffer.writeln('Updated state in Provider & rendered in UI');
      buffer.writeln('====================================================================\n');
    }
    print(buffer.toString());
  }
}
