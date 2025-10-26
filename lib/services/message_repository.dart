import 'db_helper.dart';

class MessageRepository {
  final DBHelper _db = DBHelper();

  Future<String> getRandomForRelation(String relation, String name) async {
    final t = await _db.getRandomMessageByRelation(relation);
    if (t == null) return 'Happy birthday, $name!';
    return t.replaceAll('{name}', name);
  }
}
