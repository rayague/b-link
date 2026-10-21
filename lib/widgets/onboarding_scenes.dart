import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'ui/glass.dart';

/// Illustrations animées de l'onboarding.
///
/// Chaque scène reçoit [loop] (0 → 1 en boucle, toujours le même cycle :
/// les mouvements utilisent des multiples entiers de tours pour boucler
/// sans à-coup) et [focus] (1 quand la page est au centre, 0 quand elle
/// sort de l'écran) pour son entrée.
abstract class OnboardingScene extends StatelessWidget {
  final Animation<double> loop;
  final double focus;
  const OnboardingScene({super.key, required this.loop, required this.focus});

  static const double size = 300;
}

double _tau(double v) => v * 2 * math.pi;

/// Petite carte de notification en verre.
class _Notif extends StatelessWidget {
  final String emoji;
  final String text;
  const _Notif(this.emoji, this.text);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GlassCard(
      blur: false,
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: Space.s),
          Text(text, style: t.labelLarge),
        ],
      ),
    );
  }
}

/// 1. Les rappels : un gâteau dont le halo respire, deux rappels qui
/// flottent autour.
class ReminderScene extends OnboardingScene {
  const ReminderScene({super.key, required super.loop, required super.focus});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) {
        final v = _tau(loop.value);
        final enter = Curves.easeOutCubic.transform(focus.clamp(0.0, 1.0));
        return SizedBox.square(
          dimension: OnboardingScene.size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Halo doré qui respire.
              Container(
                width: 230 + 14 * math.sin(v * 2),
                height: 230 + 14 * math.sin(v * 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    c.secondary.withValues(alpha: 0.28),
                    c.secondary.withValues(alpha: 0),
                  ]),
                ),
              ),
              Transform.translate(
                offset: Offset(0, 4 * math.sin(v * 2)),
                child: GlassCard(
                  borderRadius: BorderRadius.circular(52),
                  padding: const EdgeInsets.all(Space.xxl),
                  child: Icon(Icons.cake_outlined, size: 64, color: c.primary),
                ),
              ),
              Positioned(
                top: 22 + 7 * math.sin(v),
                right: -6 - 90 * (1 - enter),
                child: Opacity(
                  opacity: enter,
                  child: _Notif('🎂', l10n.translate('onbNotif1')),
                ),
              ),
              Positioned(
                bottom: 30 + 7 * math.sin(v + 2),
                left: -6 - 90 * (1 - enter),
                child: Opacity(
                  opacity: enter,
                  child: _Notif('🔔', l10n.translate('onbNotif2')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 2. Les jumeaux : des visages en orbite autour du globe, reliés à lui.
class TwinsScene extends OnboardingScene {
  const TwinsScene({super.key, required super.loop, required super.focus});

  static const _initials = ['L', 'K', 'A', 'M', 'S', 'N'];
  static const _colors = [
    Color(0xFFE8CD86),
    Color(0xFFB8BFE3),
    Color(0xFFF2B8C6),
    Color(0xFFA8DCC8),
    Color(0xFFF5C99B),
    Color(0xFFC9B8F2),
  ];

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) {
        const s = OnboardingScene.size;
        const center = Offset(s / 2, s / 2);
        final enter = Curves.easeOutBack.transform(focus.clamp(0.0, 1.0));
        // (rayon, sens et nombre de tours par cycle, décalage)
        final avatars = <(Offset, double, int)>[];
        for (var k = 0; k < 6; k++) {
          final inner = k.isEven;
          final r = (inner ? 82.0 : 128.0) * enter;
          final turns = inner ? 1 : -1;
          final a = _tau(loop.value * turns + k / 6);
          final p = center + Offset(math.cos(a) * r, math.sin(a) * r * 0.58);
          avatars.add((p, math.sin(a), k));
        }
        // Les visages « derrière » le globe d'abord.
        avatars.sort((a, b) => a.$2.compareTo(b.$2));
        return SizedBox.square(
          dimension: s,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _OrbitPainter(
                    ring: c.outlineVariant,
                    link: c.secondary,
                    points: [for (final a in avatars) a.$1],
                    pulse: loop.value,
                    enter: enter,
                  ),
                ),
              ),
              for (final (p, depth, k) in avatars)
                if (depth < 0) _avatar(p, depth, k),
              Center(
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Glass.of(context).fillStrong,
                    border:
                        Border.all(color: c.secondary.withValues(alpha: 0.45)),
                    boxShadow: [
                      BoxShadow(
                        color: c.secondary.withValues(alpha: 0.25),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child:
                      Icon(Icons.public_rounded, size: 46, color: c.secondary),
                ),
              ),
              for (final (p, depth, k) in avatars)
                if (depth >= 0) _avatar(p, depth, k),
            ],
          ),
        );
      },
    );
  }

  Widget _avatar(Offset p, double depth, int k) {
    final d = 38 + 8 * depth; // plus grand devant
    return Positioned(
      left: p.dx - d / 2,
      top: p.dy - d / 2,
      child: Opacity(
        opacity: 0.75 + 0.25 * depth.clamp(0, 1),
        child: Container(
          width: d,
          height: d,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _colors[k],
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.8), width: 2),
          ),
          child: Text(_initials[k],
              style: TextStyle(
                  fontSize: d * 0.42,
                  fontWeight: FontWeight.w700,
                  color: Brand.ink.withValues(alpha: 0.75))),
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final Color ring;
  final Color link;
  final List<Offset> points;
  final double pulse;
  final double enter;
  _OrbitPainter({
    required this.ring,
    required this.link,
    required this.points,
    required this.pulse,
    required this.enter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = ring.withValues(alpha: 0.7);
    for (final r in [82.0, 128.0]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: center,
              width: 2 * r * enter,
              height: 2 * r * 0.58 * enter),
          ringPaint);
    }
    // Liens qui pulsent du globe vers chaque visage.
    for (final (i, p) in points.indexed) {
      final a = 0.15 + 0.25 * (0.5 + 0.5 * math.sin(_tau(pulse * 2 + i / 6)));
      canvas.drawLine(
          center,
          p,
          Paint()
            ..strokeWidth = 1.2
            ..color = link.withValues(alpha: a * enter));
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => true;
}

/// 3. Les mots : un message qui s'écrit, puis des confettis.
class MessageScene extends OnboardingScene {
  const MessageScene({super.key, required super.loop, required super.focus});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final message = l10n.translate('onbMessage');
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) {
        // Écriture sur 55 % du cycle, puis le message reste affiché.
        final typing = (loop.value / 0.55).clamp(0.0, 1.0);
        final chars = message.characters;
        final shown = chars.take((chars.length * typing).round()).toString();
        final done = typing >= 1;
        final caretOn = !done && (loop.value * 24).floor().isEven;
        final enter = Curves.easeOutCubic.transform(focus.clamp(0.0, 1.0));
        return SizedBox.square(
          dimension: OnboardingScene.size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ConfettiPainter(
                    progress: loop.value,
                    visible: done ? 1 : 0.25,
                    colors: [
                      c.primary,
                      c.secondary,
                      const Color(0xFFF2B8C6),
                      const Color(0xFFA8DCC8)
                    ],
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, 30 * (1 - enter)),
                child: Opacity(
                  opacity: enter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: Space.s, bottom: Space.s),
                        child: Text(l10n.translate('onbTo'),
                            style: t.labelMedium
                                ?.copyWith(color: c.onSurfaceVariant)),
                      ),
                      SizedBox(
                        width: 260,
                        child: GlassCard(
                          tint: c.primary,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(22),
                            topRight: Radius.circular(22),
                            bottomRight: Radius.circular(22),
                            bottomLeft: Radius.circular(6),
                          ),
                          padding: const EdgeInsets.all(Space.l),
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(text: shown),
                              // Le reste, invisible : la bulle garde sa taille.
                              TextSpan(
                                text: caretOn ? '|' : '',
                                style: TextStyle(color: c.secondary),
                              ),
                              TextSpan(
                                text: chars
                                    .skip(shown.characters.length)
                                    .toString(),
                                style:
                                    const TextStyle(color: Colors.transparent),
                              ),
                            ]),
                            style: t.bodyLarge?.copyWith(height: 1.45),
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.m),
                      Align(
                        alignment: Alignment.centerRight,
                        child: AnimatedScale(
                          scale: done ? 1 : 0.85,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          child: AnimatedOpacity(
                            opacity: done ? 1 : 0.4,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: Space.l, vertical: Space.s),
                              decoration: BoxDecoration(
                                color: c.primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.send_rounded,
                                      size: 16, color: c.onPrimary),
                                  const SizedBox(width: Space.s),
                                  Text(l10n.translate('onbSend'),
                                      style: t.labelLarge
                                          ?.copyWith(color: c.onPrimary)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final double visible;
  final List<Color> colors;
  _ConfettiPainter(
      {required this.progress, required this.visible, required this.colors});

  static final _seeds = List.generate(26, (i) {
    final r = math.Random(i * 7919 + 13);
    return (r.nextDouble(), r.nextDouble(), r.nextInt(2) + 1, r.nextDouble());
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final (i, (x0, y0, speed, spin)) in _seeds.indexed) {
      final y = ((y0 + progress * speed) % 1) * (size.height + 40) - 20;
      final x = x0 * size.width + 10 * math.sin(_tau(progress * speed + spin));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(_tau(progress * speed + spin));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-4, -2, 8, 4), const Radius.circular(1.5)),
        Paint()
          ..color = colors[i % colors.length].withValues(alpha: 0.7 * visible),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}

/// 4. Le ciel : des étoiles qui scintillent, deux étoiles jumelles reliées.
class SkyScene extends OnboardingScene {
  const SkyScene({super.key, required super.loop, required super.focus});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) {
        final enter = Curves.easeInOutCubic.transform(focus.clamp(0.0, 1.0));
        const s = OnboardingScene.size;
        const a = Offset(s * 0.28, s * 0.62);
        const b = Offset(s * 0.74, s * 0.34);
        Widget label(String text, Offset p, {required bool above}) =>
            Positioned(
              left: p.dx - 90,
              top: above ? p.dy - 52 : p.dy + 22,
              width: 180,
              child: Opacity(
                opacity: enter,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Space.m, vertical: Space.xs),
                    decoration: BoxDecoration(
                      color: c.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: c.outlineVariant),
                    ),
                    child: Text(text, style: t.labelMedium),
                  ),
                ),
              ),
            );
        return SizedBox.square(
          dimension: s,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Une fenêtre ronde sur la nuit, dans les deux thèmes.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(0, -0.2),
                      colors: [Color(0xFF2E3458), Color(0xFF12152A)],
                    ),
                    border: Border.all(color: c.secondary.withValues(alpha: 0.25)),
                    boxShadow: [
                      BoxShadow(
                        color: Brand.slate.withValues(alpha: 0.35),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _SkyPainter(
                    progress: loop.value,
                    link: enter,
                    star: Brand.goldSoft,
                    dust: Colors.white,
                    a: a,
                    b: b,
                  ),
                ),
              ),
              label(l10n.translate('onbYou'), a, above: false),
              label(l10n.translate('onbTwin'), b, above: true),
            ],
          ),
        );
      },
    );
  }
}

