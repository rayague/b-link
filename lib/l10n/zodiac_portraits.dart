import 'zodiac_portraits_en.dart';
import 'zodiac_portraits_fr.dart';

/// Portrait détaillé d'un signe : texte long, dons, ce qui fait grandir,
/// amour, amitié, travail. Écrit à la 2e personne, sans accorder en genre
/// (la personne qui lit peut être une femme, un homme ou ni l'un ni l'autre).
class ZodiacPortrait {
  /// Paragraphes du portrait.
  final List<String> portrait;

  /// Dons : (titre, phrase).
  final List<(String, String)> gifts;

  /// Ce qui fait grandir (formulé avec bienveillance).
  final List<String> growth;
  final String love;
  final String friendship;
  final String work;

  const ZodiacPortrait({
    required this.portrait,
    required this.gifts,
    required this.growth,
    required this.love,
    required this.friendship,
    required this.work,
  });

  /// Portrait du signe [id] (nom français, voir `Zodiac.computeZodiac`).
  static ZodiacPortrait? of(String id, String lang) =>
      (lang == 'fr' ? zodiacPortraitsFr : zodiacPortraitsEn)[id] ??
      zodiacPortraitsEn[id];
}

/// Ordre traditionnel du zodiaque (identifiants français).
const List<String> kZodiacOrder = [
  'Bélier', 'Taureau', 'Gémeaux', 'Cancer', 'Lion', 'Vierge',
  'Balance', 'Scorpion', 'Sagittaire', 'Capricorne', 'Verseau', 'Poissons',
];

/// Mode du signe : 0 cardinal, 1 fixe, 2 mutable (classement traditionnel).
int zodiacModality(String id) => kZodiacOrder.indexOf(id) % 3;

/// Signe opposé sur la roue du zodiaque.
String zodiacOpposite(String id) =>
    kZodiacOrder[(kZodiacOrder.indexOf(id) + 6) % 12];

/// Affinités traditionnelles : les signes du même élément, puis ceux de
/// l'élément complice (feu et air, terre et eau).
List<String> zodiacAffinities(String id) {
  final i = kZodiacOrder.indexOf(id);
  if (i < 0) return const [];
  // Les éléments se suivent : feu, terre, air, eau (i % 4).
  final element = i % 4;
  final partner = switch (element) { 0 => 2, 2 => 0, 1 => 3, _ => 1 };
  return [
    for (var j = 0; j < 12; j++)
      if (j != i && j % 4 == element) kZodiacOrder[j],
    for (var j = 0; j < 12; j++)
      if (j % 4 == partner) kZodiacOrder[j],
  ];
}
