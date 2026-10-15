import 'package:flutter/material.dart';

import '../services/moderation_service.dart';

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
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text('🚩 Signalements',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1D1E33),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _reload,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: FutureBuilder<List<ReportGroup>>(
        future: _groups,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Erreur : ${snap.error}',
                  style: const TextStyle(color: Colors.white70)),
            );
          }
          final groups = snap.data ?? [];
          if (groups.isEmpty) {
            return const Center(
              child: Text('Aucun signalement en attente 🎉',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: groups.length,
            itemBuilder: (_, i) => _buildCard(groups[i]),
          );
        },
      ),
    );
  }

  Widget _buildCard(ReportGroup g) {
    final status = switch (g.hidden) {
      true => ('Masqué', Colors.redAccent),
      false => ('Rétabli', Colors.greenAccent),
      null => ('Visible', Colors.amber),
    };
    return Card(
      color: const Color(0xFF1D1E33),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    g.displayName ?? g.reportedUid,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text(status.$1),
                  backgroundColor: status.$2.withValues(alpha: 0.2),
                  labelStyle: TextStyle(color: status.$2),
                ),
              ],
            ),
            Text(
              '${g.reporterCount} personne(s) • '
              '${g.reasons.entries.map((e) => '${_reasonLabels[e.key] ?? e.key} ×${e.value}').join(', ')}',
              style: const TextStyle(color: Colors.white70),
            ),
            SelectableText('UID : ${g.reportedUid}',
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
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
                  child: const Text('Rejeter les signalements'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
