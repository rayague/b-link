import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/profile_provider.dart';
import '../screens/meetups_screen.dart' show canTakePart;
import '../services/analytics_service.dart';
import '../services/wish_service.dart';
import '../theme/app_theme.dart';
import 'profile_avatar.dart';
import 'ui/components.dart';
import 'ui/glass.dart';

/// Feuille « souhaiter un joyeux anniversaire » à un membre de l'annuaire :
/// trois messages proposés à la fois, jamais un message que la personne a
/// déjà reçu cette année, envoi une fois par an.
Future<void> showWishSheet(
  BuildContext context, {
  required String uid,
  required String name,
  bool showPhoto = false,
  WishService? service,
}) {
  return showGlassSheet<void>(
    context,
    builder: (_) => _WishSheet(
        uid: uid,
        name: name,
        showPhoto: showPhoto,
        service: service ?? WishService()),
  );
}

class _WishSheet extends StatefulWidget {
  final String uid;
  final String name;
  final bool showPhoto;
  final WishService service;
  const _WishSheet(
      {required this.uid,
      required this.name,
      required this.showPhoto,
      required this.service});

  @override
  State<_WishSheet> createState() => _WishSheetState();
}

class _WishSheetState extends State<_WishSheet> {
  static const _perPage = 3;

  /// Messages à proposer, dans l'ordre (voir WishService.proposals).
  List<int>? _order;
  int _page = 0;
  int? _choice;
  bool _sending = false;
  bool _alreadySent = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = widget.service;
    final results = await Future.wait([
      s.alreadySent(widget.uid),
      s.receivedBy(widget.uid),
      s.sentRecently(),
    ]);
    if (!mounted) return;
    final order = WishService.proposals(
      receivedByThem: results[1] as Set<int>,
      sentRecently: results[2] as List<int>,
      seed: DateTime.now().millisecondsSinceEpoch,
    );
    setState(() {
      _alreadySent = results[0] as bool;
      _order = order;
      _choice = order.first;
    });
  }

  List<int> get _visible {
    final order = _order!;
    final start = (_page * _perPage) % order.length;
    return [
      for (var i = 0; i < _perPage && i < order.length; i++)
        order[(start + i) % order.length],
    ];
  }

  void _nextPage() {
    setState(() {
      _page++;
      _choice = _visible.first;
    });
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final me = context.read<ProfileProvider>().profile;
    setState(() => _sending = true);
    try {
      await widget.service.send(
        toUid: widget.uid,
        wish: _choice!,
        fromName: me != null && me.publicName ? me.name : null,
      );
      AnalyticsService().logWishSent();
      navigator.pop();
      messenger.showSnackBar(SnackBar(
          content: Text(
              l10n.translate('wishSent').replaceAll('{name}', widget.name))));
    } catch (e) {
      debugPrint('❌ Vœu: $e');
      if (!mounted) return;
      setState(() => _sending = false);
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.translate('wishFailed'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final eligible = canTakePart(context.watch<ProfileProvider>());
    final order = _order;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ProfileAvatar(
                  uid: widget.uid,
                  name: widget.name,
                  size: 48,
                  showPhoto: widget.showPhoto),
              const SizedBox(width: Space.m),
              Expanded(
                child: Text(
                  l10n.translate('wishTitle').replaceAll('{name}', widget.name),
                  style: t.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.l),
          if (!eligible)
            NoticeCard(
              icon: Icons.public_rounded,
              text: l10n.translate('wishNeedPublic'),
            )
          else if (order == null)
            const Padding(
              padding: EdgeInsets.all(Space.xxl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_alreadySent)
            NoticeCard(
              icon: Icons.check_circle_outline_rounded,
              text: l10n.translate('wishAlreadySent'),
            )
          else ...[
            Row(
              children: [
                Expanded(
                    child: Text(l10n.translate('chooseWish'),
                        style: t.titleSmall)),
                TextButton.icon(
                  onPressed: _sending ? null : _nextPage,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(l10n.translate('otherWishes')),
                ),
              ],
            ),
            const SizedBox(height: Space.s),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0.04, 0), end: Offset.zero)
                      .animate(a),
                  child: child,
                ),
              ),
              child: Column(
                key: ValueKey(_page),
                children: [
                  for (final i in _visible) ...[
                    GlassCard(
                      tint: _choice == i ? c.primary : null,
                      padding: const EdgeInsets.all(Space.l),
                      onTap: () => setState(() => _choice = i),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(l10n.translate('wish_$i'),
                                style: t.bodyLarge?.copyWith(height: 1.5)),
                          ),
                          const SizedBox(width: Space.s),
                          AnimatedOpacity(
                            opacity: _choice == i ? 1 : 0.25,
                            duration: const Duration(milliseconds: 150),
                            child: Icon(
                                _choice == i
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                color: c.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Space.s),
                  ],
                ],
              ),
            ),
            Text(l10n.translate('wishOncePerYear'), style: t.bodySmall),
            const SizedBox(height: Space.l),
            FilledButton(
              onPressed: _sending || _choice == null ? null : _send,
              child: _sending
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.translate('sendWish')),
            ),
          ],
        ],
      ),
    );
  }
}
