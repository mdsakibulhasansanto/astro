import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/furniture_catalog.dart';
import '../../model/furniture_model.dart';
import 'room_canvas.dart' show furnitureColor;

/// Paints a realistic top-down view of [item] filling [size]. Pieces are
/// drawn with their back towards the wall given by the item's rotation.
/// [pixelsPerFoot] keeps details (pillows, cushions) at a natural size.
void paintFurniture(Canvas canvas, Size size, FurnitureModel item, {double pixelsPerFoot = 30}) {
  final custom = furnitureColor(item);
  final rect = Offset.zero & size;

  // Soft shadow under every piece except rugs.
  if (item.type != FurnitureType.rug) {
    final shadow = Paint()
      ..color = const Color(0x47000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    if (item.type.shape == FurnitureShape.circle) {
      canvas.drawOval(rect.shift(const Offset(1.5, 2.5)), shadow);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.shift(const Offset(1.5, 2.5)), const Radius.circular(3)),
        shadow,
      );
    }
  }

  // Turn the canvas so the back of the piece is at the top.
  final quarter = item.backWall.index; // top, right, bottom, left
  final sideways = quarter.isOdd;
  final lw = sideways ? size.height : size.width;
  final lh = sideways ? size.width : size.height;
  canvas.save();
  canvas.translate(size.width / 2, size.height / 2);
  canvas.rotate(quarter * math.pi / 2);
  canvas.translate(-lw / 2, -lh / 2);
  final art = _Art(canvas, Size(lw, lh), pixelsPerFoot.clamp(4, 400).toDouble());
  switch (item.type) {
    case FurnitureType.bed:
      art.bed(custom);
    case FurnitureType.sofa:
      art.sofa(custom);
    case FurnitureType.chair:
      art.armchair(custom);
    case FurnitureType.table:
      art.table(custom);
    case FurnitureType.desk:
      art.desk(custom);
    case FurnitureType.wardrobe:
      art.wardrobe(custom);
    case FurnitureType.tv:
      art.tv(custom);
    case FurnitureType.storage:
      art.cabinet(custom);
    case FurnitureType.bookshelf:
      art.bookshelf(custom);
    case FurnitureType.rug:
      art.rug(custom);
    case FurnitureType.mirror:
      art.mirror(custom);
    case FurnitureType.plant:
      art.plant(custom);
    case FurnitureType.lamp:
      art.lamp(custom);
  }
  canvas.restore();
}

class _Art {
  _Art(this.c, this.s, this.ft);

  final Canvas c;
  final Size s;

  /// Pixels per foot.
  final double ft;

  static const _charcoal = Color(0xFF2A2B30);
  static const _linen = Color(0xFFF7F6F2);
  static const _wood = Color(0xFF9B6B3F);

  double get w => s.width;
  double get h => s.height;
  Rect get all => Offset.zero & s;

  Paint fill(Color color) => Paint()..color = color;
  Paint line(Color color, [double width = 1]) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = color;

  RRect rr(Rect r, double radius) => RRect.fromRectAndRadius(r, Radius.circular(radius));

