import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Service centralisé pour Firebase Analytics
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analyticsInstance;
  bool _initFailed = false;

  /// Lazy-init to avoid crash when Firebase is not initialized (e.g. in tests)
  FirebaseAnalytics? get _analytics {
    if (_initFailed) return null;
    try {
      return _analyticsInstance ??= FirebaseAnalytics.instance;
    } catch (_) {
      _initFailed = true;
      return null;
    }
  }

  /// Observer pour navigation automatique
  FirebaseAnalyticsObserver getAnalyticsObserver() {
    return FirebaseAnalyticsObserver(analytics: _analytics ?? FirebaseAnalytics.instance);
  }

  // ========== TRACKING ÉCRANS ==========

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics?.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
    debugPrint('📊 Analytics: Screen viewed - $screenName');
  }

  // ========== ÉVÉNEMENTS CONTACTS ==========

  /// Contact ajouté
  Future<void> logContactAdded({
    required String relation,
    bool hasPhone = false,
  }) async {
    await _analytics?.logEvent(
      name: 'contact_added',
      parameters: {
        'relation': relation,
        'has_phone': hasPhone,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('📊 Analytics: Contact added - $relation');
  }

  /// Contact modifié
  Future<void> logContactUpdated({
    required String relation,
  }) async {
    await _analytics?.logEvent(
      name: 'contact_updated',
      parameters: {
        'relation': relation,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Contact supprimé
  Future<void> logContactDeleted({
    required String relation,
  }) async {
    await _analytics?.logEvent(
      name: 'contact_deleted',
      parameters: {
        'relation': relation,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ========== ÉVÉNEMENTS PROFIL ==========

  /// Profil mis à jour
  Future<void> logProfileUpdated({
    bool hasPhoto = false,
    bool isPublic = false,
  }) async {
    await _analytics?.logEvent(
      name: 'profile_updated',
      parameters: {
        'has_photo': hasPhoto,
        'is_public': isPublic,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('📊 Analytics: Profile updated');
  }

  // ========== ÉVÉNEMENTS MESSAGES ==========

  /// Message d'anniversaire généré
  Future<void> logBirthdayMessageGenerated({
    required String relation,
    int? messageLength,
  }) async {
    await _analytics?.logEvent(
      name: 'birthday_message_generated',
      parameters: {
        'relation': relation,
        'message_length': messageLength ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('📊 Analytics: Birthday message generated - $relation');
  }

  /// Message copié
  Future<void> logMessageCopied({
    required String relation,
  }) async {
    await _analytics?.logEvent(
      name: 'message_copied',
      parameters: {
        'relation': relation,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ========== ÉVÉNEMENTS APPELS ==========

  /// Appel initié
  Future<void> logCallInitiated({
    required String relation,
    bool hasPhone = false,
  }) async {
    await _analytics?.logEvent(
      name: 'call_initiated',
      parameters: {
        'relation': relation,
        'has_phone': hasPhone,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('📊 Analytics: Call initiated - $relation');
  }

  // ========== ÉVÉNEMENTS ADMIN ==========

  /// Admin login
  Future<void> logAdminLogin({
    required String adminRole,
  }) async {
    await _analytics?.logEvent(
      name: 'admin_login',
      parameters: {
        'admin_role': adminRole,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    debugPrint('📊 Analytics: Admin login - $adminRole');
  }

  /// Admin action
  Future<void> logAdminAction({
    required String action,
  }) async {
    await _analytics?.logEvent(
      name: 'admin_action',
      parameters: {
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ========== ÉVÉNEMENTS SYNC ==========

  /// Synchronisation déclenchée
  Future<void> logSyncTriggered({
    int? itemCount,
    bool isManual = false,
  }) async {
    await _analytics?.logEvent(
      name: 'sync_triggered',
      parameters: {
        'item_count': itemCount ?? 0,
        'is_manual': isManual ? 1 : 0,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Synchronisation réussie
  Future<void> logSyncCompleted({
    int? syncedItems,
    int? failedItems,
  }) async {
    await _analytics?.logEvent(
      name: 'sync_completed',
      parameters: {
        'synced_items': syncedItems ?? 0,
        'failed_items': failedItems ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ========== ÉVÉNEMENTS NAVIGATION ==========

  /// Navigation vers profil public
  Future<void> logPublicProfileViewed() async {
    await _analytics?.logEvent(
      name: 'public_profile_viewed',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Navigation vers zodiac
  Future<void> logZodiacViewed({
    required String zodiacSign,
  }) async {
    await _analytics?.logEvent(
      name: 'zodiac_viewed',
      parameters: {
        'zodiac_sign': zodiacSign,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Navigation vers same day
  Future<void> logSameDayViewed({
    int? userCount,
  }) async {
    await _analytics?.logEvent(
      name: 'same_day_viewed',
      parameters: {
        'user_count': userCount ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ========== ÉVÉNEMENTS ERREURS ==========

  /// Log d'erreur
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? screenName,
  }) async {
    await _analytics?.logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage.substring(
            0, errorMessage.length > 100 ? 100 : errorMessage.length),
        'screen_name': screenName ?? 'unknown',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // ========== USER PROPERTIES ==========

  /// Définir l'ID utilisateur
  Future<void> setUserId(String? userId) async {
    await _analytics?.setUserId(id: userId);
  }

  /// Définir une propriété utilisateur
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics?.setUserProperty(
      name: name,
      value: value,
    );
  }
}
