import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/env_config.dart';

class ResearchArticle {
  const ResearchArticle(
      {required this.id,
      required this.title,
      required this.journal,
      required this.year});
  final String id;
  final String title;
  final String journal;
  final String year;
  Uri get url => Uri.https('pubmed.ncbi.nlm.nih.gov', '/$id/');
  Map<String, String> toJson() =>
      {'id': id, 'title': title, 'journal': journal, 'year': year};
  static ResearchArticle? fromJson(Map<String, dynamic> map) {
    final id = map['id'];
    final title = map['title'];
    if (id is! String ||
        !RegExp(r'^\d+$').hasMatch(id) ||
        title is! String ||
        title.trim().isEmpty) {
      return null;
    }
    return ResearchArticle(
        id: id,
        title: title,
        journal: map['journal'] is String ? map['journal'] : '',
        year: map['year'] is String ? map['year'] : '');
  }
}

/// Optional bibliographic links. Research never generates lesson advice or
/// receives a learner's questions, reflections, journals or identity.
class PubmedReadingService {
  PubmedReadingService({http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;
  final http.Client _client;
  final bool _ownsClient;
  final Map<String, Future<List<ResearchArticle>>> _pending = {};

  Future<List<ResearchArticle>> search(String lessonId) {
    final existing = _pending[lessonId];
    if (existing != null) return existing;
    final work =
        _search(lessonId).whenComplete(() => _pending.remove(lessonId));
    _pending[lessonId] = work;
    return work;
  }

  Future<List<ResearchArticle>> _search(String lessonId) async {
    List<ResearchArticle>? saved;
    final key = 'learning_pubmed_v1_$lessonId';
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        saved = parseArticles(data);
        final date = DateTime.tryParse(data['savedAt'] as String? ?? '');
        if (date != null &&
            !date.isAfter(DateTime.now()) &&
            DateTime.now().difference(date) < const Duration(hours: 24)) {
          return saved;
        }
      }
    } catch (_) {
      // Caching is optional; a successful network response remains usable.
    }
    try {
      final url =
          Uri.parse('${EnvConfig.supabaseUrl}/functions/v1/learning-resources')
              .replace(
                  queryParameters: {'lesson': lessonId, 'provider': 'pubmed'});
      final response =
          await _client.get(url).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) throw StateError('Research unavailable');
      final articles =
          parseArticles(jsonDecode(response.body) as Map<String, dynamic>);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            key,
            jsonEncode({
              'savedAt': DateTime.now().toIso8601String(),
              'articles': articles.map((article) => article.toJson()).toList()
            }));
      } catch (_) {
        // Do not turn a cache failure into a content failure.
      }
      return articles;
    } catch (_) {
      if (saved != null) return saved;
      throw StateError(
          'Research links are unavailable. Your lesson still works offline.');
    }
  }

  static List<ResearchArticle> parseArticles(Map<String, dynamic> data) {
    final articles = data['articles'];
    if (articles is! List) {
      throw const FormatException('Missing research articles');
    }
    return articles
        .whereType<Map<String, dynamic>>()
        .map(ResearchArticle.fromJson)
        .whereType<ResearchArticle>()
        .fold<Map<String, ResearchArticle>>({}, (items, article) {
          items.putIfAbsent(article.id, () => article);
          return items;
        })
        .values
        .take(3)
        .toList(growable: false);
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
