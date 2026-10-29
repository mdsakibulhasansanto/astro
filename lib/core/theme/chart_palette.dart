import 'package:flutter/material.dart';

import '../constants/astro_constants.dart';
import '../../features/astrology/model/aspect_model.dart';

/// Vivid colours for the birth chart. The chart sits on a night-sky card in
/// both light and dark mode, so these are tuned for a dark background.
class ChartPalette {
  const ChartPalette._();

  static const skyCenter = Color(0xFF1E2A4F);
  static const skyEdge = Color(0xFF0A0F1C);
  static const line = Color(0x40FFFFFF);
  static const text = Color(0xFFF4F1E8);
  static const textMuted = Color(0xB3F4F1E8);
  static const gold = Color(0xFFFFC94A);

  /// Two-colour gradient for each element's signs.
  static List<Color> element(AstroElement e) => switch (e) {
    AstroElement.fire => const [Color(0xFFFF8A3D), Color(0xFFE5394F)],
    AstroElement.earth => const [Color(0xFFD9B44A), Color(0xFF5FA368)],
    AstroElement.air => const [Color(0xFF6FD0FF), Color(0xFFA98BFF)],
    AstroElement.water => const [Color(0xFF3D7BFF), Color(0xFF22C3B8)],
  };

  /// One colour per element, for legends and chips.
  static Color elementSolid(AstroElement e) => Color.lerp(element(e)[0], element(e)[1], 0.5)!;

  /// Traditional planet colours.
  static Color planet(String name) => switch (name) {
    'Sun' => const Color(0xFFFFC94A),
    'Moon' => const Color(0xFFDDE5EE),
    'Mercury' => const Color(0xFF5ED3F3),
    'Venus' => const Color(0xFFF78FB3),
    'Mars' => const Color(0xFFFF5A4E),
    'Jupiter' => const Color(0xFFB98CFF),
    'Saturn' => const Color(0xFFCDA86C),
    'Uranus' => const Color(0xFF3EE0C5),
    'Neptune' => const Color(0xFF5B8CFF),
    'Pluto' => const Color(0xFFD0587A),
    _ => const Color(0xFFA9B0BD),
  };

  static Color aspect(AspectType t) => switch (t) {
    AspectType.conjunction => const Color(0xFFFFC94A),
    AspectType.sextile => const Color(0xFF39D0E6),
    AspectType.trine => const Color(0xFF4FD68A),
    AspectType.square => const Color(0xFFFF5A6A),
    AspectType.opposition => const Color(0xFFFF9A3F),
  };
}
