import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Signalements regroupés par profil signalé (vue admin).
class ReportGroup {
  final String reportedUid;
  final String? displayName;
  final int reporterCount;
  final Map<String, int> reasons; // motif -> nombre
  final DateTime? lastReportAt;

  /// null = aucune décision, true = masqué, false = rétabli par un admin.
  final bool? hidden;

  const ReportGroup({
    required this.reportedUid,
    required this.displayName,
    required this.reporterCount,
    required this.reasons,
    required this.lastReportAt,
    required this.hidden,
  });
}

/// Actions de modération réservées aux admins (voir firestore.rules :
/// moderation/{uid}, reports/{id}). Le masquage automatique est fait par la
/// Cloud Function onReportCreated.
class ModerationService {
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  ModerationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore,
        _auth = auth;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  String? get _adminUid => (_auth ?? FirebaseAuth.instance).currentUser?.uid;

  /// Profils signalés, les plus signalés d'abord.
  Future<List<ReportGroup>> reportGroups({int limit = 500}) async {
    final snap = await _db.collection('reports').limit(limit).get();
    final byUid = <String, List<Map<String, dynamic>>>{};
    for (final doc in snap.docs) {
      final uid = doc.data()['reportedUid'];
      if (uid is String && uid.isNotEmpty) {
        (byUid[uid] ??= []).add(doc.data());
      }
    }

    final groups = <ReportGroup>[];
    for (final entry in byUid.entries) {
      final uid = entry.key;
      final reports = entry.value;
      final reasons = <String, int>{};
      DateTime? last;
      for (final r in reports) {
        final reason = r['reason'] as String? ?? 'other';
        reasons[reason] = (reasons[reason] ?? 0) + 1;
        final at = r['createdAt'];
        final date = at is Timestamp ? at.toDate() : null;
        if (date != null && (last == null || date.isAfter(last))) last = date;
      }
      final moderation = await _db.collection('moderation').doc(uid).get();
      final user = await _db.collection('users').doc(uid).get();
      groups.add(ReportGroup(
        reportedUid: uid,
        displayName: user.data()?['name'] as String?,
        reporterCount: reports.map((r) => r['reporterUid']).toSet().length,
        reasons: reasons,
        lastReportAt: last,
        hidden: moderation.exists
            ? (moderation.data()?['hidden'] == true)
            : null,
      ));
    }
    groups.sort((a, b) => b.reporterCount.compareTo(a.reporterCount));
    return groups;
  }

  /// Masque le profil de l'annuaire (le client ne pourra plus le republier).
  Future<void> hide(String uid) async {
    final batch = _db.batch();
    batch.set(_db.collection('moderation').doc(uid), {
      'hidden': true,
      'reason': 'admin',
      'decidedBy': _adminUid,
      'decidedAt': FieldValue.serverTimestamp(),
    });
    batch.delete(_db.collection('public_profiles').doc(uid));
    await batch.commit();
  }

  /// Rétablit le profil : la décision `hidden: false` est conservée pour que
  /// d'anciens signalements ne le masquent pas à nouveau automatiquement.
  /// Le profil réapparaît au prochain lancement de l'app de l'utilisateur.
  Future<void> restore(String uid) async {
    await _db.collection('moderation').doc(uid).set({
      'hidden': false,
      'reason': 'admin_restored',
      'decidedBy': _adminUid,
      'decidedAt': FieldValue.serverTimestamp(),
    });
    await dismissReports(uid);
  }

  /// Classe les signalements d'un profil sans changer sa visibilité.
  Future<void> dismissReports(String uid) async {
    final reports = await _db
        .collection('reports')
        .where('reportedUid', isEqualTo: uid)
        .get();
    final batch = _db.batch();
    for (final doc in reports.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
