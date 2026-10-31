import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';

import 'learning_model.dart';
import '../../core/utils/env_config.dart';

class MedlinePlusException implements Exception {
  const MedlinePlusException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MedlinePlusService {
  MedlinePlusService({http.Client? client}) : _client = client ?? http.Client(),
      _ownsClient = client == null;

  static const _cacheLifetime = Duration(hours: 24);
  final http.Client _client;
  final bool _ownsClient;
  final Map<String, Future<List<TrustedArticle>>> _pending = {};

  Future<List<TrustedArticle>> search(String query, {String? lessonId}) {
    final normalized = query.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    if (normalized.isEmpty) return Future.value(const []);
    final existing = _pending[normalized];
    if (existing != null) return existing;
    final work = _search(normalized, lessonId: lessonId).whenComplete(() => _pending.remove(normalized));
    _pending[normalized] = work;
    return work;
  }

  Future<List<TrustedArticle>> _search(String query, {String? lessonId}) async {
    final cached = await _readCache(query);
    if (cached != null && !cached.isStale) return cached.articles;

    try {
      final direct = Uri.https('wsearch.nlm.nih.gov', '/ws/query', {
        'db': 'healthTopics',
        'term': query,
        'rettype': 'brief',
        'retmax': '4',
        'tool': 'kaibigan',
      });
      final urls = [
        if (lessonId != null) Uri.parse('${EnvConfig.supabaseUrl}/functions/v1/learning-resources')
            .replace(queryParameters: {'lesson': lessonId, 'provider': 'medline'}),
        if (!kIsWeb || lessonId == null) direct,
      ];
      for (final uri in urls) {
        try {
          final response = await _client.get(uri).timeout(const Duration(seconds: 8));
          if (response.statusCode != 200) throw const MedlinePlusException('Reading unavailable');
          final articles = parseResponse(response.body);
          await _writeCache(query, articles);
          return articles;
        } catch (_) {
          // Native hosts can fall back to NLM directly; browsers use the
          // public topic proxy because MedlinePlus does not expose CORS.
        }
      }
      throw const MedlinePlusException('Reading unavailable');
    } catch (_) {
      if (cached != null) return cached.articles;
      throw const MedlinePlusException(
        'Trusted reading is unavailable right now. The Kaibigan lesson is still available offline.',
      );
    }
  }

  static List<TrustedArticle> parseResponse(String body) {
    final document = XmlDocument.parse(body);
    return document
        .findAllElements('document')
        .map((element) {
          String content(String name) =>
              element
                  .findElements('content')
                  .where((node) => node.getAttribute('name')?.toLowerCase() == name.toLowerCase())
                  .map((node) => node.innerText.trim())
                  .firstOrNull ??
              '';

          final title = content('title');
          final summary = plainText(content('FullSummary').isEmpty ? content('snippet') : content('FullSummary'));
          final url = Uri.tryParse(element.getAttribute('url') ?? '');
          if (title.isEmpty || url == null || !TrustedArticle.isMedlineUrl(url)) return null;
          return TrustedArticle(title: plainText(title), summary: summary, url: url);
        })
        .whereType<TrustedArticle>()
        .fold<Map<String, TrustedArticle>>({}, (items, article) {
          items.putIfAbsent(article.url.toString(), () => article);
          return items;
        }).values.take(4).toList(growable: false);
  }

  static String plainText(String value) => value
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ').replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"').replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<').replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'\s+'), ' ').trim();

  void close() {
    if (_ownsClient) _client.close();
  }

  Future<_CachedArticles?> _readCache(String query) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_cacheKey(query));
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, Object?>;
      final savedAt = DateTime.tryParse(json['savedAt'] as String? ?? '');
      final items = (json['articles'] as List<Object?>? ?? const [])
          .whereType<Map<String, Object?>>()
          .map(TrustedArticle.fromJson)
          .whereType<TrustedArticle>()
          .toList(growable: false);
      if (savedAt == null || savedAt.isAfter(DateTime.now())) return null;
      return _CachedArticles(
        articles: items,
        isStale: DateTime.now().difference(savedAt) > _cacheLifetime,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(
    String query,
    List<TrustedArticle> articles,
  ) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
      _cacheKey(query),
      jsonEncode({
        'savedAt': DateTime.now().toIso8601String(),
        'articles': articles.map((article) => article.toJson()).toList(),
      }),
      );
    } catch (_) {
      // Successful reading must still display if device caching is unavailable.
    }
  }

  String _cacheKey(String query) =>
      'medline_plus_${base64Url.encode(utf8.encode(query.toLowerCase()))}';
}

class _CachedArticles {
  const _CachedArticles({required this.articles, required this.isStale});

  final List<TrustedArticle> articles;
  final bool isStale;
}
