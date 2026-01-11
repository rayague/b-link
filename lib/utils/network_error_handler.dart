import 'package:flutter/material.dart';

/// Classe utilitaire pour gérer les erreurs réseau et Firebase
class NetworkErrorHandler {
  /// Afficher un SnackBar d'erreur
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Réessayer',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Afficher un dialogue d'erreur avec options
  static Future<bool?> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    bool showRetry = true,
  }) async {
    if (!context.mounted) return null;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          if (showRetry)
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: showRetry ? Colors.blue : Colors.red[700],
            ),
            child: Text(showRetry ? 'Réessayer' : 'OK'),
          ),
        ],
      ),
    );
  }

  /// Gérer les erreurs Firebase communes
  static String getFirebaseErrorMessage(dynamic error) {
    final errorMessage = error.toString().toLowerCase();

    if (errorMessage.contains('network')) {
      return 'Erreur réseau. Vérifiez votre connexion Internet.';
    } else if (errorMessage.contains('permission')) {
      return 'Permission refusée. Vérifiez vos droits d\'accès.';
    } else if (errorMessage.contains('not-found')) {
      return 'Ressource introuvable.';
    } else if (errorMessage.contains('timeout')) {
      return 'Délai d\'attente dépassé. Veuillez réessayer.';
    } else if (errorMessage.contains('unavailable')) {
      return 'Service temporairement indisponible.';
    } else if (errorMessage.contains('unauthenticated')) {
      return 'Vous devez être connecté pour effectuer cette action.';
    } else if (errorMessage.contains('already-exists')) {
      return 'Cette ressource existe déjà.';
    } else {
      return 'Une erreur est survenue. Veuillez réessayer.';
    }
  }

  /// Exécuter une opération avec gestion d'erreur et retry automatique
  static Future<T?> executeWithRetry<T>({
    required Future<T> Function() operation,
    required BuildContext context,
    String errorMessage = 'Une erreur est survenue',
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
    bool showErrorDialog = false,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;

        if (attempts >= maxRetries) {
          // Dernière tentative échouée
          final message = getFirebaseErrorMessage(e);

          if (showErrorDialog) {
            await NetworkErrorHandler.showErrorDialog(
              context,
              title: 'Erreur',
              message: message,
              showRetry: false,
            );
          } else {
            if (context.mounted) {
              showErrorSnackBar(context, message);
            }
          }
          return null;
        }

        // Attendre avant de réessayer
        await Future.delayed(retryDelay);
      }
    }

    return null;
  }

  /// Vérifier si l'appareil est en ligne (simple check)
  static Future<bool> isOnline() async {
    try {
      // Note: Pour une vraie vérification, il faudrait utiliser connectivity_plus
      // Ici, on fait une simple tentative de connexion
      return true; // Placeholder
    } catch (e) {
      return false;
    }
  }

  /// Afficher un message d'avertissement pour mode hors ligne
  static void showOfflineWarning(BuildContext context) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.cloud_off, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Mode hors ligne. Certaines fonctionnalités peuvent être limitées.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
