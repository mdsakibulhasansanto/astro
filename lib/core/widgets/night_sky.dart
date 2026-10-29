import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fixed palette for the night-sky surfaces (splash, onboarding, auth
/// header). They stay dark in both light and dark mode, like a real sky.
class SkyColors {
  const SkyColors._();

  static const top = Color(0xFF0B1019);
  static const bottom = Color(0xFF1B2232);
  static const star = Color(0xFFE9E4D4);
  static const brass = Color(0xFFD4A54E);
  static const jade = Color(0xFF5FB59B);
  static const text = Color(0xFFF2EFE6);
  static const muted = Color(0xFFA9B0BD);
  static const ring = Color(0x33D4A54E);
}

/// Deep gradient with a deterministic star field and faint orbit rings.
class NightSky extends StatelessWidget {
  const NightSky({super.key, this.child, this.orbitCenter = const Alignment(0, -0.35)});

  final Widget? child;

  /// Where the orbit rings are centred (Alignment coordinates).
  final Alignment orbitCenter;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SkyColors.top, SkyColors.bottom],
        ),
      ),
      child: CustomPaint(painter: _SkyPainter(orbitCenter), child: child),
    );
  }
}

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.orbitCenter);

  final Alignment orbitCenter;

  @override
  void paint(Canvas canvas, Size size) {
    // Same seed every time, so stars do not jump between frames.
    final rnd = math.Random(7);
    final star = Paint();
    final count = (size.width * size.height / 2600).clamp(40, 220).round();
    for (var i = 0; i < count; i++) {
      final p = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      final r = rnd.nextDouble() < 0.12 ? 1.4 : 0.7 + rnd.nextDouble() * 0.5;
      final a = 0.25 + rnd.nextDouble() * 0.6;
      star.color = (i % 9 == 0 ? SkyColors.brass : SkyColors.star).withValues(alpha: a);
      canvas.drawCircle(p, r, star);
    }

    final c = orbitCenter.alongSize(size);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = SkyColors.ring;
    final base = math.min(size.width, size.height);
    for (final f in [0.42, 0.62, 0.86]) {
      canvas.drawCircle(c, base * f, ring);
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.orbitCenter != orbitCenter;
}
