import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';

/// Ambiance visuelle d'une carte de vœux.
enum CardMood { romantic, family, friends, classic }

class _CardStyle {
  final List<Color> gradient;
  final Color accent;
  final Color text;
  final String emoji;
  const _CardStyle(this.gradient, this.accent, this.text, this.emoji);
}

const _styles = {
  CardMood.romantic: _CardStyle(
      [Color(0xFF9D174D), Color(0xFFEC4899), Color(0xFFF9A8D4)],
      Color(0xFFFFE4F1), Colors.white, '💖'),
  CardMood.family: _CardStyle(
      [Color(0xFF92400E), Color(0xFFF59E0B), Color(0xFFFDE68A)],
      Color(0xFFFFF7E0), Colors.white, '🎂'),
  CardMood.friends: _CardStyle(
      [Color(0xFF4C1D95), Color(0xFF8B5CF6), Color(0xFF22D3EE)],
      Color(0xFFE0F7FF), Colors.white, '🎉'),
  // Couleurs du logo B-Link (bleu nuit et doré).
  CardMood.classic: _CardStyle(
      [Color(0xFF2F3247), Color(0xFF4B4E64), Color(0xFF6B6E86)],
      Color(0xFFF2DFA6), Color(0xFFF4F1E8), '✨'),
};

/// Ambiance par défaut selon la relation (codes de utils/relations.dart).
CardMood cardMoodFor(String relation) {
  switch (relation.toUpperCase()) {
    case 'HUSBAND':
    case 'WIFE':
    case 'BOYFRIEND':
    case 'GIRLFRIEND':
      return CardMood.romantic;
    case 'FRIEND':
    case 'BESTFRIEND':
    case 'NEIGHBOR':
    case 'COUSIN':
      return CardMood.friends;
    case '':
    case 'DEFAULT':
      return CardMood.classic;
    default:
      return CardMood.family;
  }
}

/// Carte de vœux (format 4:5). Taille logique fixe : l'export multiplie la
/// résolution (pixelRatio) pour obtenir une image nette.
class GreetingCard extends StatelessWidget {
  static const double width = 360;
  static const double height = 450;

  final String title;
  final String message;
  final CardMood theme;

  const GreetingCard(
      {super.key,
      required this.title,
      required this.message,
      required this.theme});

  @override
  Widget build(BuildContext context) {
    final s = _styles[theme]!;
    // Les longs messages restent lisibles en réduisant la police.
    final fontSize = message.length > 260
        ? 14.0
        : message.length > 160
            ? 16.0
            : 18.0;
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: s.gradient,
          ),
        ),
        child: Stack(
          children: [
            // Confettis décoratifs.
            for (final (dx, dy, r) in const [
              (0.08, 0.10, 10.0), (0.85, 0.07, 14.0), (0.92, 0.55, 8.0),
              (0.05, 0.62, 12.0), (0.75, 0.90, 10.0), (0.20, 0.92, 6.0),
            ])
              Positioned(
                left: width * dx,
                top: height * dy,
                child: Container(
                  width: r,
                  height: r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: s.accent.withValues(alpha: 0.35),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 20),
              child: Column(
                children: [
                  Text(s.emoji, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: s.accent,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.fade,
                        style: TextStyle(
                          color: s.text,
                          fontSize: fontSize,
                          height: 1.45,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'B-Link 🎈',
                    style: TextStyle(
                      color: s.accent.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aperçu de la carte avec choix de l'ambiance, puis partage de l'image
/// (et du texte) via les applications du téléphone.
Future<void> showGreetingCardDialog(
  BuildContext context, {
  required String name,
  required String message,
  required String relation,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) =>
        _GreetingCardDialog(name: name, message: message, relation: relation),
  );
}

class _GreetingCardDialog extends StatefulWidget {
  final String name;
  final String message;
  final String relation;
  const _GreetingCardDialog(
      {required this.name, required this.message, required this.relation});

  @override
  State<_GreetingCardDialog> createState() => _GreetingCardDialogState();
}

class _GreetingCardDialogState extends State<_GreetingCardDialog> {
  final _boundaryKey = GlobalKey();
  late CardMood _theme = cardMoodFor(widget.relation);
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3); // 1080 x 1350
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/b-link-carte.png');
      await file.writeAsBytes(png!.buffer.asUint8List());
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: widget.message,
      ));
    } catch (e) {
      debugPrint('❌ Partage de la carte: $e');
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.translate('actionFailed'))));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = widget.name.trim();
    final title = name.isEmpty
        ? l10n.translate('cardTitleNoName')
        : l10n.translate('cardTitle').replaceAll('{name}', name);
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: FittedBox(
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: GreetingCard(
                      title: title, message: widget.message, theme: _theme),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final t in CardMood.values)
                  ChoiceChip(
                    label: Text(_styles[t]!.emoji),
                    selected: _theme == t,
                    onSelected: (_) => setState(() => _theme = t),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.translate('close')),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _sharing ? null : _share,
                  icon: const Icon(Icons.share),
                  label: Text(l10n.translate('shareCard')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
