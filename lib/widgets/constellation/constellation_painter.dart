import 'dart:math' as math;
import 'dart:typed_data';
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

  static int monthLength(int month) => _monthLengths[month - 1];

  /// « MM-DD » -> index 0…365, ou null si la clé est invalide.
  static int? indexOfKey(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return null;
    final m = int.tryParse(parts[0]), d = int.tryParse(parts[1]);
    if (m == null || d == null || m < 1 || m > 12) return null;
    if (d < 1 || d > _monthLengths[m - 1]) return null;
    return monthStarts[m - 1] + d - 1;
  }

  /// Index d'une date (année ignorée).
  static int indexOfDate(DateTime d) => monthStarts[d.month - 1] + d.day - 1;

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

  /// Cercle de base (jours sans naissance) et rayon extérieur.
  static double inner(Size s) => s.shortestSide * 0.21;
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

/// Moyenne glissante circulaire (fenêtre 2 × [half] + 1).
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

/// Jour le plus fêté de chaque mois (index), pour tracer la constellation ;
/// les mois sans naissance sont ignorés.
List<int> brightestPerMonth(List<int> counts) {
  final out = <int>[];
  for (var m = 1; m <= 12; m++) {
    final start = DayRing.monthStarts[m - 1];
    var best = -1, bestCount = 0;
    for (var i = start; i < start + DayRing.monthLength(m); i++) {
      if (counts[i] > bestCount) {
        best = i;
        bestCount = counts[i];
      }
    }
    if (best >= 0) out.add(best);
  }
  return out;
}

