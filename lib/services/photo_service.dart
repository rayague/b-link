import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Photos de profil (Firebase Storage, voir storage.rules).
///
/// Les photos sont lues octet par octet via le SDK, jamais par une URL de
/// téléchargement : ces URL contournent les règles et resteraient valides
/// après qu'une photo a cessé d'être partagée.
class PhotoService {
  static final PhotoService _instance = PhotoService._internal();
  factory PhotoService() => _instance;
  PhotoService._internal();

  /// Taille max côté (px) et qualité JPEG : environ 30 à 80 Ko par photo.
  static const int maxSide = 512;
  static const int quality = 75;
  static const int _maxBytes = 1024 * 1024; // storage.rules : < 1 Mo

  final Map<String, Uint8List?> _cache = {};

  static String pathFor(String uid) => 'profile_photos/$uid/photo.jpg';

  Reference _ref(String uid) => FirebaseStorage.instance.ref(pathFor(uid));

  /// Choisit une photo dans la galerie, la réduit et l'envoie. Retourne
  /// false si l'utilisateur a annulé.
  Future<bool> pickAndUpload() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Utilisateur non connecté');
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: maxSide.toDouble(),
      maxHeight: maxSide.toDouble(),
      imageQuality: quality,
    );
    if (picked == null) return false;
    final bytes = await picked.readAsBytes();
    if (bytes.length >= _maxBytes) {
      throw StateError('Photo trop lourde (${bytes.length} octets)');
    }
    await _ref(uid).putData(
        bytes, SettableMetadata(contentType: contentTypeFor(picked.name)));
    _cache[uid] = bytes;
    return true;
  }

  @visibleForTesting
  static String contentTypeFor(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  /// Supprime la photo de l'utilisateur connecté (absente : sans erreur).
  Future<void> deleteMine() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _ref(uid).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
    _cache[uid] = null;
  }

  /// Octets de la photo de [uid], ou null si absente ou non partagée.
  Future<Uint8List?> bytesFor(String uid) async {
    if (_cache.containsKey(uid)) return _cache[uid];
    try {
      final data = await _ref(uid).getData(_maxBytes);
      _cache[uid] = data;
      return data;
    } catch (_) {
      // Pas de photo, ou plus partagée : on affiche l'initiale.
      _cache[uid] = null;
      return null;
    }
  }

  /// Oublie le cache (déconnexion : le compte suivant ne doit pas en hériter).
  void clearCache() => _cache.clear();
}
