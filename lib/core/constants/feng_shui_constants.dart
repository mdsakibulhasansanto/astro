/// Traditional feng shui reference data: compass directions, Kua groups
/// and the nine bagua zones. Used by the rule-based recommendation engine.
library;

enum Compass {
  n('N', 'North'),
  ne('NE', 'Northeast'),
  e('E', 'East'),
  se('SE', 'Southeast'),
  s('S', 'South'),
  sw('SW', 'Southwest'),
  w('W', 'West'),
  nw('NW', 'Northwest');

  const Compass(this.code, this.label);

  final String code;
  final String label;

  /// Degrees clockwise from north.
  double get angle => index * 45.0;

  static Compass fromAngle(double degrees) {
    final a = ((degrees % 360) + 360) % 360;
    return Compass.values[((a / 45).round()) % 8];
  }

  static Compass fromCode(String code) =>
      Compass.values.firstWhere((c) => c.code == code.toUpperCase(), orElse: () => Compass.n);
}

/// The four supportive directions for each Kua number, in the order
/// Success, Health, Love, Growth.
const kuaBestDirections = <int, List<Compass>>{
  1: [Compass.se, Compass.e, Compass.s, Compass.n],
  2: [Compass.ne, Compass.w, Compass.nw, Compass.sw],
  3: [Compass.s, Compass.n, Compass.se, Compass.e],
  4: [Compass.n, Compass.s, Compass.e, Compass.se],
  6: [Compass.w, Compass.ne, Compass.sw, Compass.nw],
  7: [Compass.nw, Compass.sw, Compass.ne, Compass.w],
  8: [Compass.sw, Compass.nw, Compass.w, Compass.ne],
  9: [Compass.e, Compass.se, Compass.n, Compass.s],
};

const kuaDirectionLabels = ['Success', 'Health', 'Love', 'Growth'];

bool isEastGroup(int kua) => const [1, 3, 4, 9].contains(kua);

enum FengShuiElement { fire, earth, metal, water, wood }

enum BaguaZone {
  wealth(
    'Wealth',
    'Abundance and self-worth',
    FengShuiElement.wood,
    'Jupiter',
    'Healthy plants, a purple or gold accent, something you treasure.',
  ),
  fame(
    'Fame',
    'Reputation and visibility',
    FengShuiElement.fire,
    'Sun',
    'Strong light, a red or warm accent, work you are proud of.',
  ),
  relationships(
    'Relationships',
    'Love and partnership',
    FengShuiElement.earth,
    'Venus',
    'Pairs of objects, blush tones, soft textures.',
  ),
  family(
    'Family',
    'Roots and support',
    FengShuiElement.wood,
    'Moon',
    'Photos of people you love, wood finishes, upright plants.',
  ),
  center(
    'Center',
    'Health and balance',
    FengShuiElement.earth,
    null,
    'Keep it open and clear. Earth tones and a low rug ground the room.',
  ),
  creativity(
    'Creativity',
    'Projects and joy',
    FengShuiElement.metal,
    'Mars',
    'White or metallic finishes, round shapes, work in progress on display.',
  ),
  knowledge(
    'Knowledge',
    'Learning and reflection',
    FengShuiElement.earth,
    'Mercury',
    'Books, a quiet reading spot, deep blue or green.',
  ),
  career(
    'Career',
    'Path and purpose',
    FengShuiElement.water,
    'Saturn',
    'Black or deep blue, flowing shapes, a clear and welcoming entry.',
  ),
  helpfulPeople(
    'Helpful People',
    'Mentors, clients, travel',
    FengShuiElement.metal,
    'Ascendant',
    'Grey, white or metal, images of places you want to go.',
  );

  const BaguaZone(this.label, this.lifeArea, this.element, this.planet, this.tip);

  final String label;
  final String lifeArea;
  final FengShuiElement element;

  /// Planet paired with this area of life, or null for the center.
  final String? planet;
  final String tip;
}

/// Western (door) bagua: rows from the far wall (top) to the door wall.
const doorBaguaGrid = <List<BaguaZone>>[
  [BaguaZone.wealth, BaguaZone.fame, BaguaZone.relationships],
  [BaguaZone.family, BaguaZone.center, BaguaZone.creativity],
  [BaguaZone.knowledge, BaguaZone.career, BaguaZone.helpfulPeople],
];

/// Classical (compass) bagua: zone for each compass direction.
const compassBaguaZone = <Compass, BaguaZone>{
  Compass.s: BaguaZone.fame,
  Compass.n: BaguaZone.career,
  Compass.se: BaguaZone.wealth,
  Compass.sw: BaguaZone.relationships,
  Compass.e: BaguaZone.family,
  Compass.w: BaguaZone.creativity,
  Compass.ne: BaguaZone.knowledge,
  Compass.nw: BaguaZone.helpfulPeople,
};
