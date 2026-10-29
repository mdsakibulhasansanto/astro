import 'package:astro_home/core/constants/feng_shui_constants.dart';
import 'package:astro_home/core/utils/bagua_mapper.dart';
import 'package:astro_home/core/utils/formatters.dart';
import 'package:astro_home/core/utils/kua_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kuaNumber', () {
    test('matches published Kua tables', () {
      expect(kuaNumber(DateTime(1990, 6, 15), isMale: true), 1);
      expect(kuaNumber(DateTime(1990, 6, 15), isMale: false), 8);
      expect(kuaNumber(DateTime(2000, 6, 1), isMale: true), 9);
      expect(kuaNumber(DateTime(2000, 6, 1), isMale: false), 6);
      expect(kuaNumber(DateTime(1985, 8, 1), isMale: true), 6);
      expect(kuaNumber(DateTime(1985, 8, 1), isMale: false), 9);
    });

    test('birthdays before 4 February count as the previous year', () {
      expect(
        kuaNumber(DateTime(1991, 1, 20), isMale: true),
        kuaNumber(DateTime(1990, 6, 1), isMale: true),
      );
      expect(
        kuaNumber(DateTime(1991, 2, 4), isMale: true),
        isNot(kuaNumber(DateTime(1990, 6, 1), isMale: true)),
      );
    });

    test('never returns 5', () {
      for (var y = 1930; y < 2030; y++) {
        for (final male in [true, false]) {
          final k = kuaNumber(DateTime(y, 6, 1), isMale: male);
          expect(k, isNot(5));
          expect(kuaBestDirections.containsKey(k), isTrue, reason: '$y $male → $k');
        }
      }
    });
  });

  group('BaguaMapper', () {
    test('far wall is the facing direction, right wall is clockwise', () {
      const m = BaguaMapper(Compass.n);
      expect(m.wallDirection(Wall.top), Compass.n);
      expect(m.wallDirection(Wall.right), Compass.e);
      expect(m.wallDirection(Wall.bottom), Compass.s);
      expect(m.wallDirection(Wall.left), Compass.w);
    });

    test('cells map to compass directions', () {
      const north = BaguaMapper(Compass.n);
      expect(north.cellDirection(1, 0), Compass.n);
      expect(north.cellDirection(2, 0), Compass.ne);
      expect(north.cellDirection(0, 2), Compass.sw);
      expect(north.cellDirection(1, 1), isNull);

      const south = BaguaMapper(Compass.s);
      expect(south.cellDirection(1, 0), Compass.s);
      expect(south.cellDirection(0, 2), Compass.ne);
    });

    test('door method ignores the compass, compass method follows it', () {
      const m = BaguaMapper(Compass.e);
      expect(m.zoneForCell(BaguaMethod.door, 1, 2), BaguaZone.career);
      expect(m.zoneForCell(BaguaMethod.door, 0, 0), BaguaZone.wealth);
      // Facing East: the far wall is East (Family).
      expect(m.zoneForCell(BaguaMethod.compass, 1, 0), BaguaZone.family);
      expect(m.zoneForCell(BaguaMethod.compass, 1, 1), BaguaZone.center);
    });

    test('cellForDirection is the inverse of cellDirection', () {
      for (final facing in Compass.values) {
        final m = BaguaMapper(facing);
        for (final d in Compass.values) {
          final c = m.cellForDirection(d);
          expect(m.cellDirection(c.col, c.row), d);
        }
      }
    });
  });

  test('formatSignDegree', () {
    expect(formatSignDegree(84.12), '24°07′');
    expect(formatSignDegree(359.999), '30°00′');
    expect(formatSignDegree(-1), '29°00′');
  });
}
