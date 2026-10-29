import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/feng_shui_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/compass_heading.dart';

/// Live phone compass. Returns the 8-way direction the phone points to.
Future<Compass?> showCompassDialog(BuildContext context) {
  return showDialog<Compass>(context: context, builder: (_) => const _CompassDialog());
}

class _CompassDialog extends StatefulWidget {
  const _CompassDialog();

  @override
  State<_CompassDialog> createState() => _CompassDialogState();
}

class _CompassDialogState extends State<_CompassDialog> {
  late final Stream<double> _headings = compassHeadings();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AlertDialog(
      title: const Text('Use phone compass'),
      content: StreamBuilder<double>(
        stream: _headings,
        builder: (context, snap) {
          if (snap.hasError) {
            return const Text('This phone has no compass sensor. Choose the direction by hand.');
          }
          final h = snap.data;
          final dir = h == null ? null : Compass.fromAngle(h);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Stand in the doorway facing into the room. Hold the phone flat with its top '
                'pointing the way you face.',
                style: TextStyle(color: c.muted, fontSize: 13.5),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: 150,
                height: 150,
                child: h == null
                    ? const Center(child: CircularProgressIndicator())
                    : Transform.rotate(
                        angle: -h * math.pi / 180,
                        child: CustomPaint(painter: _RosePainter(c)),
                      ),
              ),
              const SizedBox(height: 14),
              if (h != null) ...[
                Text(dir!.label, style: AppTextStyles.display(26, c.ink)),
                Text('${h.round()}° magnetic', style: AppTextStyles.mono(13, c.muted)),
              ],
              const SizedBox(height: 8),
              Text(
                'Keep away from metal and electronics for an accurate reading.',
                style: TextStyle(color: c.muted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        StreamBuilder<double>(
          stream: _headings,
          builder: (context, snap) => FilledButton(
            onPressed: snap.data == null
                ? null
                : () => Navigator.of(context).pop(Compass.fromAngle(snap.data!)),
            child: Text(snap.data == null ? 'Use' : 'Use ${Compass.fromAngle(snap.data!).code}'),
          ),
        ),
      ],
    );
  }
}

class _RosePainter extends CustomPainter {
  _RosePainter(this.c);

  final AppColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(center, r, Paint()..color = c.surface);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = c.line,
    );
    for (final d in Compass.values) {
      final a = d.angle * math.pi / 180 - math.pi / 2;
      final major = d.code.length == 1;
      final tp = TextPainter(
        text: TextSpan(
          text: d.code,
          style: TextStyle(
            fontSize: major ? 14 : 10,
            fontWeight: major ? FontWeight.w700 : FontWeight.w500,
            color: d == Compass.n ? c.fire : c.muted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = center + Offset(math.cos(a), math.sin(a)) * (r - 16);
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
    // Needle: always points north on the rotating rose.
    final needle = Path()
      ..moveTo(center.dx, center.dy - r * 0.55)
      ..lineTo(center.dx - 8, center.dy)
      ..lineTo(center.dx + 8, center.dy)
      ..close();
    canvas.drawPath(needle, Paint()..color = c.fire);
    canvas.drawCircle(center, 5, Paint()..color = c.ink);
  }

  @override
  bool shouldRepaint(_RosePainter old) => old.c != c;
}
