import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un vœu d'anniversaire reçu.
@immutable
class Wish {
  final String id;
  final String fromUid;
  final String? fromName;

  /// Index du message prédéfini (voir [WishService.count]) : le texte est
  /// affiché dans la langue du destinataire.
  final int wish;
  final DateTime? createdAt;

  const Wish({
    required this.id,
    required this.fromUid,
    this.fromName,
    required this.wish,
    this.createdAt,
  });

  factory Wish.fromMap(String id, Map<String, dynamic> m) {
    final created = m['createdAt'];
    return Wish(
      id: id,
      fromUid: m['fromUid'] as String? ?? '',
      fromName: m['fromName'] as String?,
      wish: (m['wish'] as num?)?.toInt() ?? 0,
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}

/// Vœux d'anniversaire entre membres de l'annuaire
/// (`wishes/{destinataire}/received/{expéditeur}_{année}`, voir
/// firestore.rules) : un message prédéfini par personne et par an.
class WishService {
  /// Nombre de messages prédéfinis (clés de traduction wish_0 … wish_29).
  static const count = 30;

  /// Messages envoyés récemment depuis cet appareil, évités en priorité.
  static const _recentKey = 'wish_recent';
  static const _recentSize = 12;

  /// Ordre de proposition des messages (pur, testable) : d'abord ceux que
  /// le destinataire n'a pas reçus et que l'on n'a pas envoyés récemment,
  /// puis ceux qu'il n'a pas reçus, puis, si tout a été reçu, tous.
  /// L'ordre est mélangé avec [seed].
  static List<int> proposals(
      {required Set<int> receivedByThem,
      required List<int> sentRecently,
      required int seed}) {
    final shuffled = List<int>.generate(count, (i) => i)
      ..shuffle(math.Random(seed));
    final fresh = [
      for (final i in shuffled)
        if (!receivedByThem.contains(i) && !sentRecently.contains(i)) i,
    ];
    final notReceived = [
      for (final i in shuffled)
        if (!receivedByThem.contains(i) && !fresh.contains(i)) i,
    ];
    final ordered = [...fresh, ...notReceived];
    return ordered.isEmpty ? shuffled : ordered;
  }

  /// Numéros des messages déjà reçus cette année par [toUid] (vide si
  /// inconnu ou hors ligne).
  Future<Set<int>> receivedBy(String toUid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('wishes')
          .doc(toUid)
          .get()
          .timeout(const Duration(seconds: 6));
      final data = doc.data();
      if (data == null || data['year'] != _year) return {};
      return {
        for (final n in (data['used'] as List? ?? const []))
          if (n is int) n,
      };
    } catch (_) {
      return {};
    }
  }

  /// Messages envoyés récemment depuis cet appareil (le plus récent en
  /// dernier).
  Future<List<int>> sentRecently() async {
    final prefs = await SharedPreferences.getInstance();
    return [
      for (final s in prefs.getStringList(_recentKey) ?? const <String>[])
        if (int.tryParse(s) != null) int.parse(s),
    ];
  }

  static const _ackTimeout = Duration(seconds: 10);

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Année utilisée par les règles (heure du serveur, UTC).
  static int get _year => DateTime.now().toUtc().year;

  static String _sentKey(String toUid) => 'wish_sent_${toUid}_$_year';

  /// Vœu déjà envoyé cette année à [toUid] depuis cet appareil.
  Future<bool> alreadySent(String toUid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sentKey(toUid)) ?? false;
  }

  /// Envoie le vœu [wish] à [toUid]. [fromName] doit être le nom public de
  /// l'expéditeur (ou null s'il ne le montre pas).
  ///
  /// Hors ligne, l'écriture est mise en file par Firestore : on n'attend
  /// pas le serveur plus de 10 s. Un refus des règles (déjà envoyé, profil
  /// non public…) est relancé à l'appelant.
  Future<void> send(
      {required String toUid, required int wish, String? fromName}) async {
    final uid = _uid;
    if (uid == null) throw StateError('Utilisateur non connecté');
    final write = FirebaseFirestore.instance
        .collection('wishes')
        .doc(toUid)
        .collection('received')
        .doc('${uid}_$_year')
        .set({
      'fromUid': uid,
      'fromName': fromName,
      'wish': wish,
      'year': _year,
      'createdAt': FieldValue.serverTimestamp(),
    });
    try {
      await write.timeout(_ackTimeout);
    } on TimeoutException {
      // En attente du réseau : considéré comme envoyé.
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sentKey(toUid), true);
    final recent = await sentRecently();
    recent
      ..remove(wish)
      ..add(wish);
    await prefs.setStringList(_recentKey, [
      for (final n in recent.skip(math.max(0, recent.length - _recentSize))) '$n',
    ]);
  }

  /// Vœux reçus cette année, du plus récent au plus ancien.
  Future<List<Wish>> received() async {
    final uid = _uid;
    if (uid == null) return const [];
    final snap = await FirebaseFirestore.instance
        .collection('wishes')
        .doc(uid)
        .collection('received')
        .where('year', isEqualTo: _year)
        .get();
    final list = [for (final d in snap.docs) Wish.fromMap(d.id, d.data())]
      ..sort((a, b) => (b.createdAt ?? DateTime(0))
          .compareTo(a.createdAt ?? DateTime(0)));
    return list;
  }
}