/// Courbe fermée lisse (Catmull-Rom) passant par [points].
Path smoothClosedPath(List<Offset> points) {
  final path = Path();
  final n = points.length;
  if (n < 3) return path;
  path.moveTo(points[0].dx, points[0].dy);
  for (var i = 0; i < n; i++) {
    final p0 = points[(i - 1 + n) % n];
    final p1 = points[i];
    final p2 = points[(i + 1) % n];
    final p3 = points[(i + 2) % n];
    final c1 = p1 + (p2 - p0) / 6;
    final c2 = p2 - (p3 - p1) / 6;
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  path.close();
  return path;
}

/// Lueur d'étoile (blanche, 64 px) : dessinée une fois, puis teintée et
/// mise à l'échelle par drawRawAtlas pour les 366 étoiles en un seul appel.
final ui.Image _starSprite = () {
  const size = 64.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const c = Offset(size / 2, size / 2);
  canvas.drawCircle(
    c,
    size / 2,
    Paint()
      ..shader = ui.Gradient.radial(c, size / 2, const [
        Color(0xFFFFFFFF),
        Color(0x66FFFFFF),
        Color(0x14FFFFFF),
        Color(0x00FFFFFF),
      ], const [0, 0.12, 0.38, 1]),
  );
  canvas.drawCircle(c, 3.2, Paint()..color = const Color(0xFFFFFFFF));
  return recorder.endRecording().toImageSync(size.toInt(), size.toInt());
}();

/// Le ciel : dégradé, nébuleuse, fond d'étoiles, secteurs et noms des
/// mois, cercle de base. Enregistré une seule fois par taille, puis rejoué
/// (et plus jamais redessiné après l'entrée).
class SkyPainter extends CustomPainter {
  final Animation<double> entry;
  final Color line;
  final TextStyle labelStyle;
  final List<String> monthLabels;
  final int currentMonth; // 1…12

  SkyPainter({
    required this.entry,
    required this.line,
    required this.labelStyle,
    required this.monthLabels,
    required this.currentMonth,
  }) : super(repaint: entry);

  ui.Picture? _picture;
  Size? _pictureSize;

  ui.Picture _record(Size size) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = size.center(Offset.zero);
    final ri = DayRing.inner(size);
    final ro = DayRing.outer(size);
    final s = size.shortestSide;

    // Nébuleuse : deux voiles très doux, ardoise et or.
    canvas.drawCircle(
      center + Offset(-s * 0.18, -s * 0.12),
      s * 0.45,
      Paint()
        ..shader = ui.Gradient.radial(center + Offset(-s * 0.18, -s * 0.12),
            s * 0.45, const [Color(0x2E6C78C8), Color(0x006C78C8)]),
    );
    canvas.drawCircle(
      center + Offset(s * 0.22, s * 0.2),
      s * 0.38,
      Paint()
        ..shader = ui.Gradient.radial(center + Offset(s * 0.22, s * 0.2),
            s * 0.38, const [Color(0x1FE8CD86), Color(0x00E8CD86)]),
    );

    // Fond d'étoiles fixe (graine constante : toujours le même ciel).
    final rnd = math.Random(2026);
    final dust = Paint();
    for (var i = 0; i < 150; i++) {
      final p = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      dust.color = const Color(0xFFFFFFFF)
          .withValues(alpha: 0.12 + rnd.nextDouble() * 0.38);
      canvas.drawCircle(p, 0.3 + rnd.nextDouble() * 0.8, dust);
    }

    // Un mois sur deux, un secteur à peine plus clair.
    final sector = Paint()..color = line.withValues(alpha: 0.035);
    final ring = Rect.fromCircle(center: center, radius: ro + 6);
    for (var m = 0; m < 12; m += 2) {
      final a0 = DayRing.angleOf(DayRing.monthStarts[m]);
      final sweep = 2 * math.pi * DayRing.monthLength(m + 1) / DayRing.days;
      final path = Path()
        ..moveTo(center.dx + math.cos(a0) * ri, center.dy + math.sin(a0) * ri)
        ..arcTo(ring, a0, sweep, false)
        ..arcTo(Rect.fromCircle(center: center, radius: ri), a0 + sweep, -sweep,
            false)
        ..close();
      canvas.drawPath(path, sector);
    }

    // Cercle de base et noms des mois (le mois en cours plus marqué).
    canvas.drawCircle(
        center,
        ri,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = line.withValues(alpha: 0.28));
    for (var m = 0; m < 12; m++) {
      final mid = DayRing.angleOf(
          DayRing.monthStarts[m] + DayRing.monthLength(m + 1) / 2);
      final current = m + 1 == currentMonth;
      final tp = TextPainter(
        text: TextSpan(
          text: monthLabels[m],
          style: labelStyle.copyWith(
            color: labelStyle.color!.withValues(alpha: current ? 1 : 0.55),
            fontWeight: current ? FontWeight.w700 : labelStyle.fontWeight,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final at = center + Offset(math.cos(mid), math.sin(mid)) * (ro + 17);
      tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
    }
    return recorder.endRecording();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final e = entry.value;
    if (_picture == null || _pictureSize != size) {
      _picture?.dispose();
      _picture = _record(size);
      _pictureSize = size;
    }
    if (e >= 1) {
      canvas.drawPicture(_picture!);
      return;
    }
    canvas.saveLayer(Offset.zero & size,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: e.clamp(0, 1)));
    canvas.drawPicture(_picture!);
    canvas.restore();
  }

  @override
  bool shouldRepaint(SkyPainter old) =>
      old.line != line ||
      old.labelStyle != labelStyle ||
      old.currentMonth != currentMonth ||
      !listEquals(old.monthLabels, monthLabels);
}

/// Les étoiles, la silhouette de l'année, la constellation, son propre jour,
/// la sélection et la comète. Repeint par [entry], [clock] et [select]
/// sans reconstruire de widgets.
class ConstellationPainter extends CustomPainter {
  final List<int> counts; // 366 nombres de naissances
  final int? mine;
  final int? selected;
  final int today;
  final Animation<double> entry; // 0 -> 1, une fois
  final Animation<double> clock; // 0 -> 1 en boucle (12 s)
  final Animation<double> select; // 0 -> 1 à chaque sélection
  final Color cool;
  final Color warm;
  final Color gold;
  final TextStyle tagStyle;
  final String? selectedLabel;

  ConstellationPainter({
    required this.counts,
    required this.mine,
    required this.selected,
    required this.today,
    required this.entry,
    required this.clock,
    required this.select,
    required this.cool,
    required this.warm,
    required this.gold,
    required this.tagStyle,
    this.selectedLabel,
  })  : levels = normalizeCounts(counts),
        super(repaint: Listenable.merge([entry, clock, select])) {
    _smooth = smoothCircular(levels, half: 4);
    final ranked = [for (var i = 0; i < DayRing.days; i++) i]
      ..sort((a, b) => counts[b].compareTo(counts[a]));
    _top = {
      for (final i in ranked.take(3))
        if (counts[i] > 0) i,
    };
    _links = brightestPerMonth(counts);
  }

  final List<double> levels;
  late final List<double> _smooth;
  late final Set<int> _top;
  late final List<int> _links;

  /// Phase de scintillement propre à chaque étoile, stable.
  static final List<double> _phase = [
    for (var i = 0; i < DayRing.days; i++) (i * 0.61803398875) % 1.0
  ];

  /// Légère variation angulaire : un ciel, pas une grille.
  static final List<double> _jitter = [
    for (var i = 0; i < DayRing.days; i++)
      (((math.sin(i * 12.9898) * 43758.5453) % 1.0).abs() - 0.5) * 0.009
  ];

  /// Éclosion en balayage depuis le 1er janvier.
  static double progress(double e, int i) {
    final delay = (i / DayRing.days) * 0.45;
    return Curves.easeOutCubic.transform(((e - delay) / 0.45).clamp(0.0, 1.0));
  }

  Offset _pos(Size size, int i, double p) {
    final ri = DayRing.inner(size);
    final r = ri + (DayRing.radiusFor(size, levels[i]) - ri) * p;
    final a = DayRing.angleOf(i) + _jitter[i];
    return size.center(Offset.zero) + Offset(math.cos(a), math.sin(a)) * r;
  }

  Offset restingCenter(Size size, int i) => _pos(size, i, 1);

  // Tampons réutilisés d'une image à l'autre (aucune allocation par image).
  final Float32List _transforms = Float32List(DayRing.days * 4);
  final Float32List _rects = Float32List(DayRing.days * 4);
  final Int32List _colors = Int32List(DayRing.days);

  final _fill = Paint()..isAntiAlias = true;
  final _stroke = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final _atlas = Paint()..filterQuality = FilterQuality.medium;

  Path? _aura;
  ui.PathMetric? _auraMetric;
  Size? _auraSize;
  TextPainter? _tag;
  String? _tagText;

  void _prepareAura(Size size) {
    if (_aura != null && _auraSize == size) return;
    final center = size.center(Offset.zero);
    final pts = <Offset>[
      for (var i = 0; i < DayRing.days; i += 6)
        center + DayRing.unit[i] * DayRing.radiusFor(size, _smooth[i]),
    ];
    _aura = smoothClosedPath(pts);
    _auraMetric = _aura!.computeMetrics().first;
    _auraSize = size;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final e = entry.value;
    if (e <= 0) return;
    final t = clock.value;
    final center = size.center(Offset.zero);
    final ri = DayRing.inner(size);
    final ro = DayRing.outer(size);
    _prepareAura(size);

    // 1. Silhouette de l'année : voile, puis contour qui se dessine.
    final auraIn = Curves.easeInOut.transform(((e - 0.15) / 0.7).clamp(0.0, 1.0));
    if (auraIn > 0) {
      _fill.shader = ui.Gradient.radial(center, ro, [
        cool.withValues(alpha: 0),
        cool.withValues(alpha: 0.13 * auraIn),
      ], [0.5, 1]);
      canvas.drawPath(_aura!, _fill);
      _fill.shader = null;
      final m = _auraMetric!;
      _stroke
        ..strokeWidth = 1.1
        ..color = cool.withValues(alpha: 0.42);
      canvas.drawPath(m.extractPath(0, m.length * auraIn), _stroke);
    }

    // 2. Constellation : le jour le plus fêté de chaque mois, relié.
    final linesIn = ((e - 0.6) / 0.4).clamp(0.0, 1.0);
    if (linesIn > 0 && _links.length > 1) {
      _stroke
        ..strokeWidth = 0.9
        ..color = warm.withValues(alpha: 0.3 * linesIn);
      final n = _links.length;
      final drawn = linesIn * n;
      for (var k = 0; k < n; k++) {
        if (k >= drawn) break;
        final a = restingCenter(size, _links[k]);
        final b = restingCenter(size, _links[(k + 1) % n]);
        final part = (drawn - k).clamp(0.0, 1.0);
        canvas.drawLine(a, Offset.lerp(a, b, part)!, _stroke);
      }
    }

    // 3. Étoiles : une lueur teintée par étoile, toutes en un seul appel.
    var n = 0;
    for (var i = 0; i < DayRing.days; i++) {
      if (i == mine) continue;
      final p = progress(e, i);
      if (p <= 0) continue;
      final level = levels[i];
      final pos = _pos(size, i, p);
      final twinkle = 0.78 + 0.22 * math.sin(2 * math.pi * (t * 6 + _phase[i]));
      final scale = (level <= 0 ? 0.07 : 0.12 + 0.36 * level) * (0.6 + 0.4 * p);
      final color = level <= 0
          ? cool.withValues(alpha: 0.28 * p)
          : Color.lerp(cool, warm, level)!
              .withValues(alpha: ((0.45 + 0.55 * level) * twinkle * p).clamp(0, 1));
      final j = n * 4;
      _transforms[j] = scale;
      _transforms[j + 1] = 0;
      _transforms[j + 2] = pos.dx - 32 * scale;
      _transforms[j + 3] = pos.dy - 32 * scale;
      _rects[j] = 0;
      _rects[j + 1] = 0;
      _rects[j + 2] = 64;
      _rects[j + 3] = 64;
      _colors[n] = color.toARGB32();
      n++;
    }
    if (n > 0) {
      canvas.drawRawAtlas(
        _starSprite,
        Float32List.sublistView(_transforms, 0, n * 4),
        Float32List.sublistView(_rects, 0, n * 4),
        Int32List.sublistView(_colors, 0, n),
        BlendMode.modulate,
        null,
        _atlas,
      );
    }

    // 4. Aigrettes des trois jours les plus fêtés.
    if (e >= 0.9) {
      final a = ((e - 0.9) / 0.1).clamp(0.0, 1.0);
      for (final i in _top) {
        if (i == mine) continue;
        final pos = restingCenter(size, i);
        final len = 9 + 3 * math.sin(2 * math.pi * (t * 3 + _phase[i]));
        _spikes(canvas, pos, len, warm.withValues(alpha: 0.75 * a), t);
      }
    }

    // 5. Aujourd'hui : un trait fin sur le cercle de base.
    final u = DayRing.unit[today];
    _stroke
      ..strokeWidth = 1.4
      ..color = cool.withValues(alpha: 0.8 * e);
    canvas.drawLine(center + u * (ri - 7), center + u * (ri + 7), _stroke);

    // 6. La comète : fait le tour de l'année toutes les 12 secondes.
    if (e >= 1) {
      final head = t * DayRing.days;
      for (var k = 0; k < 14; k++) {
        final idx = head - k * 1.6;
        final a = DayRing.angleOf(idx);
        final pt = center + Offset(math.cos(a), math.sin(a)) * (ri - 0.5);
        _fill.color = cool.withValues(alpha: 0.55 * (1 - k / 14));
        canvas.drawCircle(pt, 1.7 * (1 - k / 20), _fill);
      }
    }

    // 7. Sélection : anneau qui s'ouvre, rayon, étiquette flottante.
    final sel = selected;
    if (sel != null && e >= 1) {
      final s = Curves.easeOutBack.transform(select.value.clamp(0.0, 1.0));
      final pos = restingCenter(size, sel);
      _stroke
        ..strokeWidth = 1.3
        ..color = warm.withValues(alpha: 0.95 * select.value);
      canvas.drawCircle(pos, 4 + 6 * s, _stroke);
      _stroke
        ..strokeWidth = 0.8
        ..color = warm.withValues(alpha: 0.35 * select.value);
      canvas.drawLine(center + (pos - center) * (ri / (pos - center).distance),
          pos, _stroke);
      _paintTag(canvas, size, pos, select.value);
    }

    // 8. Son propre jour : étoile dorée, aigrettes, halo qui respire.
    final me = mine;
    if (me != null) {
      final p = ((e - 0.55) / 0.45).clamp(0.0, 1.0);
      if (p > 0) {
        final pos = restingCenter(size, me);
        final pulse = 0.5 + 0.5 * math.sin(2 * math.pi * t * 4);
        _fill.shader = ui.Gradient.radial(pos, 22, [
          gold.withValues(alpha: (0.35 + 0.25 * pulse) * p),
          gold.withValues(alpha: 0),
        ]);
        canvas.drawCircle(pos, 22, _fill);
        _fill.shader = null;
        _spikes(canvas, pos, 12 + 3 * pulse, gold.withValues(alpha: p), t);
        _fill.color = gold.withValues(alpha: p);
        canvas.drawCircle(pos, 3.6 * p, _fill);
        _fill.color = const Color(0xFFFFFFFF).withValues(alpha: 0.9 * p);
        canvas.drawCircle(pos, 1.4 * p, _fill);
      }
    }
  }

  /// Aigrettes en croix (diffraction), qui tournent très lentement.
  void _spikes(Canvas canvas, Offset c, double len, Color color, double t) {
    final rot = t * 2 * math.pi * 0.25;
    for (var k = 0; k < 2; k++) {
      final a = rot + k * math.pi / 2;
      final d = Offset(math.cos(a), math.sin(a)) * len;
      _stroke
        ..strokeWidth = 0.9
        ..shader = ui.Gradient.linear(c - d, c + d, [
          color.withValues(alpha: 0),
          color,
          color.withValues(alpha: 0),
        ], [0, 0.5, 1]);
      canvas.drawLine(c - d, c + d, _stroke);
    }
    _stroke.shader = null;
  }

  void _paintTag(Canvas canvas, Size size, Offset star, double a) {
    final text = selectedLabel;
    if (text == null) return;
    if (_tag == null || _tagText != text) {
      _tag = TextPainter(
        text: TextSpan(text: text, style: tagStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      _tagText = text;
    }
    final tp = _tag!;
    const padH = 8.0, padV = 4.0;
    final w = tp.width + padH * 2, h = tp.height + padV * 2;
    var x = star.dx - w / 2;
    var y = star.dy - h - 14;
    if (y < 4) y = star.dy + 14;
    x = x.clamp(4.0, size.width - w - 4);
    final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h), const Radius.circular(8));
    _fill.color = const Color(0xE6151A33).withValues(alpha: 0.9 * a);
    canvas.drawRRect(rect, _fill);
    _stroke
      ..strokeWidth = 1
      ..color = warm.withValues(alpha: 0.35 * a);
    canvas.drawRRect(rect, _stroke);
    canvas.saveLayer(rect.outerRect,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: a));
    tp.paint(canvas, Offset(x + padH, y + padV));
    canvas.restore();
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
      !listEquals(old.counts, counts) ||
      old.mine != mine ||
      old.selected != selected ||
      old.today != today ||
      old.selectedLabel != selectedLabel ||
      old.cool != cool ||
      old.warm != warm ||
      old.gold != gold;
}
