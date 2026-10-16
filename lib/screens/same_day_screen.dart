import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../services/analytics_service.dart';
import '../services/directory_service.dart';
import '../services/safety_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_links.dart';
import '../utils/birthday_labels.dart';
import '../utils/city.dart';
import '../widgets/message_sheet.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/ui/components.dart';
import '../widgets/ui/glass.dart';
import 'meetups_screen.dart';
import 'public_profile_screen.dart';

/// Annuaire « Même jour » : les profils publics nés le même jour (ou la
/// même semaine, le même mois), dans le monde, le pays ou la ville.
class SameDayScreen extends StatefulWidget {
  const SameDayScreen({super.key});

  @override
  State<SameDayScreen> createState() => _SameDayScreenState();
}

/// Portée de l'annuaire : monde entier, mon pays, ma ville.
enum _Scope { world, country, city }

class _SameDayScreenState extends State<SameDayScreen> {
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _hasMore = true;
  DirectoryPeriod _period = DirectoryPeriod.day;
  _Scope _scope = _Scope.world;
  DocumentSnapshot? _last;
  Set<String> _blocked = {};

  /// Incrémenté à chaque changement de filtre : une réponse arrivée après
  /// un nouveau filtre est ignorée (sinon l'ancienne liste s'affichait).
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'SameDayScreen');
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
        _loadMore();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  UserProfile? get _me => context.read<ProfileProvider>().profile;

  Query<Map<String, dynamic>> _query(UserProfile me) => DirectoryService().query(
        me.birthDate,
        _period,
        countryCode: _scope == _Scope.country ? me.countryCode : null,
        cityKey: _scope == _Scope.city ? cityKey(me.countryCode, me.birthCity) : null,
      );

  /// On ne se compte pas soi-même, ni les profils bloqués.
  List<Map<String, dynamic>> _visible(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    return [
      for (final d in docs)
        if (d.id != myUid && !_blocked.contains(d.id)) {...d.data(), 'uid': d.id},
    ];
  }

  Future<void> _load() async {
    final gen = ++_generation;
    setState(() {
      _loading = true;
      _items = [];
      _last = null;
      _hasMore = true;
    });
    final me = _me;
    if (me == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      _blocked = await SafetyService().blockedUids();
      final q = await _query(me).get();
      if (!mounted || gen != _generation) return;
      setState(() {
        _items = _visible(q.docs);
        _hasMore = q.size == DirectoryService.pageSize;
        _last = q.docs.isEmpty ? null : q.docs.last;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erreur annuaire: $e');
      if (mounted && gen == _generation) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    final me = _me;
    if (!_hasMore || _loading || me == null || _last == null) return;
    final gen = _generation;
    setState(() => _loading = true);
    try {
      final q = await _query(me).startAfterDocument(_last!).get();
      if (!mounted || gen != _generation) return;
      setState(() {
        _items.addAll(_visible(q.docs));
        _hasMore = q.size == DirectoryService.pageSize;
        if (q.docs.isNotEmpty) _last = q.docs.last;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erreur pagination: $e');
      if (mounted && gen == _generation) {
        setState(() {
          _loading = false;
          _hasMore = false;
        });
      }
    }
  }

  void _setFilters({DirectoryPeriod? period, _Scope? scope}) {
    _period = period ?? _period;
    _scope = scope ?? _scope;
    _load();
  }

  /// Invite des proches nés à la même date : le seul moyen de remplir
  /// l'annuaire au lancement.
  Future<void> _invite(UserProfile me) async {
    final l10n = AppLocalizations.of(context);
    final date = '${me.birthDate.day.toString().padLeft(2, '0')}/'
        '${me.birthDate.month.toString().padLeft(2, '0')}';
    await SharePlus.instance.share(ShareParams(
      text: l10n
          .translate('inviteText')
          .replaceAll('{date}', date)
          .replaceAll('{link}', AppLinks.invite),
    ));
  }

  Future<void> _open(Map<String, dynamic> data) async {
    final profile = UserProfile.fromMap(data);
    final blocked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PublicProfileScreen(profile: profile)),
    );
    if (blocked == true && mounted) {
      setState(() {
        _blocked.add(profile.uid!);
        _items.removeWhere((it) => it['uid'] == profile.uid);
      });
    }
  }

  static bool _flag(dynamic v) => v == true || v == 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final me = context.watch<ProfileProvider>().profile;
    final padding = AppScaffold.pagePadding(context);

    return AppScaffold(
      title: Text(l10n.translate('sameDay')),
      actions: [
        if (me != null)
          IconButton(
            tooltip: l10n.translate('inviteFriends'),
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => _invite(me),
          ),
      ],
      body: RefreshIndicator(
        edgeOffset: padding.top,
        onRefresh: _load,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  padding.left, padding.top, padding.right, Space.m),
              sliver: SliverToBoxAdapter(child: _Header(
                me: me,
                count: _items.length,
                hasMore: _hasMore && _items.isNotEmpty,
                loading: _loading && _items.isEmpty,
                period: _period,
                scope: _scope,
                onPeriod: (p) => _setFilters(period: p),
                onScope: (s) => _setFilters(scope: s),
              )),
            ),
            if (_loading && _items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: EmptyState(
                    icon: Icons.public_rounded,
                    title: l10n.translate('noProfileFound'),
                    message: l10n.translate('beTheFirst'),
                    action: me == null
                        ? null
                        : FilledButton.icon(
                            onPressed: () => _invite(me),
                            icon: const Icon(Icons.ios_share_rounded, size: 18),
                            label: Text(l10n.translate('inviteFriends')),
                          ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    padding.left, 0, padding.right, padding.bottom),
                sliver: SliverList.separated(
                  itemCount: _items.length + (_loading ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: Space.s),
                  itemBuilder: (context, i) {
                    if (i == _items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(Space.l),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final it = _items[i];
                    final name = _flag(it['publicName'])
                        ? (it['name'] as String? ?? '')
                        : '';
                    final shown =
                        name.isEmpty ? l10n.translate('anonymousProfile') : name;
                    final place = _flag(it['publicBirthPlace'])
                        ? (it['birthplace'] as String? ?? '')
                        : '';
                    final birthDayKey = it['birthDayKey'] as String?;
                    return _TwinTile(
                      key: ValueKey(it['uid']),
                      uid: it['uid'] as String?,
                      name: shown,
                      subtitle: [
                        if (_period != DirectoryPeriod.day && birthDayKey != null)
                          _dayLabel(l10n, birthDayKey),
                        if (place.isNotEmpty) place,
                      ].join(' · '),
                      showPhoto: it['publicPhoto'] == true,
                      onTap: () => _open(it),
                      // Pas de message pour un profil dont le nom est masqué.
                      onMessage: name.isEmpty
                          ? null
                          : () => showBirthdayMessageSheet(context,
                              name: name.split(' ').first,
                              relation: 'default'),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// « 21 mars » à partir de la clé « MM-DD ».
  static String _dayLabel(AppLocalizations l10n, String key) {
    final parts = key.split('-');
    if (parts.length != 2) return '';
    final m = int.tryParse(parts[0]), d = int.tryParse(parts[1]);
    if (m == null || d == null) return '';
    return dayMonthLabel(l10n, DateTime(2000, m, d));
  }
}

class _Header extends StatelessWidget {
  final UserProfile? me;
  final int count;
  final bool hasMore;
  final bool loading;
  final DirectoryPeriod period;
  final _Scope scope;
  final ValueChanged<DirectoryPeriod> onPeriod;
  final ValueChanged<_Scope> onScope;

  const _Header({
    required this.me,
    required this.count,
    required this.hasMore,
    required this.loading,
    required this.period,
    required this.scope,
    required this.onPeriod,
    required this.onScope,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final hasCountry = UserProfile.isValidCountryCode(me?.countryCode);
    final hasCity = cityKey(me?.countryCode, me?.birthCity) != null;
    final flag =
        hasCountry ? Country.tryParse(me!.countryCode!)?.flagEmoji : null;

    Widget scopeChip(_Scope s, String label, bool enabled, {Widget? avatar}) =>
        ChoiceChip(
          avatar: avatar,
          label: Text(label),
          selected: scope == s,
          // Sans pays (ou ville) dans le profil, le filtre n'a pas de sens.
          onSelected: enabled ? (_) => onScope(s) : null,
        );

    return GlassCard(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (me != null) ...[
            Text(l10n.translate('yourBirthday').toUpperCase(),
                style: t.labelSmall?.copyWith(color: c.onSurfaceVariant)),
            const SizedBox(height: Space.xs),
            Text(dayMonthLabel(l10n, me!.birthDate), style: t.headlineMedium),
            const SizedBox(height: Space.xs),
            Text(
              loading
                  ? ' '
                  : l10n
                      .translate(switch (period) {
                        DirectoryPeriod.day => 'twinsCountDay',
                        DirectoryPeriod.week => 'twinsCountWeek',
                        DirectoryPeriod.month => 'twinsCountMonth',
                      })
                      .replaceAll('{count}', '$count${hasMore ? '+' : ''}'),
              style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
            ),
            const SizedBox(height: Space.l),
          ],
          SegmentedButton<DirectoryPeriod>(
            segments: [
              ButtonSegment(
                  value: DirectoryPeriod.day,
                  label: Text(l10n.translate('periodDay'))),
              ButtonSegment(
                  value: DirectoryPeriod.week,
                  label: Text(l10n.translate('periodWeek'))),
              ButtonSegment(
                  value: DirectoryPeriod.month,
                  label: Text(l10n.translate('periodMonth'))),
            ],
            selected: {period},
            onSelectionChanged: (s) => onPeriod(s.first),
          ),
          const SizedBox(height: Space.m),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            children: [
              scopeChip(_Scope.world, l10n.translate('scopeWorld'), true),
              scopeChip(_Scope.country, l10n.translate('myCountry'), hasCountry,
                  avatar: flag == null ? null : Text(flag)),
              scopeChip(_Scope.city, l10n.translate('myCity'), hasCity),
            ],
          ),
          if (!hasCountry || !hasCity) ...[
            const SizedBox(height: Space.s),
            Text(
              l10n.translate(hasCountry ? 'setCityHint' : 'setCountryHint'),
              style: t.bodySmall,
            ),
          ],
          const SizedBox(height: Space.s),
          const Divider(),
          const SizedBox(height: Space.xs),
          ActionRow(
            icon: Icons.celebration_outlined,
            title: l10n.translate('meetupsButton'),
            subtitle: l10n.translate('meetupsRowDesc'),
            tone: Tone.accent,
            onTap: () => Navigator.of(context).pushNamed(MeetupsScreen.routeName),
          ),
        ],
      ),
    );
  }
}

class _TwinTile extends StatelessWidget {
  final String? uid;
  final String name;
  final String subtitle;
  final bool showPhoto;
  final VoidCallback onTap;
  final VoidCallback? onMessage;

  const _TwinTile({
    super.key,
    required this.uid,
    required this.name,
    required this.subtitle,
    required this.showPhoto,
    required this.onTap,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(Space.m, Space.m, Space.xs, Space.m),
      onTap: onTap,
      child: Row(
        children: [
          ProfileAvatar(uid: uid, name: name, showPhoto: showPhoto),
          const SizedBox(width: Space.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: t.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: t.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          if (onMessage != null)
            IconButton(
              tooltip: l10n.translate('writeMessage'),
              icon: const Icon(Icons.edit_note_rounded),
              onPressed: onMessage,
            )
          else
            const SizedBox(width: Space.m),
        ],
      ),
    );
  }
}
