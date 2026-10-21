import '../l10n/app_localizations.dart';

/// Relations proposées pour un contact. Le code (majuscules, en anglais) est
/// la valeur enregistrée et sert à choisir les messages d'anniversaire
/// (assets/messages*.txt, en minuscules) : ne pas le renommer.
const List<String> kRelations = [
  'SON',
  'DAUGHTER',
  'SISTER',
  'BROTHER',
  'FRIEND',
  'BESTFRIEND',
  'NEIGHBOR',
  'BOYFRIEND',
  'GIRLFRIEND',
  'HUSBAND',
  'WIFE',
  'FATHER',
  'MOTHER',
  'AUNTIE',
  'UNCLE',
  'COUSIN',
  'NIECE',
  'NEPHEW',
  'GRAND-SON',
  'GRAND-DAUGHTER',
  'GRAND-FATHER',
  'GRAND-MOTHER',
  'GOD-FATHER',
  'GOD-MOTHER',
];

/// Clé de traduction du nom affiché d'une relation (ex. GRAND-MOTHER ->
/// relation_grand_mother).
String relationKey(String code) =>
    'relation_${code.toLowerCase().replaceAll('-', '_')}';

/// Nom de la relation dans la langue de l'interface (le code brut s'il est
/// inconnu, par exemple une relation saisie par une ancienne version).
String relationLabel(AppLocalizations l10n, String code) {
  if (code.isEmpty) return code;
  final key = relationKey(code);
  final label = l10n.translate(key);
  return label == key ? code : label;
}
