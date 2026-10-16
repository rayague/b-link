import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Rencontre entre jumeaux d'anniversaire d'une même ville (events/{id}).
class Meetup {
  final String id;
  final String creatorUid;
  final String? creatorName;
  final String title;
  final String description;
  final String placeHint;
  final String birthDayKey;
  final String cityKey;
  final DateTime startsAt;
  final int maxAttendees;
  final int attendeeCount;
  final bool cancelled;

  const Meetup({
    required this.id,
    required this.creatorUid,
    required this.creatorName,
    required this.title,
    required this.description,
    required this.placeHint,
    required this.birthDayKey,
    required this.cityKey,
    required this.startsAt,
    required this.maxAttendees,
    required this.attendeeCount,
    required this.cancelled,
  });

  bool get isFull => attendeeCount >= maxAttendees;

  factory Meetup.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final at = d['startsAt'];
    return Meetup(
      id: doc.id,
      creatorUid: d['creatorUid'] as String? ?? '',
      creatorName: d['creatorName'] as String?,
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      placeHint: d['placeHint'] as String? ?? '',
      birthDayKey: d['birthDayKey'] as String? ?? '',
      cityKey: d['cityKey'] as String? ?? '',
      startsAt: at is Timestamp ? at.toDate() : DateTime.fromMillisecondsSinceEpoch(0),
      maxAttendees: (d['maxAttendees'] as num?)?.toInt() ?? 0,
      attendeeCount: (d['attendeeCount'] as num?)?.toInt() ?? 0,
      cancelled: d['cancelled'] == true,
    );
  }
}

/// Participant affiché (nom seulement s'il est public).
class MeetupAttendee {
  final String uid;
  final String? name;
  const MeetupAttendee(this.uid, this.name);
}

/// Accès aux rencontres (voir firestore.rules, section RENCONTRES) : seules
/// les personnes nées le même jour les voient ; organiser ou participer
/// exige d'être dans l'annuaire public.
class MeetupService {
  static const int pageSize = 50; // <= limite des règles

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;
  MeetupService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore,
        _auth = auth;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  String? get _me => (_auth ?? FirebaseAuth.instance).currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('events');

  /// Rencontres à venir pour un jour d'anniversaire et une ville.
  Future<List<Meetup>> upcoming(
      {required String birthDayKey,
      required String cityKey,
      DateTime? now}) async {
    final snap = await _events
        .where('birthDayKey', isEqualTo: birthDayKey)
        .where('cityKey', isEqualTo: cityKey)
        .where('startsAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(now ?? DateTime.now()))
        .orderBy('startsAt')
        .limit(pageSize)
        .get();
    return snap.docs.map(Meetup.fromDoc).where((m) => !m.cancelled).toList();
  }

  Future<Meetup?> get(String id) async {
    final doc = await _events.doc(id).get();
    return doc.exists ? Meetup.fromDoc(doc) : null;
  }

  Future<String> create({
    required String title,
    required String description,
    required String placeHint,
    required String birthDayKey,
    required String cityKey,
    required DateTime startsAt,
    required int maxAttendees,
    String? creatorName,
  }) async {
    final me = _me;
    if (me == null) throw StateError('Utilisateur non connecté');
    final ref = _events.doc();
    await ref.set({
      'creatorUid': me,
      'creatorName': creatorName,
      'title': title.trim(),
      'description': description.trim(),
      'placeHint': placeHint.trim(),
      'birthDayKey': birthDayKey,
      'cityKey': cityKey,
      'startsAt': Timestamp.fromDate(startsAt),
      'maxAttendees': maxAttendees,
      'attendeeCount': 0,
      'cancelled': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<bool> isAttending(String eventId) async {
    final me = _me;
    if (me == null) return false;
    final doc = await _events.doc(eventId).collection('attendees').doc(me).get();
    return doc.exists;
  }

  Future<List<MeetupAttendee>> attendees(String eventId) async {
    final snap = await _events.doc(eventId).collection('attendees').get();
    return [
      for (final d in snap.docs)
        MeetupAttendee(d.id, d.data()['name'] as String?),
    ];
  }

  /// Inscription : participation + compteur dans un même lot (exigé par
  /// les règles, qui vérifient aussi la capacité).
  Future<void> join(String eventId, {String? publicName}) async {
    final me = _me;
    if (me == null) throw StateError('Utilisateur non connecté');
    final batch = _db.batch();
    batch.set(_events.doc(eventId).collection('attendees').doc(me), {
      'uid': me,
      'name': publicName,
      'joinedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_events.doc(eventId), {'attendeeCount': FieldValue.increment(1)});
    await batch.commit();
  }

  Future<void> leave(String eventId) async {
    final me = _me;
    if (me == null) return;
    final batch = _db.batch();
    batch.delete(_events.doc(eventId).collection('attendees').doc(me));
    batch.update(_events.doc(eventId), {'attendeeCount': FieldValue.increment(-1)});
    await batch.commit();
  }

  Future<void> cancel(String eventId) =>
      _events.doc(eventId).update({'cancelled': true});
}
