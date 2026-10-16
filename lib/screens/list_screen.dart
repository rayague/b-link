import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/contact.dart';
import '../providers/contact_provider.dart';
import '../providers/locale_provider.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import '../utils/birthday.dart';
import '../utils/birthday_labels.dart';
import '../utils/relations.dart';
import '../widgets/contact_avatar.dart';
import '../widgets/contact_form.dart';
import '../widgets/ui/components.dart';
import '../widgets/ui/glass.dart';

/// Contacts, du prochain anniversaire au plus lointain.
class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final _search = TextEditingController();
  String _query = '';

  /// Contacts balayés : retirés tout de suite de la liste, sans attendre la
  /// suppression (un Dismissible balayé ne doit plus être affiché).
  final Set<int> _dismissed = {};

  @override
  void initState() {
    super.initState();
    // Les contacts sont déjà chargés au démarrage : pas de rechargement ici
    // (il réimportait les messages et reprogrammait tous les rappels).
    AnalyticsService().logScreenView(screenName: 'ListScreen');
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _showAdd() {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ContactProvider>();
    final locale = context.read<LocaleProvider>().locale.languageCode;
    showGlassSheet<void>(
      context,
      builder: (sheet) => SingleChildScrollView(
        padding:
            const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.translate('addContact'),
                style: Theme.of(sheet).textTheme.titleLarge),
            const SizedBox(height: Space.l),
            ContactForm(
              submitLabel: l10n.translate('save'),
              onSubmit: (draft) async {
                await provider.addContact(draft, locale: locale);
                if (!sheet.mounted) return;
                Navigator.of(sheet).pop();
                messenger.showSnackBar(SnackBar(
                    content: Text(l10n
                        .translate('contactAdded')
                        .replaceAll('{name}', draft.name))));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(Contact c) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('deleteContactTitle')),
        content: Text(
            l10n.translate('deleteContactBody').replaceAll('{name}', c.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.translate('cancel'))),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.translate('delete')),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final prov = context.watch<ContactProvider>();
    final now = DateTime.now();
    final q = _query.trim().toLowerCase();

    final rows = <(Contact, int?)>[
      for (final c in prov.contacts)
        if (!_dismissed.contains(c.id) &&
            (q.isEmpty ||
            c.name.toLowerCase().contains(q) ||
            relationLabel(l10n, c.relation).toLowerCase().contains(q)))
          (c, parseBirthDate(c.date) == null
              ? null
              : daysUntilBirthday(parseBirthDate(c.date)!, now)),
    ]..sort((a, b) => (a.$2 ?? 999).compareTo(b.$2 ?? 999));

    final padding = AppScaffold.pagePadding(context, bottom: 96);
    return AppScaffold(
      title: Text(l10n.translate('myContacts')),
      actions: [
        IconButton(
          tooltip: l10n.translate('importContacts'),
          icon: const Icon(Icons.contacts_outlined),
          onPressed: () => Navigator.of(context).pushNamed('/import'),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAdd,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.translate('add')),
      ),
      body: RefreshIndicator(
        edgeOffset: padding.top,
        onRefresh: () => prov.loadContacts(
            locale: context.read<LocaleProvider>().locale.languageCode),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  padding.left, padding.top, padding.right, Space.m),
              sliver: SliverToBoxAdapter(
                child: TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.translate('searchContact'),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
            ),
            if (rows.isEmpty && !prov.loading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: q.isEmpty
                      ? EmptyState(
                          icon: Icons.people_outline_rounded,
                          title: l10n.translate('noContact'),
                          message: l10n.translate('pressToAdd'),
                          action: Column(
                            children: [
                              FilledButton.icon(
                                onPressed: () =>
                                    Navigator.of(context).pushNamed('/import'),
                                icon: const Icon(Icons.contacts_outlined),
                                label: Text(l10n.translate('importContacts')),
                              ),
                              const SizedBox(height: Space.s),
                              TextButton.icon(
                                onPressed: _showAdd,
                                icon: const Icon(Icons.add_rounded),
                                label: Text(l10n.translate('addContactAction')),
                              ),
                            ],
                          ),
                        )
                      : EmptyState(
                          icon: Icons.search_off_rounded,
                          title: l10n.translate('noResults'),
                          message: l10n.translate('tryAnotherSearch'),
                        ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    padding.left, 0, padding.right, padding.bottom),
                sliver: SliverList.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Space.s),
                  itemBuilder: (context, i) {
                    final (contact, days) = rows[i];
                    return Dismissible(
                      key: ValueKey(contact.id ?? contact.uuid ?? i),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) => _confirmDelete(contact),
                      onDismissed: (_) {
                        setState(() => _dismissed.add(contact.id!));
                        prov.deleteContact(contact.id!);
                      },
                      background: _DeleteBackground(),
                      child: _ContactTile(contact: contact, days: days),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Contact contact;
  final int? days;
  const _ContactTile({required this.contact, required this.days});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final birth = parseBirthDate(contact.date);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.m),
      onTap: () => Navigator.of(context).pushNamed('/detail', arguments: contact),
      child: Row(
        children: [
          ContactAvatar(name: contact.name, imagePath: contact.imageUri),
          const SizedBox(width: Space.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name,
                    style: t.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  [
                    relationLabel(l10n, contact.relation),
                    if (birth != null) dayMonthLabel(l10n, birth),
                  ].join(' · '),
                  style: t.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (days != null) ...[
            const SizedBox(width: Space.s),
            Pill(countdownLabel(l10n, days!),
                tone: days == 0
                    ? Tone.accent
                    : days! <= 7
                        ? Tone.primary
                        : Tone.neutral,
                strong: days == 0),
          ],
        ],
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: Space.xl),
      decoration: BoxDecoration(
        color: c.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Icon(Icons.delete_outline_rounded, color: c.error),
    );
  }
}
