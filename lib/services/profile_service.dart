import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

/// Cache local du profil (affichage immédiat au démarrage, même hors ligne).
///
/// La source de vérité est Firestore (`users/{uid}`), dont le SDK gère lui-même
/// le cache et la file d'écriture hors ligne.
class ProfileService {
  static const _prefsKey = 'user_profile_json';

  Future<void> saveLocally(UserProfile profile) async {
    profile.birthDayKey = UserProfile.dayKeyOf(profile.birthDate);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, profile.toEncodedJson());
  }

  Future<void> clearLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  Future<UserProfile?> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_prefsKey);
    if (s == null) return null;
    try {
      return UserProfile.fromJson(json.decode(s) as Map<String, dynamic>);
    } catch (_) {
      return null; // cache corrompu : Firestore reste la référence
    }
  }
}
