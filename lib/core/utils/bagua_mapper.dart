import 'dart:math' as math;

import '../constants/feng_shui_constants.dart';

/// Walls of a room as drawn on the plan: the far wall is at the top and the
/// door wall at the bottom.
enum Wall {
  top('far wall'),
  right('right wall'),
  bottom('door wall'),
  left('left wall');

  const Wall(this.label);

  final String label;

  /// Degrees clockwise from the far wall.
  double get offset => index * 90.0;

  static Wall fromName(String? v) =>
      Wall.values.firstWhere((w) => w.name == v, orElse: () => Wall.top);
}

enum BaguaMethod {
  door('Door (Western)'),
  compass('Compass (Classical)');

  const BaguaMethod(this.label);

  final String label;

  static BaguaMethod fromName(String? v) => v == 'compass' ? BaguaMethod.compass : BaguaMethod.door;
}

/// Maps plan positions to compass directions and bagua zones.
///
/// [facing] is the compass direction you face when you walk in, which is
/// the direction of the far (top) wall.
class BaguaMapper {
  const BaguaMapper(this.facing);

  final Compass facing;

  Compass wallDirection(Wall wall) => Compass.fromAngle(facing.angle + wall.offset);

  /// Grid cell (0–2, 0–2) containing a relative point (0–1, 0–1).
  static ({int col, int row}) cellOf(double relX, double relY) =>
      (col: (relX * 3).floor().clamp(0, 2), row: (relY * 3).floor().clamp(0, 2));

  /// Compass direction of a grid cell, or null for the center cell.
  Compass? cellDirection(int col, int row) {
    if (col == 1 && row == 1) return null;
    final rel = math.atan2(col - 1.0, 1.0 - row) * 180 / math.pi;
    return Compass.fromAngle(facing.angle + rel);
  }

  /// Compass direction of a relative point, or null in the center ninth.
  Compass? directionAt(double relX, double relY) {
    final c = cellOf(relX, relY);
    return cellDirection(c.col, c.row);
  }

  /// Cell lying in a compass direction from the room's center.
  ({int col, int row}) cellForDirection(Compass dir) {
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        if (cellDirection(col, row) == dir) return (col: col, row: row);
      }
    }
    return (col: 1, row: 1);
  }

  BaguaZone zoneForCell(BaguaMethod method, int col, int row) {
    if (method == BaguaMethod.door) return doorBaguaGrid[row][col];
    final dir = cellDirection(col, row);
    return dir == null ? BaguaZone.center : compassBaguaZone[dir]!;
  }

  BaguaZone zoneAt(BaguaMethod method, double relX, double relY) {
    final c = cellOf(relX, relY);
    return zoneForCell(method, c.col, c.row);
  }

  /// Plain description of a cell, as seen when walking in.
  static String describeCell(int col, int row) {
    const rows = ['far', 'middle', 'door-side'];
    const cols = ['left', 'center', 'right'];
    if (col == 1 && row == 1) return 'the center of the room';
    if (col == 1) return row == 0 ? 'the middle of the far wall' : 'the middle by the door';
    if (row == 1) return 'the middle of the ${cols[col]} wall';
    return 'the ${rows[row]} ${cols[col]} corner';
  }
}
