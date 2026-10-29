import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Astro Home mark: a house inside two orbit rings with a star on top.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 52, this.onDark = false});

  final double size;

  /// Light strokes for night-sky backgrounds, whatever the app theme.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = onDark ? AppColors.dark : context.colors;
    return CustomPaint(size: Size.square(size), painter: _BrandMarkPainter(c));
  }
}

/// Mark plus the "Astro Home" wordmark.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 44, this.tagline, this.onDark = false});

  final double size;
  final String? tagline;

  /// Light text and strokes for night-sky backgrounds.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = onDark ? AppColors.dark : context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: size * 1.2, onDark: onDark),
        const SizedBox(width: 14),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Astro ', style: AppTextStyles.display(size, c.ink)),
                    TextSpan(
                      text: 'Home',
                      style: AppTextStyles.display(size, c.brass, italic: true),
                    ),
                  ],
                ),
              ),
              if (tagline != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(tagline!, style: TextStyle(color: c.muted, fontSize: 14)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  _BrandMarkPainter(this.c);

  final AppColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 52;
    canvas.scale(s);
    final stroke = Paint()..style = PaintingStyle.stroke;
    canvas.drawCircle(
      const Offset(26, 26),
      24,
      stroke
        ..color = c.brass
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      const Offset(26, 26),
      17,
      stroke
        ..color = c.line
        ..strokeWidth = 1,
    );
    final house = Path()
      ..moveTo(15, 29)
      ..lineTo(26, 18)
      ..lineTo(37, 29)
      ..lineTo(37, 37)
      ..lineTo(15, 37)
      ..close();
    canvas.drawPath(
      house,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 1.6
        ..color = c.ink,
    );
    final fill = Paint()..color = c.brass;
    canvas.drawCircle(const Offset(26, 30), 2.4, fill);
    canvas.drawCircle(const Offset(26, 2), 2, fill);
  }

  @override
  bool shouldRepaint(_BrandMarkPainter old) => old.c != c;
}
