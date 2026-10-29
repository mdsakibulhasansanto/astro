import 'package:astro_home/core/utils/compass_heading.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Phone flat, screen up: gravity reads +9.8 on z. The Earth's field points
  // north and down (here 20 µT north, 40 µT down).
  double heading(double mx, double my) =>
      headingFrom(ax: 0, ay: 0, az: 9.8, mx: mx, my: my, mz: -40)!;

  test('top of the phone pointing north, east, south, west', () {
    expect(heading(0, 20), closeTo(0, 1e-6)); // north along +y
    expect(heading(-20, 0), closeTo(90, 1e-6)); // turned to face east
    expect(heading(0, -20), closeTo(180, 1e-6));
    expect(heading(20, 0), closeTo(270, 1e-6));
  });

  test('tilting the phone does not change the heading', () {
    // Pitched up 30° around x while still facing north.
    const c = 0.8660254;
    const s = 0.5;
    final h = headingFrom(
      ax: 0,
      ay: 9.8 * s,
      az: 9.8 * c,
      mx: 0,
      my: 20 * c - 40 * s * -1 * -1,
      mz: -40 * c - 20 * s,
    );
    expect(h, isNotNull);
    expect(h! < 1 || h > 359, isTrue);
  });

  test('no reading without a magnetic field', () {
    expect(headingFrom(ax: 0, ay: 0, az: 9.8, mx: 0, my: 0, mz: 0), isNull);
  });
}
