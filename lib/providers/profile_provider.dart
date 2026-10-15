import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';
import '../services/firebase_sync_service.dart';
import '../services/analytics_service.dart';

class ProfileProvider extends ChangeNotifier {
  /// Au-delà, une écriture Firestore est considérée "en attente" : le SDK l'a
  /// déjà appliquée au cache local et l'enverra au retour du réseau.
  static const _serverAckTimeout = Duration(seconds: 10);

  UserProfile? _profile;
  final ProfileService _service;
  final FirebaseSyncService _firebaseSync;
  bool _syncing = false;

  ProfileProvider({ProfileService? service, FirebaseSyncService? firebaseSync})
      : _service = service ?? ProfileService(),
        _firebaseSync = firebaseSync ?? FirebaseSyncService();

  UserProfile? get profile => _profile;
  bool get syncing => _syncing;

  /// Charge le profil (local puis Firebase).
  ///
  /// Retourne `true` si l'état est fiable : soit un profil a été trouvé, soit
  /// Firebase a confirmé qu'il n'en existe pas. Retourne `false` si Firebase
  /// était injoignable et qu'aucun profil local n'existe : dans ce cas on ne
  /// doit pas forcer une nouvelle inscription (risque d'écraser le profil).
  Future<bool> load() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final local = await _service.loadLocal();
    // Ignorer un profil local appartenant à un autre compte (même appareil).
    if (local != null &&
        (currentUid == null || local.uid == null || local.uid == currentUid)) {
      _profile = local;
      notifyListeners();
    }

    if (!_firebaseSync.isUserAuthenticated) return _profile != null;
    final reached = await _syncFromFirebase();
    return reached || _profile != null;
  }

  /// Synchroniser le profil depuis Firebase.
  /// Retourne `false` si Firebase n'a pas pu être interrogé.
  Future<bool> _syncFromFirebase() async {
    _syncing = true;
    notifyListeners();

    try {
      final firebaseProfile =
          await _firebaseSync.getUserProfile(rethrowErrors: true);
      if (firebaseProfile != null) {
        _profile = firebaseProfile;
        await _service.saveLocally(_profile!);
        debugPrint('✅ Profil récupéré depuis Firebase');
        // Rattrapage : les profils publics créés avant `public_profiles`
        // n'y figurent pas encore.
        if (firebaseProfile.shouldBePublished) {
          try {
            await _firebaseSync
                .publishPublicProfile(firebaseProfile)
                .timeout(_serverAckTimeout);
          } catch (e) {
            debugPrint('⚠️ Publication du profil public: $e');
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint('❌ Erreur récupération profil Firebase: $e');
      return false;
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  /// Enregistre le profil (cache local + Firestore).
  ///
  /// Hors ligne, rend la main après [_serverAckTimeout] : l'écriture reste en
  /// file dans le SDK Firestore. Les autres erreurs (permissions...) sont
  /// propagées pour que l'écran puisse les afficher.
  Future<void> save(UserProfile p, {bool push = true}) async {
    _profile = p;
    _profile!.uid = FirebaseAuth.instance.currentUser?.uid ?? p.uid;

    await _service.saveLocally(_profile!);
    notifyListeners();

    AnalyticsService().logProfileUpdated(
      hasPhoto: false,
      isPublic: _profile!.isPublic,
    );

    if (!push || !_firebaseSync.isUserAuthenticated) return;
    _syncing = true;
    notifyListeners();
    try {
      await _firebaseSync
          .saveUserProfile(_profile!)
          .timeout(_serverAckTimeout);
    } on TimeoutException {
      debugPrint('📴 Profil enregistré hors ligne, synchronisé plus tard');
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  /// Forcer une synchronisation manuelle avec Firebase
  Future<bool> forceSyncWithFirebase() => _syncFromFirebase();

  /// Oublie le profil en mémoire et en cache local (déconnexion).
  Future<void> reset() async {
    _profile = null;
    await _service.clearLocal();
    notifyListeners();
  }

  /// Supprime le profil et les contacts côté Firebase.
  Future<void> deleteRemoteData() => _firebaseSync.deleteUserData();
}
