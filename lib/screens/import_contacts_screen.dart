import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' show PermissionStatus;
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/contact.dart';
import '../providers/contact_provider.dart';
import '../providers/locale_provider.dart';
import '../services/analytics_service.dart';
import '../services/phone_contacts_service.dart';
import '../theme/app_theme.dart';
import '../utils/birthday.dart';
import '../utils/birthday_labels.dart';
import '../widgets/ui/components.dart';
import '../widgets/ui/glass.dart';

/// Import des contacts du téléphone : ceux qui ont un anniversaire sont
/// cochés d'office, les autres peuvent recevoir une date en un geste.
class ImportContactsScreen extends StatefulWidget {
  static const routeName = '/import';
  const ImportContactsScreen({super.key, this.service});

  /// Remplaçable dans les tests.
  final PhoneContactsService? service;

  @override
  State<ImportContactsScreen> createState() => _ImportContactsScreenState();
}

enum _Stage { asking, denied, blocked, loading, ready }

class _ImportContactsScreenState extends State<ImportContactsScreen> {
  late final PhoneContactsService _service =
      widget.service ?? PhoneContactsService();
  _Stage _stage = _Stage.asking;
  List<PhoneContact> _candidates = [];
  final Set<String> _selected = {};
  final _search = TextEditingController();
  String _query = '';
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'ImportContactsScreen');
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final status = await _service.requestRead();
    if (!mounted) return;
    if (!PhoneContactsService.isGranted(status)) {
      setState(() => _stage = status == PermissionStatus.permanentlyDenied ||
              status == PermissionStatus.restricted
          ? _Stage.blocked
          : _Stage.denied);
      return;
    }
    setState(() => _stage = _Stage.loading);
    final all = await _service.load();
    if (!mounted) return;
    final existing = context.read<ContactProvider>().contacts;
    final fresh = PhoneContactsService.notImported(all, existing);
    setState(() {
      // Ceux qui ont un anniversaire d'abord.
      _candidates = [
        ...fresh.where((c) => c.birthday != null),
        ...fresh.where((c) => c.birthday == null),
      ];
      _selected
        ..clear()
        ..addAll(fresh.where((c) => c.birthday != null).map((c) => c.id));
      _stage = _Stage.ready;
    });
  }

  Future<void> _setDate(PhoneContact c) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked == null) return;
    setState(() {
      final i = _candidates.indexWhere((x) => x.id == c.id);
      _candidates[i] = c.withBirthday(picked);
      _selected.add(c.id);
    });
  }

  void _toggle(PhoneContact c) {
    if (c.birthday == null) {
      _setDate(c);
      return;
    }
    setState(() =>
        _selected.contains(c.id) ? _selected.remove(c.id) : _selected.add(c.id));
  }

  static String _iso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _import() async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final chosen = [
      for (final c in _candidates)
        if (_selected.contains(c.id) && c.birthday != null)
          Contact(
            name: c.name,
            date: _iso(c.birthday!),
            relation: 'FRIEND',
            phone: c.phone,
          ),
    ];
    setState(() => _importing = true);
    final n = await context.read<ContactProvider>().addContacts(chosen,
        locale: context.read<LocaleProvider>().locale.languageCode);
    navigator.pop(n);
    messenger.showSnackBar(SnackBar(
        content: Text(
            l10n.translate('contactsImported').replaceAll('{count}', '$n'))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final count = _selected.length;
    return AppScaffold(
      title: Text(l10n.translate('importContacts')),
      bottomBar: _stage == _Stage.ready && _candidates.isNotEmpty
          ? FilledButton(
              onPressed: count == 0 || _importing ? null : _import,
              child: _importing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n
                      .translate('importCount')
                      .replaceAll('{count}', '$count')),
            )
          : null,
      body: switch (_stage) {
        _Stage.asking || _Stage.loading =>
          const Center(child: CircularProgressIndicator()),
        _Stage.denied => Center(
            child: EmptyState(
              icon: Icons.contacts_outlined,
              title: l10n.translate('contactsPermissionTitle'),
              message: l10n.translate('contactsPermissionBody'),
              action: FilledButton(
                onPressed: _start,
                child: Text(l10n.translate('allowAccess')),
              ),
            ),
          ),
        _Stage.blocked => Center(
            child: EmptyState(
              icon: Icons.contacts_outlined,
              title: l10n.translate('contactsPermissionTitle'),
              message: l10n.translate('contactsPermissionBlocked'),
              action: OutlinedButton(
                onPressed: _service.openSettings,
                child: Text(l10n.translate('openSettings')),
              ),
            ),
          ),
        _Stage.ready => _list(context),
      },
    );
  }

  Widget _list(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    if (_candidates.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.check_circle_outline_rounded,
          title: l10n.translate('nothingToImport'),
          message: l10n.translate('nothingToImportBody'),
        ),
      );
    }
    final q = _query.trim().toLowerCase();
    final visible = q.isEmpty
        ? _candidates
        : _candidates.where((c) => c.name.toLowerCase().contains(q)).toList();
    final withBirthday = _candidates.where((c) => c.birthday != null).length;
    final padding = AppScaffold.pagePadding(context, bottom: Space.l);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
              padding.left, padding.top, padding.right, Space.m),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n
                      .translate('importSummary')
                      .replaceAll('{count}', '$withBirthday'),
                  style: t.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: Space.m),
                TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: l10n.translate('searchContact'),
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
              padding.left, 0, padding.right, padding.bottom),
          sliver: SliverList.separated(
            itemCount: visible.length,
            separatorBuilder: (_, __) => const SizedBox(height: Space.xs),
            itemBuilder: (context, i) {
              final c = visible[i];
              return _CandidateTile(
                key: ValueKey(c.id),
                contact: c,
                selected: _selected.contains(c.id),
                onTap: () => _toggle(c),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CandidateTile extends StatelessWidget {
  final PhoneContact contact;
  final bool selected;
  final VoidCallback onTap;

  const _CandidateTile(
      {super.key,
      required this.contact,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final birthday = contact.birthday;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(Space.m, Space.s, Space.xs, Space.s),
      onTap: onTap,
      child: Row(
        children: [
          InitialsAvatar(name: contact.name, size: 40),
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
                  birthday == null
                      ? l10n.translate('addBirthday')
                      : [
                          fullDateLabel(l10n, birthday),
                          if (!hasBirthYear(birthday))
                            l10n.translate('yearUnknown'),
                        ].join(' · '),
                  style: t.bodySmall?.copyWith(
                      color: birthday == null ? c.primary : null),
                ),
              ],
            ),
          ),
          if (birthday == null)
            IconButton(
              tooltip: l10n.translate('addBirthday'),
              icon: const Icon(Icons.event_outlined),
              onPressed: onTap,
            )
          else
            Checkbox(value: selected, onChanged: (_) => onTap()),
        ],
      ),
    );
  }
}
