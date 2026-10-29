import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/widgets/night_sky.dart';
import '../../model/onboarding_page_model.dart';

const _fire = Color(0xFFE2734F);
const _earth = Color(0xFFD4A54E);
const _metal = Color(0xFFA8B2C0);
const _water = Color(0xFF6FA2D6);
const _wood = Color(0xFF73B684);

/// Illustration for an onboarding slide. The chart wheel turns slowly.
class OnboardingArtView extends StatefulWidget {
  const OnboardingArtView({super.key, required this.art});

  final OnboardingArt art;

  @override
  State<OnboardingArtView> createState() => _OnboardingArtViewState();
}

class _OnboardingArtViewState extends State<OnboardingArtView> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 90),
  );

  @override
  void initState() {
    super.initState();
    if (widget.art == OnboardingArt.chart) _spin.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the system "reduce motion" setting.
    if (MediaQuery.of(context).disableAnimations) _spin.stop();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painter = switch (widget.art) {
      OnboardingArt.chart => _ChartArt(_spin),
      OnboardingArt.plan => _PlanArt(),
      OnboardingArt.reading => _ReadingArt(),
    };
    return AspectRatio(
      aspectRatio: 1,
      child: ExcludeSemantics(child: CustomPaint(painter: painter)),
    );
  }
}

/// Zodiac wheel tinted by element, with planets and a glowing Sun.
class _ChartArt extends CustomPainter {
  _ChartArt(this.spin) : super(repaint: spin);

  final Animation<double> spin;

  static const _elements = [_fire, _earth, _metal, _water];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(spin.value * 2 * math.pi);

    final outer = r * 0.92;
    final inner = r * 0.74;
    for (var k = 0; k < 12; k++) {
      final a0 = k * math.pi / 6;
      final path = Path()
        ..addArc(Rect.fromCircle(center: Offset.zero, radius: outer), a0, math.pi / 6)
        ..arcTo(
          Rect.fromCircle(center: Offset.zero, radius: inner),
          a0 + math.pi / 6,
          -math.pi / 6,
          false,
        )
        ..close();
      canvas.drawPath(path, Paint()..color = _elements[k % 4].withValues(alpha: 0.22));
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = SkyColors.ring,
      );
      // Small sign marker in each segment.
      final m = Offset.fromDirection(a0 + math.pi / 12, (outer + inner) / 2);
      canvas.drawCircle(m, r * 0.022, Paint()..color = _elements[k % 4]);
    }
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = SkyColors.star.withValues(alpha: 0.25);
    canvas.drawCircle(Offset.zero, r * 0.5, ring);

    // Planets on the inner band.
    const planets = [0.3, 1.1, 1.5, 2.6, 3.4, 4.0, 5.2];
    for (final a in planets) {
      final p = Offset.fromDirection(a, r * 0.62);
      canvas.drawLine(
        Offset.fromDirection(a, inner),
        Offset.fromDirection(a, inner - r * 0.05),
        Paint()
          ..color = SkyColors.star.withValues(alpha: 0.7)
          ..strokeWidth = 1.2,
      );
      canvas.drawCircle(p, r * 0.03, Paint()..color = SkyColors.star);
    }
    // Ascendant axis.
    canvas.drawLine(
      Offset(-inner, 0),
      Offset(inner, 0),
      Paint()
        ..color = SkyColors.brass
        ..strokeWidth = 1.4,
    );
    canvas.restore();

    // Sun in the middle, not rotating.
    canvas.drawCircle(
      c,
      r * 0.2,
      Paint()
        ..shader = RadialGradient(
          colors: [SkyColors.brass.withValues(alpha: 0.55), SkyColors.brass.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.2)),
    );
    canvas.drawCircle(c, r * 0.075, Paint()..color = SkyColors.brass);
    canvas.drawCircle(c, r * 0.02, Paint()..color = SkyColors.top);
  }

  @override
  bool shouldRepaint(_ChartArt old) => false;
}

