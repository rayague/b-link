import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/sync_service.dart';
import '../services/firebase_sync_service.dart';
import '../services/db_helper.dart';

class ProfileProvider extends ChangeNotifier {
  UserProfile? _profile;
  final ProfileService _service;
  final SyncService _sync;
  final FirebaseSyncService _firebaseSync;
  bool _syncing = false;

  ProfileProvider(
      {ProfileService? service,
      SyncService? sync,
      FirebaseSyncService? firebaseSync})
      : _service = service ?? ProfileService(firestore: null),
        _sync = sync ?? SyncService(),
        _firebaseSync = firebaseSync ?? FirebaseSyncService(DBHelper());

  UserProfile? get profile => _profile;
  bool get syncing => _syncing;

  Future<void> load() async {
    final local = await _service.loadLocal();
    if (local != null) {
      _profile = local;
      notifyListeners();
    }

    // Tenter de récupérer depuis Firebase si connecté
    if (_firebaseSync.isUserAuthenticated) {
      await _syncFromFirebase();
    }
  }

  /// Synchroniser le profil depuis Firebase
  Future<void> _syncFromFirebase() async {
    _syncing = true;
    notifyListeners();

    try {
      final firebaseProfile = await _firebaseSync.getUserProfile();
      if (firebaseProfile != null) {
        _profile = firebaseProfile;
        await _service.saveLocally(_profile!);
        notifyListeners();
        print('✅ Profil récupéré depuis Firebase');
      }
    } catch (e) {
      print('❌ Erreur récupération profil Firebase: $e');
    } finally {
      _syncing = false;
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
      // Sauvegarder dans Firebase
      if (_firebaseSync.isUserAuthenticated) {
        _syncing = true;
        notifyListeners();

        try {
          await _firebaseSync.saveUserProfile(_profile!);
          print('✅ Profil sauvegardé dans Firebase');
        } catch (e) {
          print('❌ Erreur sauvegarde profil Firebase: $e');
        } finally {
          _syncing = false;
          notifyListeners();
        }
      }

      // Attempt to push immediately and also process the local queue (ancien système)
      try {
        await _service.pushToFirestore(_profile!);
      } catch (_) {}
      // process pending queue in background (best-effort)
      Future.microtask(() => _sync.processPending());
    }
  }

  /// Forcer une synchronisation manuelle avec Firebase
  Future<void> forceSyncWithFirebase() async {
    await _syncFromFirebase();
  }
}
