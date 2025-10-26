import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _keyRegistered = 'is_registered';
  static const _keyUser = 'user_email';

  bool _isRegistered = false;
  String? _userEmail;

  bool get isRegistered => _isRegistered;
  String? get userEmail => _userEmail;
  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  AuthProvider() {
    _load();
  }

  Future<void> _load() async {
    final reg = await _storage.read(key: _keyRegistered);
    final email = await _storage.read(key: _keyUser);
    _isRegistered = reg == 'true';
    _userEmail = email;
    notifyListeners();
  }

  Future<void> register(String email, String password) async {
    // store a simple hashed password (local only)
    final hashed = sha256.convert(utf8.encode(password)).toString();
    await _storage.write(key: _keyUser, value: email);
    await _storage.write(key: 'pw_hash', value: hashed);
    await _storage.write(key: _keyRegistered, value: 'true');
    _isRegistered = true;
    _userEmail = email;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final stored = await _storage.read(key: _keyUser);
    final storedHash = await _storage.read(key: 'pw_hash');
    final hashed = sha256.convert(utf8.encode(password)).toString();
    if (stored == email && storedHash == hashed) {
      _isRegistered = true;
      _userEmail = email;
      notifyListeners();
      return true;
    }
    return false;
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
