import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service pour gérer la connectivité réseau
/// Permet de détecter quand l'application est en ligne ou hors ligne
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final _connectionController = StreamController<bool>.broadcast();

  /// Stream qui émet true quand en ligne, false quand hors ligne
  Stream<bool> get onConnectivityChanged => _connectionController.stream;

  bool _isConnected = true;
  bool get isCurrentlyConnected => _isConnected;

  /// Vérifier si l'appareil est connecté à Internet
  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    final connected = _isOnline(result);
    _isConnected = connected;
    return connected;
  }

  /// Initialiser le service et écouter les changements de connectivité
  void initialize() {
    // Vérifier l'état initial
    isConnected();

    // Écouter les changements
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Prendre le premier résultat de la liste
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      final connected = _isOnline(result);
      
      if (_isConnected != connected) {
        _isConnected = connected;
        _connectionController.add(connected);
        
        if (connected) {
          print('🌐 ✅ Connexion rétablie');
        } else {
          print('🌐 ❌ Connexion perdue - Mode hors ligne');
        }
      }
    });
  }

  /// Déterminer si un résultat de connectivité signifie "en ligne"
  bool _isOnline(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }

  /// Nettoyer les ressources
  void dispose() {
    _connectionController.close();
  }
}
