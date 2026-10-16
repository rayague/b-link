import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/profile_provider.dart';
import '../services/analytics_service.dart';
import '../services/safety_service.dart';
import '../services/wish_service.dart';
import '../theme/app_theme.dart';
import '../utils/birthday.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/ui/components.dart';
import '../widgets/ui/glass.dart';

/// Le mur de vœux : les vœux reçus cette année de ses jumeaux
/// d'anniversaire.
class WishesScreen extends StatefulWidget {
  static const routeName = '/wishes';
  const WishesScreen({super.key, this.service});

  /// Remplaçable dans les tests.
  final WishService? service;

  @override
  State<WishesScreen> createState() => _WishesScreenState();
}

class _WishesScreenState extends State<WishesScreen> {
  late Future<List<Wish>> _wishes = _load();

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'WishesScreen');
  }

  Future<List<Wish>> _load() async {
    final list = await (widget.service ?? WishService()).received();
    var blocked = <String>{};
    try {
      blocked = await SafetyService().blockedUids();
    } catch (_) {}
    return [for (final w in list) if (!blocked.contains(w.fromUid)) w];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final me = context.watch<ProfileProvider>().profile;
    final now = DateTime.now();
    final isToday = me != null && daysUntilBirthday(me.birthDate, now) == 0;
    final firstName = me?.givenName?.trim().isNotEmpty == true
        ? me!.givenName!.trim()
        : (me?.name.trim().split(RegExp(r'\s+')).first ?? '');
    final padding = AppScaffold.pagePadding(context);

    return AppScaffold(
      title: Text(l10n.translate('myWishes')),
      body: RefreshIndicator(
        edgeOffset: padding.top,
        onRefresh: () async {
          setState(() => _wishes = _load());
          await _wishes;
        },
        child: FutureBuilder<List<Wish>>(
          future: _wishes,
          builder: (context, snap) {
            final wishes = snap.data ?? const <Wish>[];
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: padding,
              children: [
                GlassCard(
                  tint: isToday ? c.secondary : null,
                  padding: const EdgeInsets.all(Space.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const IconBadge(Icons.cake_outlined, tone: Tone.accent),
                      const SizedBox(height: Space.l),
                      Text(
                        isToday
                            ? l10n
                                .translate('happyBirthdayName')
                                .replaceAll('{name}', firstName)
                            : l10n.translate('wishesThisYear'),
                        style: t.headlineSmall,
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        snap.connectionState != ConnectionState.done
                            ? ' '
                            : l10n
                                .translate(wishes.length == 1
                                    ? 'wishesCountOne'
                                    : 'wishesCount')
                                .replaceAll('{count}', '${wishes.length}'),
                        style:
                            t.bodyLarge?.copyWith(color: c.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.m),
                if (snap.connectionState != ConnectionState.done)
                  const Padding(
                    padding: EdgeInsets.all(Space.xxl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (wishes.isEmpty)
                  GlassCard(
                    child: EmptyState(
                      icon: Icons.mark_email_unread_outlined,
                      title: l10n.translate('noWishesYet'),
                      message: l10n.translate('noWishesYetDesc'),
                    ),
                  )
                else
                  for (final (i, w) in wishes.indexed)
                    _WishTile(wish: w, index: i),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Un vœu, qui apparaît en fondu et glissement léger, en cascade.
class _WishTile extends StatelessWidget {
  final Wish wish;
  final int index;
  const _WishTile({required this.wish, required this.index});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final name = (wish.fromName?.trim().isNotEmpty ?? false)
        ? wish.fromName!.trim()
        : l10n.translate('aBirthdayTwin');
    final when = wish.createdAt == null
        ? null
        : DateFormat.MMMMd(l10n.locale.languageCode)
            .add_Hm()
            .format(wish.createdAt!);
    final key = 'wish_${wish.wish.clamp(0, WishService.count - 1)}';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + 60 * index.clamp(0, 8)),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: Space.s),
        child: GlassCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(
                  uid: wish.fromUid, name: wish.fromName ?? '', size: 40),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: t.titleSmall),
                    const SizedBox(height: Space.xs),
                    Text(l10n.translate(key),
                        style: t.bodyLarge?.copyWith(height: 1.45)),
                    if (when != null) ...[
                      const SizedBox(height: Space.xs),
                      Text(when, style: t.bodySmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
