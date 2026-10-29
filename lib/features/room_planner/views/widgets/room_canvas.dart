import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/feng_shui_constants.dart';
import '../../../../core/constants/furniture_catalog.dart';
import '../../../../core/theme/app_colors.dart';
import '../../model/furniture_model.dart';
import '../../model/room_model.dart';
import 'furniture_art.dart';
import 'furniture_images.dart';

/// Top-down floor plan: wooden floor, thick walls, door with its swing,
/// windows, a light bagua overlay, compass directions and draggable
/// furniture drawn as realistic pieces. Fits whatever space it is given.
class RoomCanvas extends StatelessWidget {
  const RoomCanvas({
    super.key,
    required this.room,
    required this.items,
    this.selectedKey,
    this.highlightDirections = const [],
    this.showBagua = false,
    this.onSelect,
    this.onMove,
    this.onResize,
    this.onGestureStart,
    this.overlapping = const {},
  });

  final RoomModel room;
  final List<FurnitureModel> items;
  final String? selectedKey;

  /// Directions drawn as jade badges (the user's Kua directions).
  final List<Compass> highlightDirections;

  /// Tints the floor with the nine bagua zones and their names.
  final bool showBagua;
  final ValueChanged<String?>? onSelect;
  final void Function(String key, double dx, double dy)? onMove;
  final void Function(String key, double dw, double dh)? onResize;

  /// Called once when a drag or resize begins (used to record undo history).
  final ValueChanged<String>? onGestureStart;

  /// Keys of pieces drawn with a warning outline because they collide.
  final Set<String> overlapping;

  bool get _interactive => onMove != null;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, cons) {
        final w = room.width;
        final d = room.height;
        final pad = math.max(w, d) * 0.13;
        final maxW = cons.maxWidth;
        final maxH = cons.hasBoundedHeight ? cons.maxHeight : maxW * 1.4;
        final scale = math.min(maxW / (w + 2 * pad), maxH / (d + 2 * pad));
        final off = pad * scale;
        final roomW = w * scale;
        final roomH = d * scale;

        // Rugs sit under everything else; the selected piece sits on top.
        int layer(FurnitureModel i) =>
            i.type == FurnitureType.rug ? 0 : (i.localKey == selectedKey ? 2 : 1);
        final ordered = [...items]..sort((a, b) => layer(a).compareTo(layer(b)));
        final selected = ordered.where((i) => i.localKey == selectedKey).firstOrNull;

        return Center(
          child: SizedBox(
            width: (w + 2 * pad) * scale,
            height: (d + 2 * pad) * scale,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onSelect == null ? null : () => onSelect!(null),
                    child: CustomPaint(
                      painter: _RoomPainter(
                        room: room,
                        colors: c,
                        pad: pad,
                        scale: scale,
                        highlight: highlightDirections,
                        showBagua: showBagua,
                      ),
                    ),
                  ),
                ),
                for (final item in ordered)
                  Positioned(
                    key: ValueKey(item.localKey),
                    left: off + item.x * roomW,
                    top: off + item.y * roomH,
                    width: math.max(item.width * roomW, 6),
                    height: math.max(item.height * roomH, 6),
                    child: Semantics(
                      label: item.label,
                      selected: item.localKey == selectedKey,
                      button: _interactive,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onSelect == null ? null : () => onSelect!(item.localKey),
                        onPanStart: _interactive
                            ? (_) {
                                onSelect?.call(item.localKey);
                                onGestureStart?.call(item.localKey);
                              }
                            : null,
                        onPanUpdate: _interactive
                            ? (e) => onMove!(item.localKey, e.delta.dx / roomW, e.delta.dy / roomH)
                            : null,
                        child: _FurnitureBox(
                          item: item,
                          selected: item.localKey == selectedKey,
                          colliding: overlapping.contains(item.localKey),
                          colors: c,
                          pixelsPerFoot: scale / room.unit.perFoot,
                        ),
                      ),
                    ),
                  ),
                if (selected != null && onResize != null)
                  Positioned(
                    left: off + (selected.x + selected.width) * roomW - 16,
                    top: off + (selected.y + selected.height) * roomH - 16,
                    width: 32,
                    height: 32,
                    child: Semantics(
                      label: 'Resize ${selected.label}',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (_) => onGestureStart?.call(selected.localKey),
                        onPanUpdate: (e) =>
                            onResize!(selected.localKey, e.delta.dx / roomW, e.delta.dy / roomH),
                        child: Center(
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: c.brass,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 4)],
                            ),
                            child: const Icon(Icons.open_in_full, size: 9, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FurnitureBox extends StatelessWidget {
  const _FurnitureBox({
    required this.item,
    required this.selected,
    required this.colliding,
    required this.colors,
    required this.pixelsPerFoot,
  });

  final FurnitureModel item;
  final bool selected;
  final bool colliding;
  final AppColors colors;
  final double pixelsPerFoot;

  @override
  Widget build(BuildContext context) {
    final photo = FurnitureImages.has(item.type);
    final painter = _FurniturePainter(
      item: item,
      selected: selected,
      colliding: colliding,
      colors: colors,
      pixelsPerFoot: pixelsPerFoot,
      drawArt: !photo,
    );
    if (photo) {
      // Real top-down picture, turned so its back faces the right wall.
      return Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: item.type == FurnitureType.rug
                  ? null
                  : const [
                      BoxShadow(color: Color(0x40000000), blurRadius: 5, offset: Offset(1, 3)),
                    ],
            ),
            child: RotatedBox(
              quarterTurns: item.backWall.index,
              child: Image.asset(
                FurnitureImages.pathFor(item.type),
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          CustomPaint(foregroundPainter: painter, child: _label()),
        ],
      );
    }
    return CustomPaint(painter: painter, child: _label());
  }

  // The name shows on the selected piece only, so the plan stays clean.
  Widget? _label() {
    return selected
        ? LayoutBuilder(
            builder: (context, cons) {
              if (math.min(cons.maxWidth, cons.maxHeight) < 18) return const SizedBox.shrink();
              return Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xE61B2232),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          )
        : null;
  }
}

