import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';

/// Demande le consentement aux statistiques d'utilisation (RGPD), une seule
/// fois. "Accepter" et "Refuser" ont le même poids visuel (exigence CNIL) et
/// la boîte ne se ferme qu'en faisant un choix.
Future<void> askAnalyticsConsentIfNeeded(BuildContext context) async {
  final analytics = AnalyticsService();
  if (!analytics.needsConsentDecision) return;
  final l10n = AppLocalizations.of(context);
  final granted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(l10n.translate('consentTitle')),
        content: Text(l10n.translate('consentBody')),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.translate('consentDecline')),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.translate('consentAccept')),
          ),
        ],
      ),
    ),
  );
  await analytics.setConsent(granted ?? false);
}