/// Floor plan with the bagua grid and a few pieces of furniture.
class _PlanArt extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final room = Rect.fromLTWH(s * 0.16, s * 0.14, s * 0.68, s * 0.72);
    const tint = [_wood, _fire, _earth, _wood, _earth, _metal, _earth, _water, _metal];
    for (var i = 0; i < 9; i++) {
      final col = i % 3;
      final row = i ~/ 3;
      final cell = Rect.fromLTWH(
        room.left + col * room.width / 3,
        room.top + row * room.height / 3,
        room.width / 3,
        room.height / 3,
      );
      canvas.drawRect(cell, Paint()..color = tint[i].withValues(alpha: 0.16));
      canvas.drawRect(
        cell,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = SkyColors.star.withValues(alpha: 0.12),
      );
    }

    // Walls with a door gap at the bottom.
    final dw = room.width * 0.24;
    final dx = room.center.dx - dw / 2;
    final wall = Path()
      ..moveTo(dx, room.bottom)
      ..lineTo(room.left, room.bottom)
      ..lineTo(room.left, room.top)
      ..lineTo(room.right, room.top)
      ..lineTo(room.right, room.bottom)
      ..lineTo(dx + dw, room.bottom);
    canvas.drawPath(
      wall,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..color = SkyColors.text,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(dx, room.bottom), radius: dw),
      -math.pi / 2,
      math.pi / 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = SkyColors.muted,
    );
    // Window on the far wall.
    canvas.drawLine(
      Offset(room.left + room.width * 0.3, room.top),
      Offset(room.right - room.width * 0.3, room.top),
      Paint()
        ..strokeWidth = 5
        ..color = _water,
    );

    final fill = Paint()..color = const Color(0xFF263044);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = SkyColors.star.withValues(alpha: 0.8);
    void piece(Rect r, {bool selected = false, bool round = false}) {
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(4));
      if (round) {
        canvas.drawOval(r, fill);
        canvas.drawOval(r, edge);
      } else {
        canvas.drawRRect(rr, fill);
        canvas.drawRRect(
          rr,
          selected
              ? (Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2.2
                  ..color = SkyColors.brass)
              : edge,
        );
        // Thick back edge.
        canvas.drawLine(
          r.topLeft + const Offset(3, 3),
          r.topRight + const Offset(-3, 3),
          Paint()
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round
            ..color = selected ? SkyColors.brass : SkyColors.star,
        );
      }
    }

    // Bed (selected) in the far-left, desk far-right, plant and rug.
    piece(
      Rect.fromLTWH(room.left + s * 0.03, room.top + s * 0.03, s * 0.2, s * 0.26),
      selected: true,
    );
    piece(Rect.fromLTWH(room.right - s * 0.2, room.top + s * 0.03, s * 0.17, s * 0.08));
    piece(
      Rect.fromLTWH(room.right - s * 0.11, room.bottom - s * 0.14, s * 0.08, s * 0.08),
      round: true,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: room.center + Offset(0, s * 0.06),
          width: s * 0.22,
          height: s * 0.16,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = SkyColors.star.withValues(alpha: 0.08),
    );
    // Resize handle on the selected bed.
    canvas.drawCircle(
      Offset(room.left + s * 0.23, room.top + s * 0.29),
      s * 0.018,
      Paint()..color = SkyColors.brass,
    );

    // North badge.
    final n = Offset(room.center.dx, room.top - s * 0.075);
    canvas.drawCircle(n, s * 0.04, Paint()..color = SkyColors.jade);
    final tp = TextPainter(
      text: TextSpan(
        text: 'N',
        style: TextStyle(color: SkyColors.top, fontSize: s * 0.045, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, n - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_PlanArt old) => false;
}

/// Compass rose with the four best directions lit up, over a reading card.
class _ReadingArt extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s * 0.42);
    final r = s * 0.3;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = SkyColors.star.withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      c,
      r * 0.62,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = SkyColors.ring,
    );

    const best = {1, 2, 4, 7}; // NE, E, S, NW lit as "your directions"
    for (var i = 0; i < 8; i++) {
      final a = -math.pi / 2 + i * math.pi / 4;
      final major = i.isEven;
      final tipLen = major ? r * 0.92 : r * 0.62;
      final tip = c + Offset.fromDirection(a, tipLen);
      final side = Offset.fromDirection(a + math.pi / 2, r * (major ? 0.09 : 0.06));
      final path = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(c.dx + side.dx, c.dy + side.dy)
        ..lineTo(c.dx - side.dx, c.dy - side.dy)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = (i == 0 ? SkyColors.brass : SkyColors.star).withValues(
            alpha: major ? 0.9 : 0.45,
          ),
      );
      final dot = c + Offset.fromDirection(a, r * 1.16);
      if (best.contains(i)) {
        canvas.drawCircle(dot, s * 0.034, Paint()..color = SkyColors.jade.withValues(alpha: 0.25));
        canvas.drawCircle(dot, s * 0.02, Paint()..color = SkyColors.jade);
      } else {
        canvas.drawCircle(dot, s * 0.008, Paint()..color = SkyColors.muted);
      }
    }
    canvas.drawCircle(c, s * 0.022, Paint()..color = SkyColors.top);
    canvas.drawCircle(
      c,
      s * 0.022,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = SkyColors.brass,
    );

    // Reading card.
    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.18, s * 0.8, s * 0.64, s * 0.17),
      const Radius.circular(12),
    );
    canvas.drawRRect(card, Paint()..color = const Color(0xFF263044));
    canvas.drawRRect(
      card,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = SkyColors.brass.withValues(alpha: 0.6),
    );
    final line = Paint()
      ..strokeWidth = s * 0.016
      ..strokeCap = StrokeCap.round
      ..color = SkyColors.star.withValues(alpha: 0.5);
    for (final (y, w) in [(0.85, 0.44), (0.89, 0.52), (0.93, 0.3)]) {
      canvas.drawLine(Offset(s * 0.24, s * y), Offset(s * (0.24 + w), s * y), line);
    }
    // Sparkle.
    final sp = Offset(s * 0.78, s * 0.8);
    final spark = Path()
      ..moveTo(sp.dx, sp.dy - s * 0.04)
      ..quadraticBezierTo(sp.dx, sp.dy, sp.dx + s * 0.04, sp.dy)
      ..quadraticBezierTo(sp.dx, sp.dy, sp.dx, sp.dy + s * 0.04)
      ..quadraticBezierTo(sp.dx, sp.dy, sp.dx - s * 0.04, sp.dy)
      ..quadraticBezierTo(sp.dx, sp.dy, sp.dx, sp.dy - s * 0.04);
    canvas.drawPath(spark, Paint()..color = SkyColors.brass);
  }

  @override
  bool shouldRepaint(_ReadingArt old) => false;
}
