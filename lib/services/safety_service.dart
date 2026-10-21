import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Profil bloqué (affiché dans la liste "Profils bloqués").
class BlockedProfile {
  final String uid;
  final String? name;
  const BlockedProfile(this.uid, this.name);
}

/// Signalement et blocage de profils publics.
///
/// - Un signalement crée un document `reports/{id}` lisible uniquement par
///   les admins (voir firestore.rules).
/// - Les blocages sont stockés dans `users/{moi}/blocks/{uid}` (privé, suit
///   le compte entre appareils) avec une copie locale pour filtrer
///   l'annuaire immédiatement, même hors ligne.
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
  String? get _me => _authInstance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _blocks(String me) =>
      _db.collection('users').doc(me).collection('blocks');

  Future<void> report(String reportedUid, String reason) async {
    final me = _me;
    if (me == null) throw StateError('Utilisateur non connecté');
    if (!reasons.contains(reason)) throw ArgumentError.value(reason);
    await _db.collection('reports').add({
      'reporterUid': me,
      'reportedUid': reportedUid,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Set<String>> _localUids() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_blockedKey) ?? const []).toSet();
  }

  Future<void> _saveLocal(Set<String> uids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_blockedKey, uids.toList());
  }

  /// Profils bloqués : liste du compte (cloud) fusionnée avec le cache local.
  /// Hors ligne, le cache local suffit.
  Future<Set<String>> blockedUids() async {
    final local = await _localUids();
    final me = _me;
    if (me == null) return local;
    try {
      final remote = (await _blocks(me).get()).docs.map((d) => d.id).toSet();
      // Blocages faits hors ligne ou avant la synchronisation : les envoyer.
      for (final uid in local.difference(remote)) {
        await _blocks(me).doc(uid).set({'blockedAt': FieldValue.serverTimestamp()});
      }
      final all = {...local, ...remote};
      await _saveLocal(all);
      return all;
    } catch (e) {
      debugPrint('⚠️ Blocages non synchronisés: $e');
      return local;
    }
  }

  Future<void> block(String uid, {String? name}) async {
    await _saveLocal({...await _localUids(), uid});
    final me = _me;
    if (me == null) return;
    try {
      await _blocks(me).doc(uid).set({
        if (name != null) 'name': name,
        'blockedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ Blocage non synchronisé (réessayé plus tard): $e');
    }
  }

  Future<void> unblock(String uid) async {
    await _saveLocal({...await _localUids()}..remove(uid));
    final me = _me;
    if (me == null) return;
    await _blocks(me).doc(uid).delete();
  }

  /// Liste détaillée pour l'écran "Profils bloqués".
  Future<List<BlockedProfile>> blockedProfiles() async {
    final me = _me;
    if (me == null) {
      return [for (final uid in await _localUids()) BlockedProfile(uid, null)];
    }
    await blockedUids(); // synchronise d'abord
    final snap = await _blocks(me).get();
    return [
      for (final d in snap.docs)
        BlockedProfile(d.id, d.data()['name'] as String?),
    ];
  }

  /// Oublie les blocages locaux (déconnexion : le compte suivant sur cet
  /// appareil ne doit pas en hériter).
  Future<void> clearLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_blockedKey);
  }
}
