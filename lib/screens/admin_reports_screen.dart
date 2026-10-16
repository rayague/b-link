import 'package:flutter/material.dart';

import '../services/moderation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/components.dart';
import '../widgets/ui/glass.dart';

/// Écran admin : profils signalés, avec masquage / rétablissement.
/// (Écran réservé aux admins, en français comme le reste de l'administration.)
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final _service = ModerationService();
  late Future<List<ReportGroup>> _groups = _service.reportGroups();

  static const _reasonLabels = {
    'spam': 'Spam',
    'inappropriate': 'Inapproprié',
    'fake': 'Faux profil',
    'minor': 'Mineur',
    'other': 'Autre',
  };

  void _reload() => setState(() => _groups = _service.reportGroups());

  Future<void> _run(Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Échec : $e')));
    }
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final padding = AppScaffold.pagePadding(context);
    return AppScaffold(
      title: const Text('Signalements'),
      body: RefreshIndicator(
        edgeOffset: padding.top,
        onRefresh: () async {
          _reload();
          await _groups;
        },
        child: FutureBuilder<List<ReportGroup>>(
          future: _groups,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final groups = snap.data ?? const <ReportGroup>[];
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: padding,
              children: [
                if (snap.hasError)
                  NoticeCard(
                      icon: Icons.error_outline_rounded,
                      text: 'Erreur : ${snap.error}',
                      tone: Tone.danger)
                else if (groups.isEmpty)
                  const GlassCard(
                    child: EmptyState(
                        icon: Icons.verified_outlined,
                        title: 'Aucun signalement en attente'),
                  ),
                for (final g in groups) ...[
                  _card(g),
                  const SizedBox(height: Space.s),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _card(ReportGroup g) {
    final t = Theme.of(context).textTheme;
    final (label, tone) = switch (g.hidden) {
      true => ('Masqué', Tone.danger),
      false => ('Rétabli', Tone.primary),
      null => ('Visible', Tone.accent),
    };
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(g.displayName ?? g.reportedUid,
                    style: t.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Pill(label, tone: tone),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(
            '${g.reporterCount} personne(s) · '
            '${g.reasons.entries.map((e) => '${_reasonLabels[e.key] ?? e.key} ×${e.value}').join(', ')}',
            style: t.bodyMedium,
          ),
          SelectableText(g.reportedUid,
              style: t.bodySmall?.copyWith(fontFamily: 'monospace')),
          const SizedBox(height: Space.s),
          Wrap(
            spacing: Space.s,
            children: [
              if (g.hidden != true)
                FilledButton.tonal(
                  onPressed: () => _run(() => _service.hide(g.reportedUid),
                      'Profil masqué de l\'annuaire'),
                  child: const Text('Masquer'),
                ),
              if (g.hidden == true)
                FilledButton.tonal(
                  onPressed: () => _run(
                      () => _service.restore(g.reportedUid), 'Profil rétabli'),
                  child: const Text('Rétablir'),
                ),
              TextButton(
                onPressed: () => _run(
                    () => _service.dismissReports(g.reportedUid),
                    'Signalements classés'),
                child: const Text('Rejeter'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
