import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/db_helper.dart';
import 'connectivity_service.dart';
import 'analytics_service.dart';
import 'dart:convert';

/// Service de gestion de la queue de synchronisation
/// Permet de mettre en queue les opérations quand hors ligne
/// et de les traiter automatiquement quand la connexion revient
class SyncQueueService {
  static final SyncQueueService _instance = SyncQueueService._internal();
  factory SyncQueueService() => _instance;
  SyncQueueService._internal();

  final DBHelper _db = DBHelper();
  final ConnectivityService _connectivity = ConnectivityService();
  final AnalyticsService _analytics = AnalyticsService();

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  /// Initialiser le service
  Future<void> initialize() async {
    // Écouter les changements de connectivité
    _connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline && !_isProcessing) {
        processSyncQueue();
      }
    });

    // Traiter la queue au démarrage si en ligne
    if (await _connectivity.isConnected()) {
      processSyncQueue();
    }
  }

  /// Ajouter une opération à la queue
  Future<void> addToQueue({
    required String action,
    required Map<String, dynamic> data,
    String? userId,
  }) async {
    try {
      await _db.addToSyncQueue(
        action: action,
        data: jsonEncode(data),
        userId: userId,
      );
      
      print('📤 Opération ajoutée à la queue: $action');

      // Si en ligne, traiter immédiatement
      if (await _connectivity.isConnected() && !_isProcessing) {
        processSyncQueue();
      }
    } catch (e) {
      print('❌ Erreur ajout queue: $e');
    }
  }

  /// Traiter toute la queue de synchronisation
  Future<void> processSyncQueue() async {
    if (_isProcessing) {
      print('⏳ Sync déjà en cours, skip');
      return;
    }

    if (!await _connectivity.isConnected()) {
      print('⚠️ Pas de connexion, sync annulée');
      return;
    }

    _isProcessing = true;
    print('🔄 Traitement de la queue de synchronisation...');

    try {
      _analytics.logSyncTriggered();

      final items = await _db.getNextSyncItems(limit: 50);
      print('📥 ${items.length} éléments à synchroniser');

      int successCount = 0;
      int failedCount = 0;

      for (final item in items) {
        try {
          await _processItem(item);
          await _db.markSyncItemDone(item['id'] as int);
          successCount++;
          print('✅ Sync réussie: ${item['action']} (${item['id']})');
        } catch (e) {
          failedCount++;
          await _db.markSyncItemFailed(item['id'] as int, e.toString());
          print('❌ Erreur sync ${item['action']}: $e');
        }

        // Pause pour éviter de surcharger Firebase
        await Future.delayed(Duration(milliseconds: 100));
      }

      print('🎉 Sync terminée: $successCount succès, $failedCount échecs');

      if (successCount > 0) {
        _analytics.logSyncCompleted(
          success: true,
          itemCount: successCount,
        );
      }
    } catch (e) {
      print('💥 Erreur fatale lors de la sync: $e');
      _analytics.logError(
        errorMessage: 'Sync queue error: $e',
        fatal: false,
      );
    } finally {
      _isProcessing = false;
    }
  }

  /// Traiter un élément de la queue
  Future<void> _processItem(Map<String, dynamic> item) async {
    final action = item['action'] as String;
    final dataStr = item['data'] as String;
    final userId = item['userId'] as String?;

    Map<String, dynamic> data;
    try {
      data = jsonDecode(dataStr);
    } catch (e) {
      throw Exception('Invalid JSON data: $e');
    }

    print('🔧 Processing: $action for user $userId');

    switch (action) {
      case 'add_contact':
        await _addContactToFirestore(data, userId);
        break;

      case 'update_contact':
        await _updateContactInFirestore(data, userId);
        break;

      case 'delete_contact':
        await _deleteContactFromFirestore(data, userId);
        break;

      case 'update_profile':
        await _updateProfileInFirestore(data, userId);
        break;

      case 'add_message':
        // Ajouter d'autres actions selon vos besoins
        break;

      default:
        print('⚠️ Action inconnue: $action');
    }
  }

  /// Ajouter un contact dans Firestore
  Future<void> _addContactToFirestore(
      Map<String, dynamic> data, String? userId) async {
    if (userId == null) throw Exception('userId requis pour add_contact');

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .add(data);
  }

  /// Mettre à jour un contact dans Firestore
  Future<void> _updateContactInFirestore(
      Map<String, dynamic> data, String? userId) async {
    if (userId == null) throw Exception('userId requis pour update_contact');

    final contactId = data['id'];
    if (contactId == null) throw Exception('contactId requis');

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .doc(contactId.toString())
        .update(data);
  }

  /// Supprimer un contact de Firestore
  Future<void> _deleteContactFromFirestore(
      Map<String, dynamic> data, String? userId) async {
    if (userId == null) throw Exception('userId requis pour delete_contact');

    final contactId = data['id'];
    if (contactId == null) throw Exception('contactId requis');

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .doc(contactId.toString())
        .delete();
  }

  /// Mettre à jour le profil dans Firestore
  Future<void> _updateProfileInFirestore(
      Map<String, dynamic> data, String? userId) async {
    if (userId == null) throw Exception('userId requis pour update_profile');

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update(data);
  }

  /// Obtenir le nombre d'éléments en attente
  Future<int> getPendingCount() async {
    final items = await _db.getNextSyncItems(limit: 1000);
    return items.length;
  }

  /// Vider toute la queue (utile pour debug)
  Future<void> clearQueue() async {
    final db = await _db.database;
    await db.delete('sync_queue');
    print('🗑️ Queue de synchronisation vidée');
  }
}
