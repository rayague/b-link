import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

/// Notifications push (Firebase Cloud Messaging) : "nouveau jumeau
/// d'anniversaire", envoyées par la Cloud Function onPublicProfileCreated.
///
/// Le jeton de l'appareil est stocké dans users/{uid}/devices/{jeton} (privé)
/// avec la langue de l'app, pour que le serveur écrive dans la bonne langue.
class MessagingService {
  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;
  MessagingService._internal();

  static const typeNewTwin = 'new_twin';
  static const typeWish = 'wish';

  /// Écran ouvert au toucher d'une notification, selon son type.
  static String? routeFor(Map<String, dynamic> data) => switch (data['type']) {
        typeNewTwin => '/same-day',
        typeWish => '/wishes',
        _ => null,
      };

  String? _token;
  String _locale = 'en';
  StreamSubscription<String>? _refreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;

  final _openRoute = StreamController<String>.broadcast();

  /// Émis quand l'utilisateur touche une notification push : l'écran à
  /// ouvrir.
  Stream<String> get openRouteRequests => _openRoute.stream;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? _deviceRef(String token) {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(token);
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    await _deviceRef(token)?.set({
      'platform': kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android'),
      'locale': _locale,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// À appeler une fois connecté. Sans risque si Firebase n'est pas
  /// disponible : l'app continue sans notifications push.
  Future<void> register(String locale) async {
    _locale = locale == 'fr' ? 'fr' : 'en';
    if (_uid == null) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(); // iOS (Android 13+ : déjà demandé)
      final token = await messaging.getToken();
      if (token != null) await _saveToken(token);

      _refreshSub ??= messaging.onTokenRefresh.listen((fresh) async {
        final old = _token;
        await _saveToken(fresh);
        if (old != null && old != fresh) await _deviceRef(old)?.delete();
      });

      // App au premier plan : FCM n'affiche rien, on passe par une
      // notification locale (le toucher ouvre "Même jour").
      _foregroundSub ??= FirebaseMessaging.onMessage.listen((message) {
        final n = message.notification;
        if (n == null) return;
        NotificationService().showPush(
          title: n.title ?? '',
          body: n.body ?? '',
          route: routeFor(message.data),
        );
      });

      _openedSub ??= FirebaseMessaging.onMessageOpenedApp.listen(_handleOpened);
      final initial = await messaging.getInitialMessage();
      if (initial != null) _handleOpened(initial);
    } catch (e) {
      debugPrint('⚠️ Notifications push indisponibles: $e');
    }
  }

  void _handleOpened(RemoteMessage message) {
    final route = routeFor(message.data);
    if (route != null) _openRoute.add(route);
  }

  /// La langue de l'app a changé : les prochaines notifications suivent.
  Future<void> updateLocale(String locale) async {
    _locale = locale == 'fr' ? 'fr' : 'en';
    final token = _token;
    if (token == null) return;
    try {
      await _saveToken(token);
    } catch (e) {
      debugPrint('⚠️ Langue des notifications non mise à jour: $e');
    }
  }

  /// Déconnexion : cet appareil ne doit plus recevoir les notifications du
  /// compte (à appeler avant la déconnexion Firebase).
  Future<void> unregister() async {
    final token = _token;
    try {
      if (token != null) await _deviceRef(token)?.delete();
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('⚠️ Désinscription des notifications: $e');
    } finally {
      _token = null;
    }
  }

  /// Préférence "Me prévenir des nouveaux jumeaux" (activée par défaut),
  /// lue par la Cloud Function sur le document users/{uid}.
  Future<bool> notifyNewTwins() async {
    final uid = _uid;
    if (uid == null) return true;
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.data()?['notifyNewTwins'] != false;
    } catch (_) {
      return true;
    }
  }

  Future<void> setNotifyNewTwins(bool enabled) async {
    final uid = _uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'notifyNewTwins': enabled}, SetOptions(merge: true));
  }
}
