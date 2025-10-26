import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/sync_service.dart';

class ProfileProvider extends ChangeNotifier {
  UserProfile? _profile;
  final ProfileService _service;
  final SyncService _sync;

  ProfileProvider({ProfileService? service, SyncService? sync}) : _service = service ?? ProfileService(firestore: null), _sync = sync ?? SyncService();

  UserProfile? get profile => _profile;

  Future<void> load() async {
    final local = await _service.loadLocal();
    if (local != null) {
      _profile = local;
      notifyListeners();
    }
  }

  Future<void> save(UserProfile p, {bool push = true}) async {
    _profile = p;
    // ensure we have an anonymous user id to attach
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        final cred = await FirebaseAuth.instance.signInAnonymously();
        _profile!.uid = cred.user?.uid;
      } else {
        _profile!.uid = userId;
      }
    } catch (e) {
      // ignore auth errors; push will be skipped if not available
    }

    await _service.saveLocally(_profile!);
    notifyListeners();
    if (push) {
      // Attempt to push immediately and also process the local queue
      try {
        await _service.pushToFirestore(_profile!);
      } catch (_) {}
      // process pending queue in background (best-effort)
      Future.microtask(() => _sync.processPending());
    }
  }
}
