import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/contact_provider.dart';
import '../providers/profile_provider.dart';
import '../services/messaging_service.dart';
import '../services/photo_service.dart';
import '../services/safety_service.dart';

/// Actions de compte partagées par les écrans (menu, profil).

Future<bool> _confirm(BuildContext context, String message,
    {required String action, bool destructive = false}) async {
  final loc = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(loc.translate('cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: destructive
              ? TextButton.styleFrom(
                  foregroundColor: Theme.of(ctx).colorScheme.error)
              : null,
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Efface l'état local de l'utilisateur et revient à l'onboarding.
Future<void> _clearLocalAndExit(BuildContext context) async {
  final navigator = Navigator.of(context);
  await context.read<ContactProvider>().reset();
  if (!context.mounted) return;
  await context.read<ProfileProvider>().reset();
  await SafetyService().clearLocalCache();
  PhotoService().clearCache();
  navigator.pushNamedAndRemoveUntil('/onboarding', (_) => false);
}

Future<void> signOut(BuildContext context) async {
  final loc = AppLocalizations.of(context);
  if (!await _confirm(context, loc.translate('logoutConfirm'),
      action: loc.translate('logout'))) {
    return;
  }
  if (!context.mounted) return;
  // Avant la déconnexion : il faut encore être authentifié pour retirer le
  // jeton de cet appareil.
  await MessagingService().unregister();
  if (!context.mounted) return;
  await context.read<AuthProvider>().logout();
  if (!context.mounted) return;
  await _clearLocalAndExit(context);
}

/// Suppression définitive du compte (exigée par Google Play et l'App Store).
///
/// Ordre : ré-authentification (connexion récente exigée par Firebase et
/// confirmation explicite), effacement des données Firestore, suppression du
/// compte Auth, puis nettoyage local.
Future<void> deleteAccount(BuildContext context) async {
  final loc = AppLocalizations.of(context);
  if (!await _confirm(context, loc.translate('deleteAccountConfirm'),
      action: loc.translate('deleteAccount'), destructive: true)) {
    return;
  }
  if (!context.mounted) return;
  final auth = context.read<AuthProvider>();
  final profile = context.read<ProfileProvider>();
  final messenger = ScaffoldMessenger.of(context);
  try {
    if (!await auth.reauthenticateWithGoogle()) return; // annulé
    await PhotoService().deleteMine();
    await profile.deleteRemoteData();
    await MessagingService().unregister();
    await auth.deleteFirebaseUser();
  } catch (e) {
    debugPrint('❌ Suppression du compte: $e');
    messenger.showSnackBar(
      SnackBar(content: Text(loc.translate('deleteAccountFailed'))),
    );
    return;
  }
  if (!context.mounted) return;
  await _clearLocalAndExit(context);
}
