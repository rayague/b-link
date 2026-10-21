import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/contact.dart';
import '../services/admin_service.dart';
import '../services/analytics_service.dart';
import '../services/firebase_sync_service.dart';
import '../services/message_repository.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/components.dart';
import '../widgets/ui/glass.dart';
import 'admin_reports_screen.dart';

/// Administration : statistiques globales et utilisateurs inscrits.
/// Réservé aux comptes présents dans la collection `admins` (vérifié ici et
/// par les règles Firestore). Écran interne, en français.
class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  final _firebaseSync = FirebaseSyncService();
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _users = const [];
  bool _loading = true;
  bool _authorized = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'AdminStatsScreen');
    AnalyticsService().logAdminLogin(adminRole: 'admin');
    _checkAuthorization();
  }

  Future<void> _checkAuthorization() async {
    final user = FirebaseAuth.instance.currentUser;
    final admin = AdminService();
    final ok = user != null && await admin.isUserAdmin(user.uid);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _authorized = false;
        _loading = false;
      });
      return;
    }
    await admin.updateLastLogin(user.uid);
    if (!mounted) return;
    setState(() => _authorized = true);
    await _load();
  }

  Future<void> _load() async {
    if (!_authorized) return;
    setState(() => _loading = true);
    try {
      final stats = await _firebaseSync.getGlobalStats();
      final users = await _firebaseSync.getAllUsers();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _users = users;
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement données admin: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Envoie une notification d'exemple avec un vrai message de la banque.
  Future<void> _testNotification() async {
    final category = await showGlassSheet<String>(
      context,
      builder: (sheet) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Test de notification',
                style: Theme.of(sheet).textTheme.titleLarge),
            const SizedBox(height: Space.xs),
            Text('Catégorie du message d\'exemple :',
                style: Theme.of(sheet).textTheme.bodySmall),
            const SizedBox(height: Space.s),
            for (final (code, label) in const [
              ('son', 'Fils'),
              ('daughter', 'Fille'),
              ('friend', 'Ami(e)'),
              ('mother', 'Mère'),
              ('father', 'Père'),
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(label),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(sheet).pop(code),
              ),
          ],
        ),
      ),
    );
    if (category == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final message =
          await MessageRepository().getRandomForRelation(category, 'Contact Test');
      await NotificationService().sendTestNotificationWithMessage(
        contact: Contact(
          name: 'Contact Test ($category)',
          date: DateTime.now().toIso8601String(),
          relation: category,
        ),
        message: message,
      );
      messenger.showSnackBar(const SnackBar(
          content: Text('Notification envoyée : vérifiez la barre de notifications')));
    } catch (e) {
      debugPrint('❌ Erreur test notification: $e');
      messenger.showSnackBar(SnackBar(content: Text('Échec : $e')));
    }
  }

  static String? _formatDate(dynamic value, String pattern) {
    if (value == null) return null;
    try {
      final DateTime date =
          value is String ? DateTime.parse(value) : (value as dynamic).toDate();
      return DateFormat(pattern, 'fr').format(date);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!_loading && !_authorized) {
      return AppScaffold(
        title: Text(l10n.translate('accessDenied')),
        body: Center(
          child: EmptyState(
            icon: Icons.lock_outline_rounded,
            title: l10n.translate('restrictedAccess'),
            message: l10n.translate('adminOnly'),
            action: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.translate('back')),
            ),
          ),
        ),
      );
    }

    final t = Theme.of(context).textTheme;
    final padding = AppScaffold.pagePadding(context);
    return AppScaffold(
      title: const Text('Administration'),
      actions: [
        IconButton(
          tooltip: 'Signalements',
          icon: const Icon(Icons.flag_outlined),
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminReportsScreen())),
        ),
        IconButton(
          tooltip: 'Test de notification',
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: _testNotification,
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              edgeOffset: padding.top,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: padding,
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(Space.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.translate('totalUsers').toUpperCase(),
                            style: t.labelSmall),
                        const SizedBox(height: Space.xs),
                        Text('${_stats?['totalUsers'] ?? 0}',
                            style: t.displaySmall),
                        const SizedBox(height: Space.xs),
                        Text(
                          l10n.translate('lastUpdate').replaceAll(
                              '{date}',
                              _formatDate(_stats?['lastUpdated'],
                                      'dd/MM/yyyy HH:mm') ??
                                  '—'),
                          style: t.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  SectionHeader('Utilisateurs (${_users.length})'),
                  if (_users.isEmpty)
                    const GlassCard(
                      child: EmptyState(
                          icon: Icons.group_outlined,
                          title: 'Aucun utilisateur inscrit'),
                    ),
                  for (final user in _users) ...[
                    _UserCard(user: user),
                    const SizedBox(height: Space.s),
                  ],
                ],
              ),
            ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final name = (user['name'] as String?)?.trim();
    final uid = user['uid'] as String? ?? '';
    final contacts = user['contactsCount'] ?? 0;
    final birth = _AdminStatsScreenState._formatDate(user['birthDate'], 'dd/MM/yyyy');
    final created = _AdminStatsScreenState._formatDate(user['createdAt'], 'dd/MM/yyyy');
    final lastLogin =
        _AdminStatsScreenState._formatDate(user['lastLogin'], 'dd/MM HH:mm');
    final place = [user['birthplace'], user['birthCountry']]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toSet()
        .join(', ');

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(name: name ?? '?', size: 40),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name?.isNotEmpty == true ? name! : 'Sans nom',
                        style: t.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(user['email'] as String? ??
                            l10n.translate('emailNotProvided'),
                        style: t.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.m),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            children: [
              if (birth != null) Pill(birth, icon: Icons.cake_outlined),
              if (place.isNotEmpty) Pill(place, icon: Icons.place_outlined),
              Pill('$contacts contact${contacts is int && contacts > 1 ? 's' : ''}',
                  icon: Icons.people_outline_rounded, tone: Tone.primary),
            ],
          ),
          const SizedBox(height: Space.s),
          Text(
            [
              if (created != null) 'Inscrit le $created',
              'Connexion : ${lastLogin ?? 'jamais'}',
            ].join(' · '),
            style: t.bodySmall,
          ),
          if (uid.isNotEmpty)
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await Clipboard.setData(ClipboardData(text: uid));
                messenger.showSnackBar(
                    const SnackBar(content: Text('UID copié')));
              },
              icon: const Icon(Icons.copy_rounded, size: 14),
              label: Text(uid,
                  style: t.bodySmall?.copyWith(fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
    );
  }
}
