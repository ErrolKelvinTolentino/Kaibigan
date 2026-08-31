import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';

import 'learning_model.dart';

class MedlinePlusException implements Exception {
  const MedlinePlusException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MedlinePlusService {
  MedlinePlusService({http.Client? client}) : _client = client ?? http.Client();

  static const _cacheLifetime = Duration(hours: 24);
  final http.Client _client;

  Future<List<TrustedArticle>> search(String query) async {
    final cached = await _readCache(query);
    if (cached != null && !cached.isStale) return cached.articles;

    try {
      final uri = Uri.https('wsearch.nlm.nih.gov', '/ws/query', {
        'db': 'healthTopics',
        'term': query,
        'rettype': 'brief',
        'retmax': '4',
        'tool': 'kaibigan',
      });
      final response = await _client.get(uri).timeout(
            const Duration(seconds: 12),
          );
      if (response.statusCode != 200) {
        throw MedlinePlusException(
            'MedlinePlus returned ${response.statusCode}');
      }
      final articles = parseResponse(response.body);
      await _writeCache(query, articles);
      return articles;
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
                  .where((node) => node.getAttribute('name') == name)
                  .map((node) => node.innerText.trim())
                  .firstOrNull ??
              '';

          final title = content('title');
          final summary = content('FullSummary');
          final url = Uri.tryParse(element.getAttribute('url') ?? '');
          if (title.isEmpty || url == null || !url.hasScheme) return null;
          return TrustedArticle(title: title, summary: summary, url: url);
        })
        .whereType<TrustedArticle>()
        .toList(growable: false);
  }

  Future<_CachedArticles?> _readCache(String query) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_cacheKey(query));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      final savedAt = DateTime.tryParse(json['savedAt'] as String? ?? '');
      final items = (json['articles'] as List<Object?>? ?? const [])
          .whereType<Map<String, Object?>>()
          .map(TrustedArticle.fromJson)
          .whereType<TrustedArticle>()
          .toList(growable: false);
      if (savedAt == null) return null;
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
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _cacheKey(query),
      jsonEncode({
        'savedAt': DateTime.now().toIso8601String(),
        'articles': articles.map((article) => article.toJson()).toList(),
      }),
    );
  }

  String _cacheKey(String query) =>
      'medline_plus_${base64Url.encode(utf8.encode(query.toLowerCase()))}';
}

class _CachedArticles {
  const _CachedArticles({required this.articles, required this.isStale});

  final List<TrustedArticle> articles;
  final bool isStale;
}
