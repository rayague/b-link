import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart' show Listenable, listEquals;
import 'package:flutter/rendering.dart';

/// Géométrie de la constellation : 366 jours (année bissextile) autour du
/// centre, le 1er janvier en haut, dans le sens des aiguilles d'une montre.
abstract final class DayRing {
  static const days = 366;
  static const _monthLengths = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  /// Premier index de chaque mois.
  static final List<int> monthStarts = () {
    final s = <int>[];
    var acc = 0;
    for (final l in _monthLengths) {
      s.add(acc);
      acc += l;
    }
    return s;
  }();

  /// « MM-DD » -> index 0…365, ou null si la clé est invalide.
  static int? indexOfKey(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return null;
    final m = int.tryParse(parts[0]), d = int.tryParse(parts[1]);
    if (m == null || d == null || m < 1 || m > 12) return null;
    if (d < 1 || d > _monthLengths[m - 1]) return null;
    return monthStarts[m - 1] + d - 1;
  }

  /// Index -> (mois, jour).
  static (int, int) monthDayOf(int index) {
    var m = 11;
    while (monthStarts[m] > index) {
      m--;
    }
    return (m + 1, index - monthStarts[m] + 1);
  }

  /// Angle de l'index (radians, 0 = en haut).
  static double angleOf(num index) => 2 * math.pi * index / days - math.pi / 2;

  /// Vecteurs unitaires précalculés (aucun sin/cos par étoile au dessin).
  static final List<Offset> unit = [
    for (var i = 0; i < days; i++)
      Offset(math.cos(angleOf(i)), math.sin(angleOf(i))),
  ];

  /// Rayon du cercle de base (jours sans naissance) et rayon extérieur.
  static double inner(Size s) => s.shortestSide * 0.20;
  static double outer(Size s) => s.shortestSide * 0.40;

  /// Distance au centre d'une étoile de niveau [level] (0…1).
  static double radiusFor(Size s, double level) {
    final ri = inner(s);
    return level <= 0 ? ri : ri + (outer(s) - ri) * (0.12 + 0.88 * level);
  }
}

/// Comptes normalisés (0…1) par jour : racine carrée pour que les petits
/// nombres restent visibles à côté des grands.
List<double> normalizeCounts(List<int> counts) {
  final maxCount = counts.fold<int>(0, math.max);
  if (maxCount == 0) return List.filled(counts.length, 0);
  return [for (final c in counts) math.sqrt(c / maxCount)];
}

/// Moyenne glissante circulaire (fenêtre 2 × [half] + 1) : la silhouette
/// lissée de l'année.
List<double> smoothCircular(List<double> v, {int half = 3}) {
  final n = v.length;
  final out = List<double>.filled(n, 0);
  for (var i = 0; i < n; i++) {
    var s = 0.0;
    for (var k = -half; k <= half; k++) {
      s += v[(i + k + n) % n];
    }
    out[i] = s / (2 * half + 1);
  }
  return out;
}

/// Dessine les étoiles, l'aura et son propre jour. Repeint par [entry] et
/// [clock] sans reconstruire de widgets : seul ce painter travaille à
/// chaque image, et la silhouette n'est recalculée que pendant l'entrée.
class ConstellationPainter extends CustomPainter {
  final List<double> levels; // 366 valeurs 0…1
  final int? mine;
  final int? selected;
  final Animation<double> entry; // 0 -> 1, une fois
  final Animation<double> clock; // 0 -> 1 en boucle
  final Color star;
  final Color faint;
  final Color gold;

  ConstellationPainter({
    required this.levels,
    required this.mine,
    required this.selected,
    required this.entry,
    required this.clock,
    required this.star,
    required this.faint,
    required this.gold,
  })  : _smooth = smoothCircular(levels),
        super(repaint: Listenable.merge([entry, clock]));

  final List<double> _smooth;

  /// Phase de scintillement propre à chaque étoile, stable.
  static final List<double> _phase = [
    for (var i = 0; i < DayRing.days; i++) (i * 0.61803398875) % 1.0
  ];

  /// Petite variation angulaire stable : un ciel, pas une grille.
  static final List<double> _jitter = [
    for (var i = 0; i < DayRing.days; i++)
      ((math.sin(i * 12.9898) * 43758.5453) % 1.0).abs() * 0.008 - 0.004
  ];

  static double starRadius(double level) => level <= 0 ? 0.8 : 1.0 + 2.4 * level;

  /// Progression de l'entrée pour l'étoile [i] : balayage dans le sens des
  /// aiguilles d'une montre depuis le 1er janvier.
  static double _progress(double e, int i) {
    final delay = (i / DayRing.days) * 0.5;
    return Curves.easeOutCubic.transform(((e - delay) / 0.5).clamp(0.0, 1.0));
  }

  /// Centre de l'étoile [i] une fois l'entrée terminée.
  Offset restingCenter(Size size, int i) => _pos(size, i, 1);

  Offset _pos(Size size, int i, double p) {
    final ri = DayRing.inner(size);
    final r = ri + (DayRing.radiusFor(size, levels[i]) - ri) * p;
    final a = DayRing.angleOf(i) + _jitter[i];
    return size.center(Offset.zero) + Offset(math.cos(a), math.sin(a)) * r;
  }

  final _fill = Paint()..isAntiAlias = true;
  final _glow = Paint()
    ..isAntiAlias = true
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  final _stroke = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke;

  Path? _aura;
  Size? _auraSize;

