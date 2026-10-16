import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Un nom et le nombre de profils publics qui le portent.
typedef NameCount = ({String name, int count});

/// « Élodie » -> « elodie » : comparaison de noms sans casse ni accents
/// (même règle que la Cloud Function `refreshConstellation`).
String foldName(String s) {
  // Mêmes lettres que la décomposition NFD côté serveur (œ, æ inchangés).
  const from = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
  const to = 'aaaaaaceeeeiiiinooooouuuuyy';
  final b = StringBuffer();
  for (final ch in s.trim().toLowerCase().split('')) {
    final i = from.indexOf(ch);
    b.write(i < 0 ? ch : to[i]);
  }
  return b.toString();
}

/// Statistiques anonymes de l'annuaire, calculées par le serveur
/// (`app_stats/constellation`) : naissances par jour, noms partagés.
@immutable
class ConstellationStats {
  final int total;
  final Map<String, int> days;
  final List<NameCount> firstNames;
  final List<NameCount> familyNames;
  final DateTime? updatedAt;

  const ConstellationStats({
    required this.total,
    required this.days,
    this.firstNames = const [],
    this.familyNames = const [],
    this.updatedAt,
  });

  factory ConstellationStats.fromMap(Map<String, dynamic> m) {
    List<NameCount> names(Object? raw) => [
          if (raw is List)
            for (final e in raw)
              if (e is Map && e['name'] is String && e['count'] is num)
                (name: e['name'] as String, count: (e['count'] as num).toInt()),
        ];
    final rawDays = m['days'];
    final updated = m['updatedAt'];
    return ConstellationStats(
      total: (m['total'] as num?)?.toInt() ?? 0,
      days: {
        if (rawDays is Map)
          for (final e in rawDays.entries)
            if (e.value is num) '${e.key}': (e.value as num).toInt(),
      },
      firstNames: names(m['firstNames']),
      familyNames: names(m['familyNames']),
      updatedAt: updated is Timestamp ? updated.toDate() : null,
    );
  }

  int countFor(String dayKey) => days[dayKey] ?? 0;

  /// Rang du jour (1 = le jour où il y a le plus de naissances), ex aequo
  /// au même rang.
  int rankOf(String dayKey) {
    final mine = countFor(dayKey);
    return 1 + days.values.where((v) => v > mine).length;
  }

  /// Les [n] jours qui comptent le plus de naissances.
  List<MapEntry<String, int>> topDays(int n) =>
      (days.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value) != 0
                ? b.value.compareTo(a.value)
                : a.key.compareTo(b.key)))
          .take(n)
          .toList();

  /// Profils publics qui portent ce prénom / ce nom (null si moins que le
  /// seuil de publication du serveur).
  int? firstNameCount(String name) => _find(firstNames, name);
  int? familyNameCount(String name) => _find(familyNames, name);

  static int? _find(List<NameCount> list, String name) {
    final key = foldName(name);
    for (final n in list) {
      if (foldName(n.name) == key) return n.count;
    }
    return null;
  }
}

/// Lecture des statistiques (gardées 10 minutes en mémoire).
class ConstellationService {
  static ConstellationStats? _cache;
  static DateTime? _cachedAt;

  Future<ConstellationStats?> load({bool refresh = false}) async {
    final fresh = _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < const Duration(minutes: 10);
    if (!refresh && fresh) return _cache;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_stats')
          .doc('constellation')
          .get();
      final data = doc.data();
      _cache = data == null ? null : ConstellationStats.fromMap(data);
      _cachedAt = DateTime.now();
    } catch (e) {
      debugPrint('Statistiques indisponibles: $e');
    }
    return _cache;
  }
}
