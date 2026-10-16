/// Normalisation des noms de ville pour le filtre "Ma ville".
library;

const _accents = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'æ': 'ae',
  'ç': 'c', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ì': 'i', 'í': 'i',
  'î': 'i', 'ï': 'i', 'ñ': 'n', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o',
  'ö': 'o', 'ø': 'o', 'œ': 'oe', 'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ý': 'y', 'ÿ': 'y', 'ß': 'ss',
};

/// "Saint-Étienne ", "saint  etienne", "SAINT ETIENNE" -> "saint etienne".
String normalizeCity(String city) {
  final lower = city.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(_accents[ch] ?? ch);
  }
  return buffer
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
}

/// Clé de ville pour l'annuaire : pays + ville normalisée ("FR:paris"), pour
/// ne pas confondre Paris (France) et Paris (Texas). null si incomplet.
String? cityKey(String? countryCode, String? city) {
  if (countryCode == null || !RegExp(r'^[A-Z]{2}$').hasMatch(countryCode)) {
    return null;
  }
  final normalized = normalizeCity(city ?? '');
  if (normalized.isEmpty) return null;
  return '$countryCode:$normalized';
}
