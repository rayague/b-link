import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore firestore;
  final String _docPath = 'app_config/admin';

  AdminService({FirebaseFirestore? firestore}) : firestore = firestore ?? FirebaseFirestore.instance;

  /// Get configured admin UID from Firestore; returns null if not set.
  Future<String?> getAdminUid() async {
    try {
      final doc = await firestore.doc(_docPath).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      final v = data['uid'];
      if (v is String && v.isNotEmpty) return v;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Claim admin by writing the uid field. Will fail if write is denied by rules.
  Future<void> claimAdmin(String uid) async {
    await firestore.doc(_docPath).set({'uid': uid, 'claimedAt': FieldValue.serverTimestamp()});
  }

  /// Revoke admin (delete the doc)
  Future<void> revokeAdmin() async {
    await firestore.doc(_docPath).delete();
  }

  /// Stream admin uid changes
  Stream<String?> adminUidStream() async* {
    yield await getAdminUid();
    final snapStream = firestore.doc(_docPath).snapshots();
    await for (final snap in snapStream) {
      if (!snap.exists) {
        yield null;
      } else {
        final d = snap.data();
        yield d == null ? null : (d['uid'] as String?);
      }
    }
  }
}
