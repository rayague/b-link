import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import 'db_helper.dart';

class ProfileService {
  static const _prefsKey = 'user_profile_json';

  final FirebaseFirestore? firestore;

  ProfileService({this.firestore});

  Future<void> saveLocally(UserProfile profile) async {
    // keep SharedPreferences for quick access
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, profile.toEncodedJson());
    // also persist to SQLite for offline queries and robust storage
    try {
      final db = DBHelper();
      // compute birthDayKey MM-DD
      profile.birthDayKey = '${profile.birthDate.month.toString().padLeft(2, '0')}-${profile.birthDate.day.toString().padLeft(2,'0')}';
      await db.upsertProfileToDb(profile);
      // enqueue sync for Firestore
      await db.enqueueSync('upsert_profile', profile.uid, profile.toEncodedJson());
    } catch (_) {
      // If DB is unavailable in test environment, ignore and keep SharedPreferences as primary
    }
  }

  Future<UserProfile?> loadLocal() async {
    // try SharedPreferences first
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_prefsKey);
    if (s != null) {
      try {
        final Map<String, dynamic> jsonMap = json.decode(s) as Map<String, dynamic>;
        return UserProfile.fromJson(jsonMap);
      } catch (_) {}
    }
    // fallback to SQLite if SP missing
    final db = DBHelper();
    // prefer anonymous current user uid if available
    // we leave uid handling to caller; attempt to fetch first profile if any
    final items = await db.database.then((d) => d.query('profiles', limit: 1));
    if (items.isEmpty) return null;
    try {
      final parsed = items.first;
      return await db.getProfileByUid(parsed['uid'] as String);
    } catch (_) {
      return null;
    }
  }

  /// Push profile to Firestore under collection `profiles` with doc id = uid or auto
  Future<void> pushToFirestore(UserProfile profile) async {
    if (firestore == null) return;
    final collection = firestore!.collection('profiles');
    final docRef = (profile.uid == null || profile.uid!.isEmpty) ? collection.doc() : collection.doc(profile.uid);
    final data = profile.toJson();
    data['lastSyncedAt'] = DateTime.now().toIso8601String();
    await docRef.set(data, SetOptions(merge: true));
    // update local DB lastSyncedAt
    try {
      final db = DBHelper();
      // ensure birthDayKey is saved
      if (profile.birthDayKey == null || profile.birthDayKey!.isEmpty) {
        profile.birthDayKey = '${profile.birthDate.month.toString().padLeft(2,'0')}-${profile.birthDate.day.toString().padLeft(2,'0')}';
      }
      await db.upsertProfileToDb(profile);
      await db.setProfileLastSynced(profile.uid ?? '', data['lastSyncedAt']);
    } catch (_) {}
  }

  Future<UserProfile?> fetchFromFirestore(String uid) async {
    if (firestore == null) return null;
    final doc = await firestore!.collection('profiles').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromJson(doc.data()!);
  }
}
