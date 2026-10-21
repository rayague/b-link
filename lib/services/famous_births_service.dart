import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Une personnalité née un jour donné (source : Wikipédia).
@immutable
class FamousBirth {
  final int pageId;
  final String name;
  final int? year;
  final String? description;
  final String? thumbnail;
  final String? url;

  /// Nombre de langues dans lesquelles l'article existe : notre mesure de
  /// notoriété.
  final int languages;

  const FamousBirth({
    required this.pageId,
    required this.name,
    this.year,
    this.description,
    this.thumbnail,
    this.url,
    this.languages = 0,
  });

  FamousBirth withLanguages(int n) => FamousBirth(
      pageId: pageId,
      name: name,
      year: year,
      description: description,
      thumbnail: thumbnail,
      url: url,
      languages: n);

  Map<String, dynamic> toJson() => {
        'pageId': pageId,
        'name': name,
        'year': year,
        'description': description,
        'thumbnail': thumbnail,
        'url': url,
        'languages': languages,
      };

  factory FamousBirth.fromJson(Map<String, dynamic> j) => FamousBirth(
        pageId: j['pageId'] as int,
        name: j['name'] as String,
        year: j['year'] as int?,
        description: j['description'] as String?,
        thumbnail: j['thumbnail'] as String?,
        url: j['url'] as String?,
        languages: j['languages'] as int? ?? 0,
      );
}

/// Personnalités nées un jour donné, d'après le flux « Ce jour-là » de
/// Wikipédia, classées par notoriété (nombre de langues de l'article).
///
/// Le résultat est gardé 30 jours sur l'appareil : une ouverture de l'écran
/// ne fait aucune requête la plupart du temps.
class FamousBirthsService {
  static const _userAgent = 'B-Link/1.0 (https://b-link-3b2d5.web.app)';
  static const _cacheDays = 30;
  final http.Client? _injected;

  // Créé à la première requête seulement (rien n'est ouvert si le résultat
  // est déjà en cache).
  late final http.Client _client = _injected ?? http.Client();

  FamousBirthsService({http.Client? client}) : _injected = client;

  Map<String, String> get _headers =>
      const {'User-Agent': _userAgent, 'Api-User-Agent': _userAgent};

  static String _two(int n) => n.toString().padLeft(2, '0');

  Future<List<FamousBirth>> forDay(int month, int day, String lang,
      {int limit = 12}) async {
    final l = lang == 'fr' ? 'fr' : 'en';
    final key = 'famous_v1_${l}_${_two(month)}-${_two(day)}';
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(key);
    if (cached != null) {
      try {
        final j = jsonDecode(cached) as Map<String, dynamic>;
        final saved = DateTime.parse(j['savedAt'] as String);
        if (DateTime.now().difference(saved).inDays < _cacheDays) {
          return [
            for (final e in j['items'] as List)
              FamousBirth.fromJson(e as Map<String, dynamic>)
          ];
        }
      } catch (_) {}
    }

    final feed = await _client
        .get(
            Uri.parse('https://$l.wikipedia.org/api/rest_v1/feed/onthisday/'
                'births/${_two(month)}/${_two(day)}'),
            headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (feed.statusCode != 200) {
      throw http.ClientException('feed ${feed.statusCode}');
    }
    final births = parseFeed(jsonDecode(feed.body) as Map<String, dynamic>);

    final counts = <int, int>{};
    for (var i = 0; i < births.length; i += 50) {
      final ids = births.skip(i).take(50).map((b) => b.pageId).join('|');
      final r = await _client
          .get(
              Uri.https('$l.wikipedia.org', '/w/api.php', {
                'action': 'query',
                'prop': 'langlinkscount',
                'pageids': ids,
                'format': 'json',
                'formatversion': '2',
              }),
              headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        counts.addAll(parseLanguageCounts(jsonDecode(r.body) as Map<String, dynamic>));
      }
    }
    final top = rank(births, counts, limit: limit);
    await prefs.setString(
        key,
        jsonEncode({
          'savedAt': DateTime.now().toIso8601String(),
          'items': [for (final b in top) b.toJson()],
        }));
    return top;
  }

  /// Entrées du flux « births » (une par personne, dédoublonnées).
  @visibleForTesting
  static List<FamousBirth> parseFeed(Map<String, dynamic> json) {
    final out = <FamousBirth>[];
    final seen = <int>{};
    for (final b in (json['births'] as List? ?? const [])) {
      if (b is! Map) continue;
      final pages = b['pages'];
      if (pages is! List || pages.isEmpty || pages.first is! Map) continue;
      final page = pages.first as Map;
      final id = page['pageid'];
      if (id is! int || !seen.add(id)) continue;
      final titles = page['titles'];
      final name = (titles is Map ? titles['normalized'] : null) ??
          (page['title'] as String?)?.replaceAll('_', ' ');
      if (name is! String || name.isEmpty) continue;
      final thumb = page['thumbnail'];
      final urls = page['content_urls'];
      out.add(FamousBirth(
        pageId: id,
        name: name,
        year: b['year'] is int ? b['year'] as int : null,
        description: page['description'] as String?,
        thumbnail: thumb is Map ? thumb['source'] as String? : null,
        url: urls is Map && urls['mobile'] is Map
            ? urls['mobile']['page'] as String?
            : null,
      ));
    }
    return out;
  }

  /// pageid -> nombre de langues, depuis la réponse de l'API MediaWiki.
  @visibleForTesting
  static Map<int, int> parseLanguageCounts(Map<String, dynamic> json) {
    final pages = (json['query'] as Map?)?['pages'];
    return {
      if (pages is List)
        for (final p in pages)
          if (p is Map && p['pageid'] is int)
            p['pageid'] as int: (p['langlinkscount'] as int?) ?? 0,
    };
  }

  /// Les plus connus d'abord ; à notoriété égale, ceux qui ont une photo.
  @visibleForTesting
  static List<FamousBirth> rank(List<FamousBirth> births, Map<int, int> counts,
      {int limit = 12}) {
    final scored = [
      for (final b in births) b.withLanguages(counts[b.pageId] ?? 0),
    ]..sort((a, b) {
        final c = b.languages.compareTo(a.languages);
        if (c != 0) return c;
        return (b.thumbnail != null ? 1 : 0) - (a.thumbnail != null ? 1 : 0);
      });
    return scored.take(limit).toList();
  }
}