  /// A rounded block with a gentle top-left highlight.
  void block(Rect r, Color color, double radius, {double edge = 0.25}) {
    c.drawRRect(rr(r, radius), fill(color));
    c.drawRRect(
      rr(r, radius),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: 0.18), Colors.black.withValues(alpha: 0.12)],
        ).createShader(r),
    );
    c.drawRRect(rr(r, radius), line(Color.lerp(color, Colors.black, edge)!, 0.8));
  }

  /// A soft cushion or pillow.
  void cushion(Rect r, Color color) {
    final radius = math.min(r.width, r.height) * 0.3;
    c.drawRRect(
      rr(r.shift(const Offset(0, 1)), radius),
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    c.drawRRect(
      rr(r, radius),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 0.9,
          colors: [Color.lerp(color, Colors.white, 0.25)!, Color.lerp(color, Colors.black, 0.12)!],
        ).createShader(r),
    );
    c.drawRRect(rr(r, radius), line(Color.lerp(color, Colors.black, 0.25)!, 0.6));
  }

  void bed(Color? custom) {
    final frame = custom ?? _charcoal;
    final head = math.min(h * 0.11, 0.6 * ft);
    // Small feet at the end of the frame.
    for (final x in [w * 0.03, w * 0.97 - 4]) {
      c.drawRect(Rect.fromLTWH(x, h - 3, 4, 3), fill(frame));
    }
    // White mattress with rounded foot.
    final body = Rect.fromLTRB(w * 0.01, head * 0.6, w * 0.99, h - 2);
    final foot = RRect.fromRectAndCorners(
      body,
      bottomLeft: const Radius.circular(6),
      bottomRight: const Radius.circular(6),
    );
    c.drawRRect(foot, fill(_linen));
    // Padded headboard in two panels.
    block(Rect.fromLTWH(0, 0, w, head), frame, 2, edge: 0.4);
    for (var i = 0; i < 2; i++) {
      final panel = Rect.fromLTWH(w * 0.04 + i * w * 0.47, head * 0.18, w * 0.45, head * 0.62);
      c.drawRRect(rr(panel, 2), fill(Color.lerp(frame, Colors.white, 0.06)!));
      c.drawRRect(rr(panel, 2), line(Colors.black.withValues(alpha: 0.5), 0.8));
    }
    // Pillows.
    final ph = math.min(body.height * 0.2, 1.4 * ft);
    final gap = body.width * 0.07;
    final pw = (body.width - gap * 3) / 2;
    for (var i = 0; i < 2; i++) {
      cushion(
        Rect.fromLTWH(body.left + gap + i * (pw + gap), head + body.height * 0.02, pw, ph),
        Colors.white,
      );
    }
    // Duvet with a folded band over the top.
    final duvetTop = head + body.height * 0.02 + ph + body.height * 0.02;
    final duvet = Rect.fromLTRB(body.left - 1, duvetTop, body.right + 1, body.bottom);
    c.drawRRect(
      RRect.fromRectAndCorners(
        duvet,
        bottomLeft: const Radius.circular(6),
        bottomRight: const Radius.circular(6),
      ),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFEDEEF0)],
        ).createShader(duvet),
    );
    final fold = Rect.fromLTRB(duvet.left, duvet.top, duvet.right, duvet.top + duvet.height * 0.16);
    c.drawRRect(rr(fold, 3), fill(const Color(0xFFF4F4F5)));
    c.drawLine(fold.bottomLeft, fold.bottomRight, line(const Color(0x2A000000), 1));
    c.drawLine(fold.topLeft, fold.topRight, line(const Color(0x1A000000), 0.8));
    // Rolled edge at the foot.
    c.drawLine(
      Offset(duvet.left + 4, duvet.bottom - 4),
      Offset(duvet.right - 4, duvet.bottom - 4),
      line(const Color(0x1F000000), 1.2),
    );
    c.drawRRect(foot, line(const Color(0x55000000), 0.8));
  }

  void sofa(Color? custom) {
    final body = custom ?? _charcoal;
    block(all, body, math.min(w, h) * 0.12);
    final back = h * 0.26;
    final arm = math.min(w * 0.12, h * 0.32);
    final seat = Rect.fromLTRB(arm, back, w - arm, h - h * 0.06);
    final n = math.max(1, (seat.width / (2.6 * ft)).round().clamp(1, 4));
    final cw = seat.width / n;
    final light = Color.lerp(body, Colors.white, 0.12)!;
    for (var i = 0; i < n; i++) {
      cushion(Rect.fromLTWH(seat.left + i * cw + 1, seat.top + 1, cw - 2, seat.height - 2), light);
    }
    // Back cushions.
    for (var i = 0; i < n; i++) {
      cushion(
        Rect.fromLTWH(seat.left + i * cw + 1, h * 0.05, cw - 2, back - h * 0.06),
        Color.lerp(body, Colors.white, 0.06)!,
      );
    }
    // A throw pillow.
    final tp = math.min(seat.height * 0.5, 1.1 * ft);
    cushion(
      Rect.fromLTWH(seat.left + cw * 0.2, seat.top + seat.height * 0.1, tp, tp * 0.9),
      Color.lerp(body, Colors.black, 0.3)!,
    );
  }

  void armchair(Color? custom) {
    final body = custom ?? const Color(0xFFF3F1EC);
    block(all, body, math.min(w, h) * 0.18, edge: 0.18);
    final back = h * 0.25;
    final arm = w * 0.17;
    cushion(Rect.fromLTRB(arm, back, w - arm, h - h * 0.08), Color.lerp(body, Colors.white, 0.3)!);
    cushion(Rect.fromLTRB(arm * 0.6, h * 0.05, w - arm * 0.6, back), body);
  }

  void table(Color? custom) {
    final top = custom ?? const Color(0xFFB98552);
    block(all, top, math.min(w, h) * 0.08);
    _woodGrain(all.deflate(2), top);
    // A small vase in the middle.
    final r = math.min(w, h) * 0.12;
    c.drawCircle(all.center, r, fill(const Color(0xFFEDEBE6)));
    _leaves(all.center, r * 1.3, 6);
  }

  void desk(Color? custom) {
    final top = custom ?? _charcoal;
    block(all, top, 2);
    // Laptop.
    final lw = math.min(w * 0.38, 1.2 * ft);
    final lh = math.min(h * 0.42, 0.8 * ft);
    final laptop = Rect.fromCenter(center: Offset(w / 2, h * 0.38), width: lw, height: lh);
    c.drawRRect(rr(laptop, 2), fill(const Color(0xFFC9CDD2)));
    c.drawRRect(rr(laptop.deflate(lw * 0.08), 1.5), fill(const Color(0xFF8E959D)));
    // Lamp in the corner.
    final r = math.min(w, h) * 0.12;
    c.drawCircle(Offset(w - r * 1.6, r * 1.6), r, fill(const Color(0xFFF6EFD9)));
    c.drawCircle(Offset(w - r * 1.6, r * 1.6), r * 0.35, fill(const Color(0xFF3A3A40)));
    // Chair tucked in at the front.
    final cw = math.min(w * 0.3, 1.6 * ft);
    final chair = Rect.fromCenter(center: Offset(w / 2, h * 0.92), width: cw, height: h * 0.28);
    cushion(chair, const Color(0xFF3B3D44));
  }

  void wardrobe(Color? custom) {
    final body = custom ?? const Color(0xFF7C5634);
    block(all, body, 2);
    _woodGrain(all.deflate(2), body);
    final doors = math.max(2, (w / (1.6 * ft)).round());
    final dw = w / doors;
    final edge = line(Color.lerp(body, Colors.black, 0.35)!, 1);
    for (var i = 1; i < doors; i++) {
      c.drawLine(Offset(i * dw, 2), Offset(i * dw, h - 2), edge);
    }
    // Front edge and handles.
    c.drawLine(Offset(0, h - 2), Offset(w, h - 2), line(Colors.black.withValues(alpha: 0.3), 2));
    for (var i = 0; i < doors; i++) {
      c.drawCircle(Offset(i * dw + dw / 2, h * 0.82), 1.6, fill(const Color(0xFFE5D3A8)));
    }
  }

  void tv(Color? custom) {
    final body = custom ?? const Color(0xFF16171B);
    final stand = Rect.fromLTRB(w * 0.32, h * 0.25, w * 0.68, h);
    c.drawRRect(rr(stand, 2), fill(const Color(0xFF3B3D44)));
    final screen = Rect.fromLTWH(0, 0, w, h * 0.45);
    block(screen, body, 2, edge: 0);
    c.drawLine(
      screen.bottomLeft + const Offset(2, -1),
      screen.bottomRight + const Offset(-2, -1),
      line(const Color(0x5591A7C9), 1),
    );
  }

  /// Nightstand / storage unit: dark cube with a round drawer top.
  void cabinet(Color? custom) {
    final body = custom ?? _charcoal;
    block(all, body, 3);
    final inner = all.deflate(math.min(w, h) * 0.1);
    c.drawRRect(rr(inner, 2), line(Colors.white.withValues(alpha: 0.12), 1));
    final r = math.min(w, h) * 0.3;
    if (w < h * 1.6) {
      c.drawCircle(all.center, r, line(const Color(0xFF0E0E10), math.max(1.5, r * 0.18)));
      c.drawCircle(all.center, r * 0.75, fill(Color.lerp(body, Colors.black, 0.25)!));
    } else {
      final n = (w / (1.5 * ft)).round().clamp(2, 6);
      for (var i = 1; i < n; i++) {
        c.drawLine(
          Offset(w * i / n, inner.top),
          Offset(w * i / n, inner.bottom),
          line(Colors.black.withValues(alpha: 0.35)),
        );
      }
    }
  }

  void bookshelf(Color? custom) {
    final body = custom ?? _wood;
    block(all, body, 2);
    final inner = Rect.fromLTRB(2, 2, w - 2, h * 0.75);
    c.drawRect(inner, fill(Color.lerp(body, Colors.black, 0.45)!));
    const spines = [
      Color(0xFFB4483C),
      Color(0xFF2F5D8A),
      Color(0xFFE0B04A),
      Color(0xFF3E7B58),
      Color(0xFFEEE7D9),
      Color(0xFF6B4E9B),
    ];
    final rnd = math.Random(w.round() * 31 + h.round());
    var x = inner.left + 1;
    while (x < inner.right - 2) {
      final bw = math.max(2.0, ft * (0.12 + rnd.nextDouble() * 0.12));
      final depth = inner.height * (0.65 + rnd.nextDouble() * 0.33);
      c.drawRect(
        Rect.fromLTWH(x, inner.top, math.min(bw, inner.right - x - 1), depth),
        fill(spines[rnd.nextInt(spines.length)]),
      );
      x += bw + 0.6;
    }
  }

  void rug(Color? custom) {
    final base = custom ?? const Color(0xFFC9A98A);
    final r = rr(all, 3);
    c.drawRRect(r, fill(base.withValues(alpha: 0.92)));
    final border = all.deflate(math.min(w, h) * 0.07);
    c.drawRRect(rr(border, 2), line(Color.lerp(base, Colors.black, 0.3)!, 2));
    c.drawRRect(rr(border.deflate(4), 2), line(Colors.white.withValues(alpha: 0.5), 1));
    // Diamond pattern.
    final mid = border.deflate(8);
    if (mid.width > 10 && mid.height > 10) {
      final p = Path()
        ..moveTo(mid.center.dx, mid.top)
        ..lineTo(mid.right, mid.center.dy)
        ..lineTo(mid.center.dx, mid.bottom)
        ..lineTo(mid.left, mid.center.dy)
        ..close();
      c.drawPath(p, fill(Color.lerp(base, Colors.black, 0.12)!));
      c.drawPath(p, line(Colors.white.withValues(alpha: 0.45), 1));
    }
    // Fringe on the short ends.
    final fringe = line(Color.lerp(base, Colors.white, 0.4)!, 0.8);
    for (var x = 2.0; x < w - 1; x += 3) {
      c.drawLine(Offset(x, 0), Offset(x, -3), fringe);
      c.drawLine(Offset(x, h), Offset(x, h + 3), fringe);
    }
  }

  void mirror(Color? custom) {
    final frame = custom ?? const Color(0xFFB08D57);
    block(all, frame, 2);
    final glass = all.deflate(math.min(w, h) * 0.25);
    c.drawRect(
      glass,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFE8F1F6), Color(0xFFA9BCC8), Color(0xFFE8F1F6)],
        ).createShader(glass),
    );
  }

  void plant(Color? custom) {
    final r = math.min(w, h) / 2;
    final centre = all.center;
    c.drawCircle(centre, r * 0.55, fill(custom ?? const Color(0xFFDCD8D0)));
    c.drawCircle(centre, r * 0.55, line(const Color(0xFF9C968B), 1));
    c.drawCircle(centre, r * 0.45, fill(const Color(0xFF5A4532)));
    _leaves(centre, r, 9);
  }

  void lamp(Color? custom) {
    final r = math.min(w, h) / 2;
    final centre = all.center;
    c.drawCircle(
      centre,
      r * 1.25,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0x66FFE7A3), const Color(0x00FFE7A3)],
        ).createShader(Rect.fromCircle(center: centre, radius: r * 1.25)),
    );
    c.drawCircle(centre, r * 0.92, fill(custom ?? const Color(0xFFF7EFD8)));
    c.drawCircle(centre, r * 0.92, line(const Color(0xFFC9B98F), 1));
    c.drawCircle(centre, r * 0.6, line(const Color(0x33A08850), 1));
    c.drawCircle(centre, r * 0.18, fill(const Color(0xFF3A3A40)));
  }

  /// Radiating leaves for plants and vases.
  void _leaves(Offset centre, double r, int count) {
    const greens = [Color(0xFF2F8F3A), Color(0xFF43A84A), Color(0xFF5CBF52), Color(0xFF267A33)];
    for (var i = 0; i < count; i++) {
      final a = i * 2 * math.pi / count + (i.isOdd ? 0.3 : 0);
      final len = r * (i.isOdd ? 0.8 : 1.0);
      c.save();
      c.translate(centre.dx, centre.dy);
      c.rotate(a);
      final leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(len * 0.5, -len * 0.28, len, 0)
        ..quadraticBezierTo(len * 0.5, len * 0.28, 0, 0)
        ..close();
      c.drawPath(leaf, fill(greens[i % greens.length]));
      c.drawLine(Offset.zero, Offset(len * 0.9, 0), line(const Color(0x55FFFFFF), 0.6));
      c.restore();
    }
  }

  void _woodGrain(Rect r, Color base) {
    final grain = line(Color.lerp(base, Colors.black, 0.2)!.withValues(alpha: 0.35), 0.6);
    final rnd = math.Random(r.width.round() * 7 + r.height.round());
    final vertical = r.height > r.width;
    for (var i = 0; i < 6; i++) {
      final f = 0.1 + rnd.nextDouble() * 0.8;
      if (vertical) {
        final x = r.left + r.width * f;
        c.drawLine(Offset(x, r.top + 2), Offset(x + 1, r.bottom - 2), grain);
      } else {
        final y = r.top + r.height * f;
        c.drawLine(Offset(r.left + 2, y), Offset(r.right - 2, y + 1), grain);
      }
    }
  }
}