  /// Silhouette lissée : recalculée pendant l'entrée, puis gardée.
  Path _auraPath(Size size, double e) {
    if (e >= 1 && _aura != null && _auraSize == size) return _aura!;
    final ri = DayRing.inner(size);
    final center = size.center(Offset.zero);
    final path = Path();
    for (var i = 0; i <= DayRing.days; i++) {
      final k = i % DayRing.days;
      final p = _progress(e, k);
      final r = ri + (DayRing.radiusFor(size, _smooth[k]) - ri) * p;
      final pt = center + DayRing.unit[k] * r;
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    if (e >= 1) {
      _aura = path;
      _auraSize = size;
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final e = entry.value;
    final t = clock.value;
    if (e <= 0) return;

    // Aura : la forme de l'année, en voile très léger.
    final aura = _auraPath(size, e);
    _fill.shader = ui.Gradient.radial(center, DayRing.outer(size), [
      star.withValues(alpha: 0.0),
      star.withValues(alpha: 0.10 * e),
    ], [0.45, 1]);
    canvas.drawPath(aura, _fill);
    _fill.shader = null;
    _stroke
      ..color = star.withValues(alpha: 0.28 * e)
      ..strokeWidth = 1;
    canvas.drawPath(aura, _stroke);

    // Étoiles.
    for (var i = 0; i < DayRing.days; i++) {
      if (i == mine) continue; // dessinée par-dessus, en or
      final p = _progress(e, i);
      if (p <= 0) continue;
      final level = levels[i];
      final pos = _pos(size, i, p);
      final twinkle = 0.8 + 0.2 * math.sin(2 * math.pi * (t * 3 + _phase[i]));
      final radius = starRadius(level);
      if (level > 0.8) {
        _glow.color = star.withValues(alpha: 0.45 * twinkle * p);
        canvas.drawCircle(pos, radius * 2.6, _glow);
      }
      final alpha = level <= 0 ? 0.25 : (0.4 + 0.6 * level) * twinkle;
      _fill.color = (level <= 0 ? faint : star).withValues(alpha: alpha * p);
      canvas.drawCircle(pos, radius, _fill);
    }

    // Jour sélectionné : un anneau fin.
    final sel = selected;
    if (sel != null && e >= 1) {
      _stroke
        ..color = star.withValues(alpha: 0.95)
        ..strokeWidth = 1.4;
      canvas.drawCircle(
          restingCenter(size, sel), starRadius(levels[sel]) + 7, _stroke);
    }

    // Son propre jour : étoile dorée, rayon, halo qui pulse.
    final me = mine;
    if (me != null) {
      final p = ((e - 0.55) / 0.45).clamp(0.0, 1.0);
      if (p > 0) {
        final pos = restingCenter(size, me);
        final pulse = 0.5 + 0.5 * math.sin(2 * math.pi * t * 2);
        final from = center + (pos - center) * 0.42;
        _stroke
          ..shader = ui.Gradient.linear(from, pos, [
            gold.withValues(alpha: 0),
            gold.withValues(alpha: 0.6 * p),
          ])
          ..strokeWidth = 1.2;
        canvas.drawLine(from, pos, _stroke);
        _stroke.shader = null;
        _glow.color = gold.withValues(alpha: (0.3 + 0.3 * pulse) * p);
        canvas.drawCircle(pos, (11 + 5 * pulse) * p, _glow);
        _fill.color = gold.withValues(alpha: p);
        canvas.drawCircle(pos, 4.2 * p, _fill);
      }
    }
  }

  /// Jour sous [point] (tolérance d'angle et de distance), ou null.
  static int? dayAt(Size size, Offset point) {
    final v = point - size.center(Offset.zero);
    final d = v.distance;
    if (d < DayRing.inner(size) - 22 || d > DayRing.outer(size) + 22) {
      return null;
    }
    var angle = math.atan2(v.dy, v.dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    return (angle / (2 * math.pi) * DayRing.days).round() % DayRing.days;
  }

  @override
  bool shouldRepaint(ConstellationPainter old) =>
      !listEquals(old.levels, levels) ||
      old.mine != mine ||
      old.selected != selected ||
      old.star != star ||
      old.gold != gold;
}

/// Fond : cercle de base, repères et noms des mois. Ne se redessine que
/// pendant l'entrée.
class RingPainter extends CustomPainter {
  final Animation<double> entry;
  final Color line;
  final TextStyle labelStyle;
  final List<String> monthLabels;

  RingPainter({
    required this.entry,
    required this.line,
    required this.labelStyle,
    required this.monthLabels,
  }) : super(repaint: entry);

  late final List<TextPainter> _labels = [
    for (final s in monthLabels)
      TextPainter(
        text: TextSpan(text: s, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final e = entry.value;
    if (e <= 0) return;
    final center = size.center(Offset.zero);
    final ri = DayRing.inner(size);
    final ro = DayRing.outer(size);
    final fading = e < 1;
    if (fading) {
      canvas.saveLayer(Offset.zero & size,
          Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: e));
    }
    final stroke = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = line.withValues(alpha: 0.22);
    canvas.drawCircle(center, ri, stroke);
    stroke.color = line.withValues(alpha: 0.08);
    canvas.drawCircle(center, ro, stroke);
    for (var m = 0; m < 12; m++) {
      // Repère au début du mois, nom au milieu du mois.
      final u = DayRing.unit[DayRing.monthStarts[m]];
      stroke.color = line.withValues(alpha: 0.18);
      canvas.drawLine(center + u * (ri - 4), center + u * (ro + 6), stroke);
      final mid = DayRing.angleOf(DayRing.monthStarts[m] + 15);
      final at = center + Offset(math.cos(mid), math.sin(mid)) * (ro + 18);
      final tp = _labels[m];
      tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
    }
    if (fading) canvas.restore();
  }

  @override
  bool shouldRepaint(RingPainter old) =>
      old.line != line ||
      old.labelStyle != labelStyle ||
      !listEquals(old.monthLabels, monthLabels);
}
