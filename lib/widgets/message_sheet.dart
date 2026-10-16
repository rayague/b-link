import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';
import '../services/message_repository.dart';
import '../theme/app_theme.dart';
import '../utils/relations.dart';
import 'greeting_card.dart';
import 'ui/components.dart';
import 'ui/glass.dart';

/// Feuille « message d'anniversaire » : un message tiré de la banque, que
/// l'on peut copier, remplacer par un autre ou transformer en carte.
/// Partagée par l'accueil, la fiche contact et l'annuaire.
Future<void> showBirthdayMessageSheet(
  BuildContext context, {
  required String name,
  required String relation,
}) {
  return showGlassSheet<void>(
    context,
    builder: (_) => _MessageSheet(name: name, relation: relation),
  );
}

class _MessageSheet extends StatefulWidget {
  final String name;
  final String relation;
  const _MessageSheet({required this.name, required this.relation});

  @override
  State<_MessageSheet> createState() => _MessageSheetState();
}

class _MessageSheetState extends State<_MessageSheet> {
  final _repo = MessageRepository();
  String? _message;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_message == null) _next();
  }

  Future<void> _next() async {
    final lang = AppLocalizations.of(context).locale.languageCode;
    final previous = _message;
    var msg = await _repo.getRandomForRelation(widget.relation, widget.name,
        lang: lang);
    // Un second tirage évite de reproposer le même texte.
    if (msg == previous) {
      msg = await _repo.getRandomForRelation(widget.relation, widget.name,
          lang: lang);
    }
    AnalyticsService().logBirthdayMessageGenerated(
        relation: widget.relation, messageLength: msg.length);
    if (mounted) setState(() => _message = msg);
  }

  Future<void> _copy() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: _message!));
    if (!mounted) return;
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(l10n.translate('messageCopied'))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final msg = _message;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          Space.page, Space.s, Space.page, Space.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.translate('messageForName').replaceAll('{name}', widget.name),
            style: t.titleLarge,
          ),
          const SizedBox(height: Space.s),
          Align(
            alignment: Alignment.centerLeft,
            child: Pill(relationLabel(l10n, widget.relation),
                tone: Tone.accent),
          ),
          const SizedBox(height: Space.l),
          GlassCard(
            padding: const EdgeInsets.all(Space.l),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: msg == null
                  ? const SizedBox(
                      height: 96,
                      child: Center(child: CircularProgressIndicator()))
                  : SelectableText(msg,
                      key: ValueKey(msg),
                      style: t.bodyLarge?.copyWith(height: 1.6)),
            ),
          ),
          const SizedBox(height: Space.s),
          Text(l10n.translate('copyHelp'), style: t.bodySmall),
          const SizedBox(height: Space.l),
          FilledButton.icon(
            onPressed: msg == null ? null : _copy,
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: Text(l10n.translate('copyMessage')),
          ),
          const SizedBox(height: Space.s),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: msg == null ? null : _next,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(l10n.translate('anotherMessage')),
                ),
              ),
              const SizedBox(width: Space.s),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: msg == null
                      ? null
                      : () => showGreetingCardDialog(context,
                          name: widget.name,
                          message: msg,
                          relation: widget.relation),
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: Text(l10n.translate('makeCard')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
