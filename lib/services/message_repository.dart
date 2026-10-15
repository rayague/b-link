import 'db_helper.dart';

class MessageRepository {
  final DBHelper _db = DBHelper();

  /// Message d'anniversaire aléatoire pour la relation, dans la langue
  /// [lang] (repli sur l'anglais). `{name}` est remplacé par [name].
  Future<String> getRandomForRelation(String relation, String name,
      {String lang = 'en'}) async {
    final fallback =
        lang == 'fr' ? 'Joyeux anniversaire, $name !' : 'Happy birthday, $name!';
    try {
      final t = await _db.getRandomMessageByRelation(relation, lang: lang);
      if (t == null) return fallback;
      return t.replaceAll('{name}', name);
    } catch (_) {
      return fallback;
    }
  }
}
