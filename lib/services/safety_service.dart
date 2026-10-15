import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Signalement et blocage de profils publics.
///
/// - Un signalement crée un document `reports/{id}` lisible uniquement par
///   les admins (voir firestore.rules).
/// - Le blocage est local à l'appareil : les profils bloqués sont masqués de
///   l'annuaire "Même jour".
class SafetyService {
  static const reasons = ['spam', 'inappropriate', 'fake', 'minor', 'other'];
  static const _blockedKey = 'blocked_uids';

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  SafetyService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore,
        _auth = auth;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _authInstance => _auth ?? FirebaseAuth.instance;

  Future<void> report(String reportedUid, String reason) async {
    final me = _authInstance.currentUser?.uid;
    if (me == null) throw StateError('Utilisateur non connecté');
    if (!reasons.contains(reason)) throw ArgumentError.value(reason);
    await _db.collection('reports').add({
      'reporterUid': me,
      'reportedUid': reportedUid,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Set<String>> blockedUids() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_blockedKey) ?? const []).toSet();
  }

  Future<void> block(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final blocked = (prefs.getStringList(_blockedKey) ?? <String>[]).toSet()
      ..add(uid);
    await prefs.setStringList(_blockedKey, blocked.toList());
  }
}
