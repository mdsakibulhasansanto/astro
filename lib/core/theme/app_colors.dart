import 'package:flutter/material.dart';

import '../constants/astro_constants.dart';
import '../constants/feng_shui_constants.dart';

/// Design tokens from the Astro Home prototype: stone ground, ink type,
/// brass for the sky, jade for good directions, plus five element colours.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.line,
    required this.brass,
    required this.jade,
    required this.fire,
    required this.earth,
    required this.metal,
    required this.water,
    required this.wood,
  });

  final Color bg;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color line;
  final Color brass;
  final Color jade;
  final Color fire;
  final Color earth;
  final Color metal;
  final Color water;
  final Color wood;

  static const light = AppColors(
    bg: Color(0xFFE8EBE5),
    surface: Color(0xFFF6F7F3),
    ink: Color(0xFF1B2232),
    muted: Color(0xFF586172),
    line: Color(0xFFCCD2C7),
    brass: Color(0xFF946A1F),
    jade: Color(0xFF2B6A59),
    fire: Color(0xFFB6472A),
    earth: Color(0xFF9A6E22),
    metal: Color(0xFF6C7787),
    water: Color(0xFF2B5A87),
    wood: Color(0xFF3C7A4A),
  );

  static const dark = AppColors(
    bg: Color(0xFF10141C),
    surface: Color(0xFF181E2A),
    ink: Color(0xFFE6E8E1),
    muted: Color(0xFF9AA2B0),
    line: Color(0xFF2B3343),
    brass: Color(0xFFD4A54E),
    jade: Color(0xFF5FB59B),
    fire: Color(0xFFE2734F),
    earth: Color(0xFFD4A54E),
    metal: Color(0xFFA8B2C0),
    water: Color(0xFF6FA2D6),
    wood: Color(0xFF73B684),
  );

  Color forAstroElement(AstroElement e) => switch (e) {
    AstroElement.fire => fire,
    AstroElement.earth => earth,
    AstroElement.air => metal,
    AstroElement.water => water,
  };

  Color forFengShuiElement(FengShuiElement e) => switch (e) {
    FengShuiElement.fire => fire,
    FengShuiElement.earth => earth,
    FengShuiElement.metal => metal,
    FengShuiElement.water => water,
    FengShuiElement.wood => wood,
  };

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? ink,
    Color? muted,
    Color? line,
    Color? brass,
    Color? jade,
    Color? fire,
    Color? earth,
    Color? metal,
    Color? water,
    Color? wood,
  }) => AppColors(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    ink: ink ?? this.ink,
    muted: muted ?? this.muted,
    line: line ?? this.line,
    brass: brass ?? this.brass,
    jade: jade ?? this.jade,
    fire: fire ?? this.fire,
    earth: earth ?? this.earth,
    metal: metal ?? this.metal,
    water: water ?? this.water,
    wood: wood ?? this.wood,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      brass: Color.lerp(brass, other.brass, t)!,
      jade: Color.lerp(jade, other.jade, t)!,
      fire: Color.lerp(fire, other.fire, t)!,
      earth: Color.lerp(earth, other.earth, t)!,
      metal: Color.lerp(metal, other.metal, t)!,
      water: Color.lerp(water, other.water, t)!,
      wood: Color.lerp(wood, other.wood, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
