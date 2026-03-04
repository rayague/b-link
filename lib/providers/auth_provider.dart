import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/analytics_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _googleInitialized = false;

  bool get isRegistered => FirebaseAuth.instance.currentUser != null;
  String? get userEmail => FirebaseAuth.instance.currentUser?.email;
  String? get userId => FirebaseAuth.instance.currentUser?.uid;
  String? get displayName => FirebaseAuth.instance.currentUser?.displayName;
  String? get photoUrl => FirebaseAuth.instance.currentUser?.photoURL;

  AuthProvider();

  /// Initialise le SDK GoogleSignIn une seule fois.
  Future<void> _ensureGoogleInitialized() async {
    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize();
      _googleInitialized = true;
    }
  }

  /// Sign in with Google and link to Firebase Auth.
  /// Returns `true` on success, `false` if the user cancelled or an error occurred.
  Future<bool> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();

      final googleUser = await GoogleSignIn.instance.authenticate();

      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final uid = userCredential.user?.uid;
      if (uid != null) {
        AnalyticsService().setUserId(uid);
      }
      notifyListeners();
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return false; // user cancelled
      }
      debugPrint('Google sign-in error: $e');
      return false;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      return false;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Google sign-out may fail if not initialized; ignore.
    }
    await FirebaseAuth.instance.signOut();
    notifyListeners();
  }

  /// Ensure there is an anonymous Firebase user. Returns the UID.
  Future<String?> ensureAnonymousUser() async {
    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current != null) return current.uid;
      final cred = await FirebaseAuth.instance.signInAnonymously();
      return cred.user?.uid;
    } catch (e) {
      return null;
    }
  }
}
