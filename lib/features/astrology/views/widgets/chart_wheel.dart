import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/astro_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/chart_palette.dart';
import '../../../../core/utils/formatters.dart';
import '../../model/aspect_model.dart';
import '../../model/astrology_result_model.dart';

/// Colourful birth-chart wheel on a night-sky disc: sign ring in element
/// gradients, planets in their own colours, Placidus houses, Ascendant and
/// Midheaven axes and glowing aspect lines. The Ascendant sits on the left.
class ChartWheel extends StatelessWidget {
  const ChartWheel({super.key, required this.result, this.showAspects = true});

  final AstrologyResultModel result;
  final bool showAspects;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Birth chart wheel. Sun in ${result.sunSign}, Moon in ${result.moonSign}'
          '${result.ascendant != null ? ', ${result.ascendant} rising' : ''}. '
          '${result.aspects.length} aspects.',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: _WheelPainter(result: result, showAspects: showAspects),
          ),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.result, required this.showAspects});

  final AstrologyResultModel result;
  final bool showAspects;

  static const _view = 396.0;
  static const _c = 198.0;
  static const _center = Offset(_c, _c);
  static const _rim = 186.0; // outer glow rim
  static const _outer = 176.0; // sign ring outer edge
  static const _signIn = 148.0; // sign ring inner edge
  static const _planetR = 127.0; // planet badges
  static const _houseOut = 104.0; // house ring outer edge
  static const _houseIn = 86.0; // house ring inner edge, aspect circle

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _view);
    final asc = result.ascendantLongitude;
    final left = asc ?? (normalizeDegrees(result.sunLongitude) ~/ 30) * 30.0;

    double angle(double longitude) => (180 + longitude - left) * math.pi / 180;
    Offset p(double longitude, double r) {
      final th = angle(longitude);
      return Offset(_c + r * math.cos(th), _c - r * math.sin(th));
    }

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = ChartPalette.line;

    _background(canvas);

    // Sign ring: each sign a gradient arc in its element's colours.
    for (var k = 0; k < 12; k++) {
      final sign = zodiacSigns[k];
      final grad = ChartPalette.element(sign.element);
      final a0 = k * 30.0;
      final path = _ringSegment(p, a0, a0 + 30, _signIn, _outer);
      final rect = Rect.fromPoints(p(a0, _outer), p(a0 + 30, _signIn));
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            colors: [grad[0].withValues(alpha: 0.85), grad[1].withValues(alpha: 0.85)],
          ).createShader(rect.inflate(6)),
      );
      // Darken the inner half so glyphs read clearly.
      canvas.drawPath(
        path,
        Paint()
          ..shader = RadialGradient(
            colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent],
            stops: [_signIn / _outer, 1],
          ).createShader(Rect.fromCircle(center: _center, radius: _outer)),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = ChartPalette.skyEdge.withValues(alpha: 0.7),
      );
      _text(
        canvas,
        sign.symbol + AppTextStyles.textVariation,
        p(a0 + 15, (_outer + _signIn) / 2),
        AppTextStyles.symbol(
          16,
          Colors.white,
        ).copyWith(shadows: const [Shadow(color: Color(0x99000000), blurRadius: 4)]),
      );
      // Degree ticks just inside the sign ring.
      for (var d = 1; d < 30; d++) {
        final len = d % 10 == 0 ? 6.0 : (d % 5 == 0 ? 4.0 : 2.0);
        canvas.drawLine(
          p(a0 + d, _signIn),
          p(a0 + d, _signIn - len),
          Paint()
            ..strokeWidth = d % 5 == 0 ? 1 : 0.6
            ..color = grad[0].withValues(alpha: d % 5 == 0 ? 0.8 : 0.45),
        );
      }
    }

    // House ring with alternating tints.
    if (result.hasHouses) {
      for (final h in result.houses) {
        final next = result.houses[h.number % 12].cusp;
        final span = normalizeDegrees(next - h.cusp);
        canvas.drawPath(
          _ringSegment(p, h.cusp, h.cusp + span, _houseIn, _houseOut),
          Paint()
            ..color = (h.number.isOdd ? const Color(0xFF7B8CFF) : const Color(0xFF39D0E6))
                .withValues(alpha: 0.12),
        );
      }
    } else {
      canvas.drawCircle(
        _center,
        (_houseOut + _houseIn) / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _houseOut - _houseIn
          ..color = const Color(0x147B8CFF),
      );
    }
    canvas.drawCircle(_center, _signIn, line);
    canvas.drawCircle(_center, _houseOut, line);
    canvas.drawCircle(_center, _houseIn, line);

    // Inner aspect disc.
    canvas.drawCircle(
      _center,
      _houseIn,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF2A3A6E), Color(0xFF111A33)],
        ).createShader(Rect.fromCircle(center: _center, radius: _houseIn)),
    );

    // House cusps: angular ones (1, 4, 7, 10) are stronger.
    if (result.hasHouses) {
      for (final h in result.houses) {
        final angular = h.number % 3 == 1;
        canvas.drawLine(
          p(h.cusp, _houseIn),
          p(h.cusp, angular ? _signIn : _houseOut),
          Paint()
            ..strokeWidth = angular ? 1.3 : 0.7
            ..color = angular ? ChartPalette.textMuted : ChartPalette.line,
        );
        final next = result.houses[h.number % 12].cusp;
        final mid = h.cusp + normalizeDegrees(next - h.cusp) / 2;
        _text(
          canvas,
          '${h.number}',
          p(mid, (_houseOut + _houseIn) / 2),
          AppTextStyles.mono(9.5, ChartPalette.textMuted),
        );
      }
    }

    // Aspect lines with a soft glow.
    if (showAspects) {
      for (final a in result.aspects) {
        if (a.type == AspectType.conjunction) continue;
        final la = result.longitudeOf(a.a);
        final lb = result.longitudeOf(a.b);
        if (la == null || lb == null) continue;
        final color = ChartPalette.aspect(a.type);
        final width = a.strength == 3 ? 1.8 : (a.strength == 2 ? 1.3 : 0.8);
        final from = p(la, _houseIn - 3);
        final to = p(lb, _houseIn - 3);
        canvas.drawLine(
          from,
          to,
          Paint()
            ..strokeWidth = width + 3
            ..strokeCap = StrokeCap.round
            ..color = color.withValues(alpha: 0.18)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
        );
        canvas.drawLine(
          from,
          to,
          Paint()
            ..strokeWidth = width
            ..strokeCap = StrokeCap.round
            ..color = color.withValues(alpha: a.strength == 1 ? 0.55 : 0.95),
        );
        for (final end in [from, to]) {
          canvas.drawCircle(end, 1.6, Paint()..color = color);
        }
      }
    }

    // Centre medallion.
    canvas.drawCircle(
      _center,
      14,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFF1B8), Color(0xFFFFC94A), Color(0xFFE08A1E)],
          stops: [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: _center, radius: 14)),
    );
    canvas.drawCircle(
      _center,
      20,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = ChartPalette.gold.withValues(alpha: 0.35),
    );

    // Ascendant–Descendant and Midheaven–IC axes.
    void axis(double lon, String label) {
      final paint = Paint()
        ..strokeWidth = 1.8
        ..color = ChartPalette.gold;
      canvas.drawLine(p(lon, _houseIn), p(lon, _outer + 3), paint);
      canvas.drawLine(
        p(lon + 180, _houseIn),
        p(lon + 180, _signIn),
        paint
          ..strokeWidth = 1
          ..color = ChartPalette.gold.withValues(alpha: 0.6),
      );
      // Arrowhead pointing outward.
      final th = angle(lon);
      final tip = p(lon, _outer + 6);
      final dir = Offset(math.cos(th), -math.sin(th));
      final side = Offset(-dir.dy, dir.dx);
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo((tip - dir * 7 + side * 4).dx, (tip - dir * 7 + side * 4).dy)
          ..lineTo((tip - dir * 7 - side * 4).dx, (tip - dir * 7 - side * 4).dy)
          ..close(),
        Paint()..color = ChartPalette.gold,
      );
      _text(
        canvas,
        label,
        p(lon, _rim + 4),
        AppTextStyles.mono(9.5, ChartPalette.gold).copyWith(fontWeight: FontWeight.w700),
      );
    }

    if (asc != null) axis(asc, 'AC');
    if (result.mcLongitude != null) axis(result.mcLongitude!, 'MC');

    // Planets in coloured badges. Crowded planets are spread sideways along
    // the ring; a pointer still marks each exact degree.
    final planets = [...result.planets]
      ..sort((a, b) => normalizeDegrees(a.longitude).compareTo(normalizeDegrees(b.longitude)));
    final shown = _spread([for (final pl in planets) normalizeDegrees(pl.longitude)], 10.5);
    for (var i = 0; i < planets.length; i++) {
      final planet = planets[i];
      final l = normalizeDegrees(planet.longitude);
      const r = _planetR;
      final color = ChartPalette.planet(planet.name);
      final at = p(shown[i], r);
      final badge = planet.isNode ? 8.5 : 10.5;

      // Pointer from the badge to the exact degree.
      canvas.drawLine(
        p(l, _signIn),
        p(l, _signIn - 7),
        Paint()
          ..strokeWidth = 1.6
          ..color = color,
      );
      canvas.drawLine(
        p(l, _signIn - 7),
        p(shown[i], r + badge),
        Paint()
          ..strokeWidth = 0.6
          ..color = color.withValues(alpha: 0.35),
      );
      // Glow and badge.
      canvas.drawCircle(
        at,
        badge + 3,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(at, badge, Paint()..color = const Color(0xFF141C36));
      canvas.drawCircle(
        at,
        badge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = color,
      );
      _text(
        canvas,
        planet.symbol + AppTextStyles.textVariation,
        at,
        AppTextStyles.symbol(planet.isNode ? 11 : 13.5, color),
      );
      _text(
        canvas,
        '${(l % 30).floor()}°${planet.retrograde && !planet.isNode ? '℞' : ''}',
        p(shown[i], r - badge - 7),
        AppTextStyles.mono(7.5, ChartPalette.textMuted),
      );
    }
  }

  /// Spreads sorted longitudes so neighbours are at least [gap] degrees
  /// apart: each crowded group is laid out evenly around its own centre.
  static List<double> _spread(List<double> lons, double gap) {
    final n = lons.length;
    if (n < 2 || n * gap >= 360) return [...lons];
    // Start the line at the widest empty arc so groups never wrap around.
    var start = 0;
    var widest = -1.0;
    for (var i = 0; i < n; i++) {
      final d = normalizeDegrees(lons[i] - lons[(i - 1 + n) % n]);
      if (d > widest) {
        widest = d;
        start = i;
      }
    }
    final base = lons[start];
    final xs = [for (var k = 0; k < n; k++) base + normalizeDegrees(lons[(start + k) % n] - base)];
    // Groups of (first index, count); merge while any two overlap.
    final groups = [for (var k = 0; k < n; k++) (k, 1)];
    double centre((int, int) g) {
      var sum = 0.0;
      for (var k = g.$1; k < g.$1 + g.$2; k++) {
        sum += xs[k];
      }
      return sum / g.$2;
    }

    double lo((int, int) g) => centre(g) - (g.$2 - 1) * gap / 2;
    double hi((int, int) g) => centre(g) + (g.$2 - 1) * gap / 2;
    var merged = true;
    while (merged) {
      merged = false;
      for (var g = 0; g + 1 < groups.length; g++) {
        if (lo(groups[g + 1]) - hi(groups[g]) < gap) {
          groups[g] = (groups[g].$1, groups[g].$2 + groups[g + 1].$2);
          groups.removeAt(g + 1);
          merged = true;
          break;
        }
      }
    }
    final placed = List<double>.filled(n, 0);
    for (final g in groups) {
      final first = lo(g);
      for (var k = 0; k < g.$2; k++) {
        placed[(start + g.$1 + k) % n] = first + k * gap;
      }
    }
    return placed;
  }

  void _background(Canvas canvas) {
    // Soft outer halo.
    canvas.drawCircle(
      _center,
      _rim,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF7B8CFF).withValues(alpha: 0.28),
            const Color(0xFF7B8CFF).withValues(alpha: 0),
          ],
          stops: const [0.88, 1],
        ).createShader(Rect.fromCircle(center: _center, radius: _rim)),
    );
    // Night-sky disc.
    canvas.drawCircle(
      _center,
      _outer + 1,
      Paint()
        ..shader = const RadialGradient(
          colors: [ChartPalette.skyCenter, ChartPalette.skyEdge],
        ).createShader(Rect.fromCircle(center: _center, radius: _outer)),
    );
    // A scatter of fixed stars between the sign ring and the houses.
    final rnd = math.Random(7);
    final star = Paint()..color = Colors.white;
    for (var i = 0; i < 70; i++) {
      final th = rnd.nextDouble() * 2 * math.pi;
      final r = _houseOut + 2 + rnd.nextDouble() * (_signIn - _houseOut - 4);
      star.color = Colors.white.withValues(alpha: 0.15 + rnd.nextDouble() * 0.4);
      canvas.drawCircle(
        Offset(_c + r * math.cos(th), _c + r * math.sin(th)),
        rnd.nextDouble() * 0.9 + 0.3,
        star,
      );
    }
  }

  Path _ringSegment(
    Offset Function(double, double) p,
    double from,
    double to,
    double rIn,
    double rOut,
  ) {
    final steps = math.max(2, ((to - from) / 2).ceil());
    final path = Path()..moveTo(p(from, rOut).dx, p(from, rOut).dy);
    for (var s = 1; s <= steps; s++) {
      final pt = p(from + (to - from) * s / steps, rOut);
      path.lineTo(pt.dx, pt.dy);
    }
    for (var s = steps; s >= 0; s--) {
      final pt = p(from + (to - from) * s / steps, rIn);
      path.lineTo(pt.dx, pt.dy);
    }
    return path..close();
  }

  void _text(Canvas canvas, String text, Offset center, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.result != result || old.showAspects != showAspects;
}