class _FurniturePainter extends CustomPainter {
  _FurniturePainter({
    required this.item,
    required this.selected,
    required this.colliding,
    required this.colors,
    required this.pixelsPerFoot,
    this.drawArt = true,
  });

  final FurnitureModel item;
  final bool selected;
  final bool colliding;
  final AppColors colors;
  final double pixelsPerFoot;

  /// False when a photo is shown instead; then only the outline is drawn.
  final bool drawArt;

  @override
  void paint(Canvas canvas, Size size) {
    if (drawArt) paintFurniture(canvas, size, item, pixelsPerFoot: pixelsPerFoot);

    if (selected || colliding) {
      final rect = (Offset.zero & size).inflate(3);
      final r = item.type.shape == FurnitureShape.circle
          ? RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide / 2))
          : RRect.fromRectAndRadius(rect, const Radius.circular(5));
      canvas.drawRRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = colliding ? colors.fire : colors.brass,
      );
    }
  }

  @override
  bool shouldRepaint(_FurniturePainter old) =>
      old.item != item ||
      old.selected != selected ||
      old.colliding != colliding ||
      old.colors != colors ||
      old.pixelsPerFoot != pixelsPerFoot ||
      old.drawArt != drawArt;
}

class _RoomPainter extends CustomPainter {
  _RoomPainter({
    required this.room,
    required this.colors,
    required this.pad,
    required this.scale,
    required this.highlight,
    required this.showBagua,
  });

  final RoomModel room;
  final AppColors colors;
  final double pad;
  final double scale;
  final List<Compass> highlight;
  final bool showBagua;

  static const _wallColor = Color(0xFF26262B);
  static const _wallTop = Color(0xFF3A3A41);

