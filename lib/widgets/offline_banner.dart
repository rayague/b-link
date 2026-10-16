import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/connectivity_service.dart';
import '../theme/app_theme.dart';

/// Bandeau discret affiché en bas de l'accueil quand l'appareil est hors
/// ligne ; il disparaît au retour du réseau.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityService().onConnectivityChanged,
      initialData: ConnectivityService().isCurrentlyConnected,
      builder: (context, snapshot) {
        final online = snapshot.data ?? true;
        final c = Theme.of(context).colorScheme;
        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: online
              ? const SizedBox(width: double.infinity)
              : SafeArea(
                  top: false,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(
                        Space.l, 0, Space.l, Space.s),
                    padding: const EdgeInsets.symmetric(
                        horizontal: Space.l, vertical: Space.m),
                    decoration: BoxDecoration(
                      color: c.inverseSurface,
                      borderRadius: BorderRadius.circular(Radii.control),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_off_rounded,
                            size: 18, color: c.onInverseSurface),
                        const SizedBox(width: Space.m),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)
                                .translate('offlineBanner'),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: c.onInverseSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
