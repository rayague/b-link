import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/directory_service.dart';
import '../services/safety_service.dart';
import '../services/wish_service.dart';
import '../theme/app_theme.dart';
import 'profile_avatar.dart';
import 'ui/components.dart';
import 'wish_sheet.dart';

/// Un membre de l'annuaire qui fête son anniversaire aujourd'hui.
typedef TodayTwin = ({String uid, String name, bool showPhoto});

/// « Aujourd'hui dans le monde » : les membres qui fêtent leur anniversaire
/// aujourd'hui, à qui l'on peut envoyer un vœu. Rien n'est affiché s'il n'y
/// en a aucun (ou hors ligne).
class TodayTwinsSection extends StatefulWidget {
  const TodayTwinsSection({super.key, this.loader, this.wishService});

  /// Remplaçables dans les tests.
  final Future<List<TodayTwin>> Function()? loader;
  final WishService? wishService;

  @override
  State<TodayTwinsSection> createState() => _TodayTwinsSectionState();
}

class _TodayTwinsSectionState extends State<TodayTwinsSection> {
  late final Future<List<TodayTwin>> _twins = (widget.loader ?? _load)();

  static Future<List<TodayTwin>> _load() async {
    try {
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      final blocked = await SafetyService().blockedUids();
      final snap =
          await DirectoryService().query(DateTime.now(), DirectoryPeriod.day).get();
      return [
        for (final d in snap.docs)
          if (d.id != myUid && !blocked.contains(d.id))
            (
              uid: d.id,
              name: d.data()['publicName'] == true
                  ? (d.data()['name'] as String? ?? '')
                  : '',
              showPhoto: d.data()['publicPhoto'] == true,
            ),
      ];
    } catch (e) {
      debugPrint("Anniversaires du jour indisponibles: $e");
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return FutureBuilder<List<TodayTwin>>(
      future: _twins,
      builder: (context, snap) {
        final twins = snap.data ?? const <TodayTwin>[];
        // Pas de place réservée pendant le chargement : la section apparaît
        // seulement si elle a quelque chose à montrer.
        return AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: twins.isEmpty
              ? const SizedBox(width: double.infinity)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeader(l10n
                        .translate('todayInTheWorld')
                        .replaceAll('{count}', '${twins.length}')),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: Space.xs, bottom: Space.s),
                      child: Text(l10n.translate('todayInTheWorldDesc'),
                          style: t.bodySmall),
                    ),
                    SizedBox(
                      height: 104,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: twins.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: Space.s),
                        itemBuilder: (context, i) => _Bubble(
                            twin: twins[i], service: widget.wishService),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  final TodayTwin twin;
  final WishService? service;
  const _Bubble({required this.twin, this.service});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).colorScheme;
    final name = twin.name.trim().isEmpty
        ? l10n.translate('anonymousProfile')
        : twin.name.trim().split(RegExp(r'\s+')).first;
    return SizedBox(
      width: 76,
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.control),
        onTap: () => showWishSheet(context,
            uid: twin.uid,
            name: name,
            showPhoto: twin.showPhoto,
            service: service),
        child: Column(
          children: [
            const SizedBox(height: Space.xs),
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: c.secondary, width: 2),
              ),
              child: ProfileAvatar(
                  uid: twin.uid, name: name, size: 56, showPhoto: twin.showPhoto),
            ),
            const SizedBox(height: Space.s),
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}