  @override
  void paint(Canvas canvas, Size size) {
    final w = room.width;
    final d = room.height;
    final mapper = room.mapper;
    final foot = room.unit.perFoot;
    // Draw in room units from here on.
    canvas.translate(pad * scale, pad * scale);
    canvas.scale(scale);
    double px(double v) => v / scale;
    const fs = 11.5; // pixels; text is drawn unscaled
    final t = math.max(0.45 * foot, math.max(w, d) * 0.035); // wall thickness

    // Drop shadow under the whole room.
    canvas.drawRect(
      Rect.fromLTWH(-t, -t, w + 2 * t, d + 2 * t).shift(Offset(0, px(4))),
      Paint()
        ..color = const Color(0x40000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, px(8)),
    );

    _floor(canvas, w, d, foot, px);

    // Bagua zones as a light tint over the floor.
    if (showBagua) {
      for (var row = 0; row < 3; row++) {
        for (var col = 0; col < 3; col++) {
          final zone = mapper.zoneForCell(room.baguaMethod, col, row);
          final color = colors.forFengShuiElement(zone.element);
          final cell = Rect.fromLTWH(col * w / 3, row * d / 3, w / 3, d / 3);
          canvas.drawRect(cell, Paint()..color = color.withValues(alpha: 0.13));
          canvas.drawRect(
            cell,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = px(1)
              ..color = Colors.white.withValues(alpha: 0.35),
          );
          _pill(canvas, zone.label, cell.topLeft + Offset(px(4), px(4)), color, w / 3 - px(8));
        }
      }
    }

    // Door opening in the bottom wall.
    final dw = math.min(3 * foot, w * 0.32);
    final dx = switch (room.doorPosition) {
      DoorPosition.left => w * 0.08,
      DoorPosition.center => (w - dw) / 2,
      DoorPosition.right => w * 0.92 - dw,
    };

    // Walls: one thick band outside the floor, with the door gap.
    final outer = Rect.fromLTWH(-t, -t, w + 2 * t, d + 2 * t);
    final walls = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(outer)
      ..addRect(Rect.fromLTWH(0, 0, w, d))
      ..addRect(Rect.fromLTWH(dx, d - px(0.5), dw, t + px(1)));
    canvas.drawPath(walls, Paint()..color = _wallColor);
    canvas.drawPath(
      walls,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = px(1.2)
        ..color = _wallTop,
    );

    // Windows: light frames set into the wall, split into panes.
    void window(Offset a, Offset b, bool vertical) {
      final rect = vertical
          ? Rect.fromLTRB(a.dx - t, a.dy, a.dx, b.dy)
          : Rect.fromLTRB(a.dx, a.dy - t, b.dx, a.dy);
      final r = vertical ? rect.shift(Offset(a.dx == 0 ? 0 : t, 0)) : rect;
      canvas.drawRect(r, Paint()..color = const Color(0xFFF2F4F5));
      final glass = Paint()
        ..color = const Color(0xFFB9D8EA)
        ..strokeWidth = px(1.4);
      final edge = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = px(1)
        ..color = const Color(0xFF8E979E);
      canvas.drawRect(r, edge);
      if (vertical) {
        canvas.drawLine(r.topCenter, r.bottomCenter, glass);
      } else {
        canvas.drawLine(r.centerLeft, r.centerRight, glass);
      }
      const panes = 3;
      for (var k = 1; k < panes; k++) {
        if (vertical) {
          final y = r.top + r.height * k / panes;
          canvas.drawRect(Rect.fromLTRB(r.left, y - px(2), r.right, y + px(2)), edge);
        } else {
          final x = r.left + r.width * k / panes;
          canvas.drawRect(Rect.fromLTRB(x - px(2), r.top, x + px(2), r.bottom), edge);
        }
      }
    }

    switch (room.windowPosition) {
      case WindowPosition.top:
        window(Offset(w * .25, 0), Offset(w * .75, 0), false);
      case WindowPosition.left:
        window(Offset(0, d * .25), Offset(0, d * .75), true);
      case WindowPosition.right:
        window(Offset(w, d * .25), Offset(w, d * .75), true);
      case WindowPosition.none:
        break;
    }

    // Door: threshold, swing area, arc and the open leaf.
    canvas.drawRect(Rect.fromLTWH(dx, d, dw, t), Paint()..color = const Color(0xFFF2F4F5));
    final hinge = Offset(dx, d);
    final swing = Path()
      ..moveTo(hinge.dx, hinge.dy)
      ..arcTo(Rect.fromCircle(center: hinge, radius: dw), 0, -math.pi / 2, false)
      ..close();
    // The swing is drawn as the wooden door leaf seen from above.
    canvas.drawPath(swing, Paint()..color = const Color(0xFFEDD2A8));
    final grainDoor = Paint()
      ..strokeWidth = px(0.6)
      ..color = const Color(0x1A7A5228);
    canvas.save();
    canvas.clipPath(swing);
    for (var gx = dx + dw * 0.12; gx < dx + dw; gx += dw * 0.16) {
      canvas.drawLine(Offset(gx, d - dw), Offset(gx, d), grainDoor);
    }
    canvas.restore();
    canvas.drawArc(
      Rect.fromCircle(center: hinge, radius: dw),
      -math.pi / 2,
      math.pi / 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = px(2)
        ..color = Colors.white,
    );
    canvas.drawLine(
      hinge,
      Offset(dx, d - dw),
      Paint()
        ..strokeWidth = px(2.5)
        ..color = Colors.white,
    );
    canvas.drawCircle(Offset(dx + dw - px(4), d - px(5)), px(2.2), Paint()..color = Colors.white);

    // Compass directions around the room, outside the walls.
    final gap = t + (pad - t) * 0.5;
    for (final dir in Compass.values) {
      final r = (dir.angle - room.direction.angle) * math.pi / 180;
      final vx = math.sin(r);
      final vy = -math.cos(r);
      final tt = math.min(
        vx.abs() > 1e-6 ? (w / 2 + gap) / vx.abs() : double.infinity,
        vy.abs() > 1e-6 ? (d / 2 + gap) / vy.abs() : double.infinity,
      );
      final pos = Offset(w / 2 + vx * tt, d / 2 + vy * tt);
      if (highlight.contains(dir)) {
        canvas.drawCircle(pos, px(13), Paint()..color = colors.jade);
        _text(
          canvas,
          dir.code,
          pos,
          TextStyle(fontSize: fs * 0.9, fontWeight: FontWeight.w700, color: colors.surface),
          center: true,
        );
      } else {
        _text(
          canvas,
          dir.code,
          pos,
          TextStyle(
            fontSize: fs,
            fontWeight: dir.code.length == 1 ? FontWeight.w700 : FontWeight.w500,
            color: colors.muted,
          ),
          center: true,
        );
      }
    }
  }

