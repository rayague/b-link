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
/// choix d'un message prédéfini, envoyé une fois par an.
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
  int _choice = 0;
  bool _sending = false;
  bool? _sent;

  @override
  void initState() {
    super.initState();
    widget.service.alreadySent(widget.uid).then((v) {
      if (mounted) setState(() => _sent = v);
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
        wish: _choice,
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
          else if (_sent == true)
            NoticeCard(
              icon: Icons.check_circle_outline_rounded,
              text: l10n.translate('wishAlreadySent'),
            )
          else ...[
            for (var i = 0; i < WishService.count; i++) ...[
              GlassCard(
                tint: _choice == i ? c.primary : null,
                padding: const EdgeInsets.symmetric(
                    horizontal: Space.l, vertical: Space.m),
                onTap: () => setState(() => _choice = i),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(l10n.translate('wish_$i'),
                          style: t.bodyLarge?.copyWith(height: 1.4)),
                    ),
                    const SizedBox(width: Space.s),
                    AnimatedOpacity(
                      opacity: _choice == i ? 1 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(Icons.check_circle_rounded, color: c.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.s),
            ],
            const SizedBox(height: Space.s),
            Text(l10n.translate('wishOncePerYear'), style: t.bodySmall),
            const SizedBox(height: Space.l),
            FilledButton(
              onPressed: _sending || _sent == null ? null : _send,
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
