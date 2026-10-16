import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

      // Volontairement aucun AnalyticsService().setUserId : les statistiques
      // ne sont pas reliées au compte (voir hosting/privacy.html).
      if (userCredential.user == null) return false;
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

  /// Ré-authentifie l'utilisateur avec Google. Firebase exige une connexion
  /// récente pour supprimer un compte ; cela sert aussi de confirmation.
  /// Retourne `false` si l'utilisateur annule.
  Future<bool> reauthenticateWithGoogle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      await _ensureGoogleInitialized();
      final googleUser = await GoogleSignIn.instance.authenticate();
      final credential = GoogleAuthProvider.credential(
        idToken: googleUser.authentication.idToken,
      );
      await user.reauthenticateWithCredential(credential);
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      rethrow;
    }
  }

  /// Supprime le compte Firebase Auth (à appeler après
  /// [reauthenticateWithGoogle] et après l'effacement des données).
  Future<void> deleteFirebaseUser() async {
    await FirebaseAuth.instance.currentUser?.delete();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    notifyListeners();
  }
}