  /// Light oak planks running across the room, with staggered joints.
  void _floor(Canvas canvas, double w, double d, double foot, double Function(double) px) {
    final room = Rect.fromLTWH(0, 0, w, d);
    canvas.drawRect(room, Paint()..color = const Color(0xFFE4C092));
    canvas.save();
    canvas.clipRect(room);
    const tones = [Color(0xFFE5C193), Color(0xFFE2BD8D), Color(0xFFE8C598), Color(0xFFE0BA89)];
    final plank = 0.8 * foot;
    final board = 8 * foot;
    final rnd = math.Random(11);
    final seam = Paint()
      ..strokeWidth = px(0.7)
      ..color = const Color(0x22815A2E);
    final grain = Paint()
      ..strokeWidth = px(0.5)
      ..color = const Color(0x147A5228);
    var row = 0;
    for (var y = 0.0; y < d; y += plank, row++) {
      var x = -board * rnd.nextDouble();
      while (x < w) {
        final len = board * (0.7 + rnd.nextDouble() * 0.6);
        canvas.drawRect(
          Rect.fromLTWH(x, y, len, plank),
          Paint()..color = tones[rnd.nextInt(tones.length)],
        );
        // Fine, long grain lines along the board.
        for (var g = 0; g < 4; g++) {
          final gy = y + plank * (0.15 + rnd.nextDouble() * 0.7);
          final gx = x + len * rnd.nextDouble() * 0.3;
          canvas.drawLine(
            Offset(gx, gy),
            Offset(gx + len * (0.4 + rnd.nextDouble() * 0.5), gy),
            grain,
          );
        }
        canvas.drawLine(Offset(x, y), Offset(x, y + plank), seam);
        x += len;
      }
      canvas.drawLine(Offset(0, y), Offset(w, y), seam);
    }
    // Soft light from the middle of the room.
    canvas.drawRect(
      room,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: 0.10), Colors.black.withValues(alpha: 0.05)],
        ).createShader(room),
    );
    canvas.restore();
  }

  void _pill(Canvas canvas, String text, Offset at, Color color, double maxWidth) {
    canvas.save();
    canvas.scale(1 / scale);
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.max(0, maxWidth * scale - 10));
    final p = at * scale;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(p.dx, p.dy, tp.width + 10, tp.height + 4),
        const Radius.circular(8),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
    tp.paint(canvas, p + const Offset(5, 2));
    canvas.restore();
  }

  void _text(Canvas canvas, String text, Offset at, TextStyle style, {bool center = false}) {
    // [at] is in room units; the font size is in pixels.
    canvas.save();
    canvas.scale(1 / scale);
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final p = at * scale;
    tp.paint(canvas, center ? p - Offset(tp.width / 2, tp.height / 2) : p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RoomPainter old) =>
      old.room != room ||
      old.colors != colors ||
      old.scale != scale ||
      old.highlight != highlight ||
      old.showBagua != showBagua;
}

/// Fill colour of a piece: its chosen colour, or null for its natural look.
Color? furnitureColor(FurnitureModel item) {
  final hex = item.color;
  if (hex == null || hex.length != 7) return null;
  return Color(int.parse('FF${hex.substring(1)}', radix: 16));
}
