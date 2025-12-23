import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
// Suppression du stockage local et du hashage, tout passe par Firebase Auth
import '../services/analytics_service.dart';

class AuthProvider extends ChangeNotifier {
  bool get isRegistered => FirebaseAuth.instance.currentUser != null;
  String? get userEmail => FirebaseAuth.instance.currentUser?.email;
  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  AuthProvider();

  Future<void> register(String email, String password) async {
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Analytics: Set user ID
      final uid = cred.user?.uid;
      if (uid != null) {
        AnalyticsService().setUserId(uid);
      }
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
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
      // ignore errors here, upstream code should handle null uid
      return null;
    }
  }
}
