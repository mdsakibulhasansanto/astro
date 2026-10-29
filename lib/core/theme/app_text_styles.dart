import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography: Bodoni Moda for display, Figtree for body,
/// IBM Plex Mono for degrees and numbers.
class AppTextStyles {
  const AppTextStyles._();

  static TextTheme textTheme(Color ink, Color muted) {
    final body = GoogleFonts.figtreeTextTheme().apply(bodyColor: ink, displayColor: ink);
    return body.copyWith(
      displayLarge: display(44, ink),
      displayMedium: display(34, ink),
      headlineMedium: display(26, ink),
      headlineSmall: display(22, ink),
      titleLarge: display(20, ink),
      labelSmall: GoogleFonts.figtree(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
        color: muted,
      ),
    );
  }

  static TextStyle display(double size, Color color, {bool italic = false}) =>
      GoogleFonts.bodoniModa(
        fontSize: size,
        fontWeight: FontWeight.w500,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        color: color,
        height: 1.1,
      );

  static TextStyle mono(double size, Color color) => GoogleFonts.ibmPlexMono(
    fontSize: size,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Zodiac and planet glyphs. Add [textVariation] after a glyph so phones
  /// draw it as text, not as an emoji.
  static TextStyle symbol(double size, Color color) =>
      GoogleFonts.notoSansSymbols(fontSize: size, color: color);

  static const textVariation = '︎';

  /// Small uppercase section heading, like the prototype's `h3`.
  static TextStyle overline(Color muted) => GoogleFonts.figtree(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.1,
    color: muted,
  );
}
