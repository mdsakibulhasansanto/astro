/// Major aspect types, with their exact angle and whether they are
/// traditionally easy (harmonious) or demanding.
enum AspectType {
  conjunction('Conjunction', '☌', 0, null),
  sextile('Sextile', '⚹', 60, true),
  square('Square', '□', 90, false),
  trine('Trine', '△', 120, true),
  opposition('Opposition', '☍', 180, false);

  const AspectType(this.label, this.symbol, this.angle, this.harmonious);

  final String label;
  final String symbol;
  final int angle;

  /// True for flowing aspects, false for tense ones, null for conjunctions
  /// (which take on the nature of the planets involved).
  final bool? harmonious;

  static AspectType fromName(String v) =>
      AspectType.values.firstWhere((t) => t.name == v, orElse: () => AspectType.conjunction);
}

/// An aspect between two chart points, from the `astrology-chart` function.
class AspectModel {
  const AspectModel({
    required this.a,
    required this.b,
    required this.type,
    required this.angle,
    required this.orb,
    this.applying,
  });

  /// Point names, e.g. "Sun", "Moon", "Ascendant", "Midheaven".
  final String a;
  final String b;
  final AspectType type;

  /// Actual angle between the points.
  final double angle;

  /// Distance from exact, in degrees. Smaller is stronger.
  final double orb;

  /// Moving toward exact (true) or away (false); null for fixed points.
  final bool? applying;

  bool involves(String name) => a == name || b == name;

  String other(String name) => a == name ? b : a;

  /// 1 (wide) to 3 (very close).
  int get strength => orb < 1.5 ? 3 : (orb < 4 ? 2 : 1);

  factory AspectModel.fromJson(Map<String, dynamic> j) => AspectModel(
    a: j['a'] as String,
    b: j['b'] as String,
    type: AspectType.fromName(j['type'] as String),
    angle: (j['angle'] as num).toDouble(),
    orb: (j['orb'] as num).toDouble(),
    applying: j['applying'] as bool?,
  );
}
