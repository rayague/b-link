import 'package:shared_preferences/shared_preferences.dart';

import 'db_helper.dart';

/// Messages d'anniversaire tirés de la banque, sans répétition : un message
/// déjà montré pour une relation ne revient qu'une fois tous les autres
/// proposés (historique gardé sur l'appareil).
class MessageRepository {
  final DBHelper _db;

  MessageRepository({DBHelper? db}) : _db = db ?? DBHelper();

  /// La banque change de numérotation à chaque réimport : l'historique est
  /// lié à sa version.
  static String _historyKey(String lang, String relation) =>
      'msg_seen_v${DBHelper.messagesVersion}_${lang}_${relation.toLowerCase()}';

  /// Message d'anniversaire pour la relation, dans la langue [lang] (repli
  /// sur l'anglais), jamais un message déjà montré tant qu'il en reste
  /// d'autres. `{name}` est remplacé par [name].
  Future<String> getRandomForRelation(String relation, String name,
      {String lang = 'en'}) async {
    final fallback =
        lang == 'fr' ? 'Joyeux anniversaire, $name !' : 'Happy birthday, $name!';
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _historyKey(lang, relation);
      final seen = {
        for (final s in prefs.getStringList(key) ?? const <String>[])
          if (int.tryParse(s) != null) int.parse(s),
      };
      var pick = await _db.pickMessage(relation, lang: lang, exclude: seen);
      if (pick == null && seen.isNotEmpty) {
        // Tout a été montré : on recommence un tour complet.
        seen.clear();
        pick = await _db.pickMessage(relation, lang: lang);
      }
      if (pick == null) return fallback;
      seen.add(pick.id);
      await prefs.setStringList(key, [for (final id in seen) '$id']);
      return pick.text.replaceAll('{name}', name);
    } catch (_) {
      return fallback;
    }
  }
}
