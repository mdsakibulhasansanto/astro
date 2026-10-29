/// Static astrology reference data. Calculations happen in the
/// `astrology-chart` Edge Function; this file only describes the results.
library;

enum AstroElement {
  fire('Fire', 'Fire'),
  earth('Earth', 'Earth'),
  air('Air', 'Metal'),
  water('Water', 'Water');

  const AstroElement(this.label, this.fengShuiLabel);

  final String label;

  /// Feng shui counterpart (Air maps to Metal).
  final String fengShuiLabel;

  static AstroElement fromName(String value) => AstroElement.values.firstWhere(
    (e) => e.label.toLowerCase() == value.toLowerCase(),
    orElse: () => AstroElement.fire,
  );

  String get displayLabel => this == AstroElement.air ? 'Air · Metal' : label;

  /// Ways to bring this element into a room.
  String get remedy => switch (this) {
    AstroElement.fire => 'warm lamps, candles, red or orange accents, triangle shapes, leather',
    AstroElement.earth => 'ceramics, stone, terracotta, square shapes, sand and ochre tones',
    AstroElement.air => 'metal frames, white and grey, round shapes, crisp open surfaces',
    AstroElement.water => 'glass, a mirror, black and deep blue, wavy lines, a small fountain',
  };

  /// Colour palette names suggested for this element.
  List<String> get colors => switch (this) {
    AstroElement.fire => ['Terracotta red', 'Amber', 'Warm orange'],
    AstroElement.earth => ['Ochre', 'Sand', 'Clay brown'],
    AstroElement.air => ['White', 'Soft grey', 'Brushed silver'],
    AstroElement.water => ['Deep blue', 'Charcoal', 'Sea-glass'],
  };
}

class ZodiacSign {
  const ZodiacSign(this.name, this.symbol, this.element, this.decor);

  final String name;
  final String symbol;
  final AstroElement element;

  /// Decor style traditionally associated with the sign.
  final String decor;

  String get short => name.substring(0, 3);
}

const zodiacSigns = <ZodiacSign>[
  ZodiacSign(
    'Aries',
    '♈',
    AstroElement.fire,
    'bold red accents, raw steel, angular shapes, one statement lamp',
  ),
  ZodiacSign(
    'Taurus',
    '♉',
    AstroElement.earth,
    'linen and wool, stoneware, potted plants, moss and clay tones',
  ),
  ZodiacSign(
    'Gemini',
    '♊',
    AstroElement.air,
    'stacked books, layered paper, a pin board, pale yellow, objects in pairs',
  ),
  ZodiacSign(
    'Cancer',
    '♋',
    AstroElement.water,
    'family photos, silver and pearl, rounded vessels, soft throws',
  ),
  ZodiacSign(
    'Leo',
    '♌',
    AstroElement.fire,
    'brass and gold, warm amber light, one showpiece artwork',
  ),
  ZodiacSign(
    'Virgo',
    '♍',
    AstroElement.earth,
    'labeled bins, ordered shelves, natural fibers, sage green, fresh herbs',
  ),
  ZodiacSign(
    'Libra',
    '♎',
    AstroElement.air,
    'symmetry, matching pairs, blush tones, a mirror, balanced groupings',
  ),
  ZodiacSign(
    'Scorpio',
    '♏',
    AstroElement.water,
    'deep colors, dark wood, black accents, closed storage, low moody light',
  ),
  ZodiacSign(
    'Sagittarius',
    '♐',
    AstroElement.fire,
    'maps, travel finds, a globe, indigo and plum, books from other cultures',
  ),
  ZodiacSign(
    'Capricorn',
    '♑',
    AstroElement.earth,
    'slate and charcoal, sturdy heirloom pieces, clean structure',
  ),
  ZodiacSign(
    'Aquarius',
    '♒',
    AstroElement.air,
    'one unexpected piece, glass, electric blue, modular storage',
  ),
  ZodiacSign(
    'Pisces',
    '♓',
    AstroElement.water,
    'sea-glass colors, sheer fabric, water imagery, soft-focus art',
  ),
];

ZodiacSign signByName(String name) => zodiacSigns.firstWhere(
  (s) => s.name.toLowerCase() == name.toLowerCase(),
  orElse: () => zodiacSigns.first,
);

/// Sign containing an ecliptic longitude in degrees.
ZodiacSign signOfLongitude(double longitude) {
  final l = ((longitude % 360) + 360) % 360;
  return zodiacSigns[(l ~/ 30) % 12];
}

const planetSymbols = <String, String>{
  'Sun': '☉',
  'Moon': '☽',
  'Mercury': '☿',
  'Venus': '♀',
  'Mars': '♂',
  'Jupiter': '♃',
  'Saturn': '♄',
  'Uranus': '♅',
  'Neptune': '♆',
  'Pluto': '♇',
  'North Node': '☊',
};

/// What each planet traditionally governs; shown on Planet Details.
const planetMeanings = <String, String>{
  'Sun': 'Identity, vitality and the way you shine.',
  'Moon': 'Emotions, comfort and what makes a place feel like home.',
  'Mercury': 'Thinking, learning and communication.',
  'Venus': 'Love, beauty and what you find pleasing.',
  'Mars': 'Drive, energy and how you take action.',
  'Jupiter': 'Growth, luck and abundance.',
  'Saturn': 'Structure, discipline and long-term goals.',
  'Uranus': 'Change, originality and surprise.',
  'Neptune': 'Dreams, intuition and imagination.',
  'Pluto': 'Transformation and deep renewal.',
  'North Node': 'The direction of growth: qualities you are learning to develop in this life.',
};

class City {
  const City(this.name, this.latitude, this.longitude, this.timezone);

  final String name;
  final double latitude;
  final double longitude;

  /// IANA timezone id, e.g. `Asia/Dhaka`.
  final String timezone;
}

const cities = <City>[
  City('Dhaka', 23.81, 90.41, 'Asia/Dhaka'),
  City('Chittagong', 22.36, 91.78, 'Asia/Dhaka'),
  City('Kolkata', 22.57, 88.36, 'Asia/Kolkata'),
  City('Mumbai', 19.08, 72.88, 'Asia/Kolkata'),
  City('Delhi', 28.61, 77.21, 'Asia/Kolkata'),
  City('Dubai', 25.20, 55.27, 'Asia/Dubai'),
  City('London', 51.51, -0.13, 'Europe/London'),
  City('Paris', 48.86, 2.35, 'Europe/Paris'),
  City('Lagos', 6.52, 3.38, 'Africa/Lagos'),
  City('Manila', 14.60, 120.98, 'Asia/Manila'),
  City('Singapore', 1.35, 103.82, 'Asia/Singapore'),
  City('Tokyo', 35.68, 139.69, 'Asia/Tokyo'),
  City('Sydney', -33.87, 151.21, 'Australia/Sydney'),
  City('Toronto', 43.65, -79.38, 'America/Toronto'),
  City('New York', 40.71, -74.01, 'America/New_York'),
  City('Chicago', 41.88, -87.63, 'America/Chicago'),
  City('Los Angeles', 34.05, -118.24, 'America/Los_Angeles'),
  City('Mexico City', 19.43, -99.13, 'America/Mexico_City'),
  City('São Paulo', -23.55, -46.63, 'America/Sao_Paulo'),
];