class _SkyPainter extends CustomPainter {
  final double progress;
  final double link;
  final Color star;
  final Color dust;
  final Offset a;
  final Offset b;
  _SkyPainter({
    required this.progress,
    required this.link,
    required this.star,
    required this.dust,
    required this.a,
    required this.b,
  });

  static final _stars = List.generate(46, (i) {
    final r = math.Random(i * 104729 + 7);
    return (
      r.nextDouble(),
      r.nextDouble(),
      r.nextDouble() * 1.6 + 0.6,
      r.nextInt(3) + 1,
      r.nextDouble()
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    for (final (x, y, r, speed, phase) in _stars) {
      final p = Offset(x * size.width, y * size.height);
      // Seulement dans le disque, plus discret vers le bord.
      final d = (p - center).distance / radius;
      if (d > 1) continue;
      final twinkle = 0.5 + 0.5 * math.sin(_tau(progress * speed + phase));
      canvas.drawCircle(
          p,
          r,
          Paint()
            ..color = dust.withValues(
                alpha: (0.15 + 0.45 * twinkle) * (1 - d * 0.6)));
    }
    // Le lien se trace à l'entrée de la page.
    final end = Offset.lerp(a, b, link)!;
    canvas.drawLine(
        a,
        end,
        Paint()
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = star.withValues(alpha: 0.8));
    for (final (i, p) in [a, b].indexed) {
      final glow = 0.6 + 0.4 * math.sin(_tau(progress * 2 + i * 0.5));
      canvas.drawCircle(
          p,
          26,
          Paint()
            ..shader = RadialGradient(colors: [
              star.withValues(alpha: 0.45 * glow),
              star.withValues(alpha: 0),
            ]).createShader(Rect.fromCircle(center: p, radius: 26)));
      _drawStar(canvas, p, 11, star);
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final rr = i.isEven ? r : r * 0.38;
      final ang = -math.pi / 2 + i * math.pi / 4;
      final q = c + Offset(math.cos(ang), math.sin(ang)) * rr;
      i == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SkyPainter old) => true;
}
