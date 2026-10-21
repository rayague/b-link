import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/safety_service.dart';
import '../theme/app_theme.dart';
import 'ui/components.dart';
import 'ui/glass.dart';

/// Liste des profils bloqués, avec déblocage.
Future<void> showBlockedProfilesSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final safety = SafetyService();
  return showGlassSheet<void>(
    context,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setSheet) => FutureBuilder<List<BlockedProfile>>(
        future: safety.blockedProfiles(),
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(Space.xxl),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final blocked = snap.data ?? const <BlockedProfile>[];
          return Padding(
            padding:
                const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.translate('blockedProfiles'),
                    style: Theme.of(sheet).textTheme.titleLarge),
                const SizedBox(height: Space.s),
                if (blocked.isEmpty)
                  EmptyState(
                      icon: Icons.block_outlined,
                      title: l10n.translate('noBlockedProfiles'))
                else
                  for (final b in blocked)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: InitialsAvatar(name: b.name ?? '?', size: 40),
                      title: Text(b.name ?? l10n.translate('anonymousProfile')),
                      trailing: TextButton(
                        onPressed: () async {
                          await safety.unblock(b.uid);
                          setSheet(() {}); // recharge la liste
                        },
                        child: Text(l10n.translate('unblock')),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
