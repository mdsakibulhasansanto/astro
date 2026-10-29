/// Rule-based interpretation tables from traditional Western astrology.
/// The insights engine combines these with the calculated chart; no AI is
/// involved in choosing what a placement means.
library;

/// How a sign colours whatever planet sits in it.
class SignProfile {
  const SignProfile({
    required this.modality,
    required this.ruler,
    required this.keywords,
    required this.style,
    required this.needs,
    required this.gift,
    required this.shadow,
  });

  /// Cardinal, Fixed or Mutable.
  final String modality;

  /// Traditional ruling planet.
  final String ruler;
  final List<String> keywords;

  /// Adverbial phrase: "boldly and directly".
  final String style;

  /// What the sign seeks: "challenge, independence and a fresh start".
  final String needs;
  final String gift;
  final String shadow;
}

const signProfiles = <String, SignProfile>{
  'Aries': SignProfile(
    modality: 'Cardinal',
    ruler: 'Mars',
    keywords: ['Bold', 'Direct', 'Pioneering'],
    style: 'boldly and directly',
    needs: 'challenge, independence and fresh starts',
    gift: 'courage',
    shadow: 'impatience',
  ),
  'Taurus': SignProfile(
    modality: 'Fixed',
    ruler: 'Venus',
    keywords: ['Steady', 'Sensual', 'Loyal'],
    style: 'steadily and patiently',
    needs: 'comfort, security and beautiful, tangible things',
    gift: 'staying power',
    shadow: 'stubbornness',
  ),
  'Gemini': SignProfile(
    modality: 'Mutable',
    ruler: 'Mercury',
    keywords: ['Curious', 'Witty', 'Adaptable'],
    style: 'quickly and playfully',
    needs: 'variety, conversation and new ideas',
    gift: 'versatility',
    shadow: 'restlessness',
  ),
  'Cancer': SignProfile(
    modality: 'Cardinal',
    ruler: 'Moon',
    keywords: ['Caring', 'Protective', 'Intuitive'],
    style: 'gently and protectively',
    needs: 'belonging, family and emotional safety',
    gift: 'nurturing',
    shadow: 'moodiness',
  ),
  'Leo': SignProfile(
    modality: 'Fixed',
    ruler: 'Sun',
    keywords: ['Warm', 'Expressive', 'Generous'],
    style: 'warmly and with flair',
    needs: 'recognition, creativity and heartfelt appreciation',
    gift: 'generosity',
    shadow: 'pride',
  ),
  'Virgo': SignProfile(
    modality: 'Mutable',
    ruler: 'Mercury',
    keywords: ['Precise', 'Helpful', 'Practical'],
    style: 'carefully and precisely',
    needs: 'order, usefulness and steady improvement',
    gift: 'skill',
    shadow: 'over-criticism',
  ),
  'Libra': SignProfile(
    modality: 'Cardinal',
    ruler: 'Venus',
    keywords: ['Fair', 'Graceful', 'Diplomatic'],
    style: 'gracefully and diplomatically',
    needs: 'harmony, partnership and beauty',
    gift: 'balance',
    shadow: 'indecision',
  ),
  'Scorpio': SignProfile(
    modality: 'Fixed',
    ruler: 'Mars',
    keywords: ['Intense', 'Perceptive', 'Devoted'],
    style: 'intensely and privately',
    needs: 'depth, trust and transformation',
    gift: 'resilience',
    shadow: 'jealousy',
  ),
  'Sagittarius': SignProfile(
    modality: 'Mutable',
    ruler: 'Jupiter',
    keywords: ['Adventurous', 'Optimistic', 'Honest'],
    style: 'freely and enthusiastically',
    needs: 'meaning, travel and room to explore',
    gift: 'optimism',
    shadow: 'carelessness',
  ),
  'Capricorn': SignProfile(
    modality: 'Cardinal',
    ruler: 'Saturn',
    keywords: ['Ambitious', 'Disciplined', 'Responsible'],
    style: 'deliberately and with discipline',
    needs: 'achievement, structure and lasting results',
    gift: 'perseverance',
    shadow: 'rigidity',
  ),
  'Aquarius': SignProfile(
    modality: 'Fixed',
    ruler: 'Saturn',
    keywords: ['Original', 'Independent', 'Humane'],
    style: 'inventively and independently',
    needs: 'freedom, friendship and progress',
    gift: 'vision',
    shadow: 'detachment',
  ),
  'Pisces': SignProfile(
    modality: 'Mutable',
    ruler: 'Jupiter',
    keywords: ['Compassionate', 'Imaginative', 'Sensitive'],
    style: 'intuitively and compassionately',
    needs: 'inspiration, quiet and a sense of connection',
    gift: 'empathy',
    shadow: 'escapism',
  ),
};

/// Modern rulers, used alongside traditional ones for the outer planets.
const modernRulers = <String, String>{
  'Scorpio': 'Pluto',
  'Aquarius': 'Uranus',
  'Pisces': 'Neptune',
};

class HouseMeaning {
  const HouseMeaning(this.title, this.area);

  final String title;

  /// Phrase used in sentences: "self-image and first impressions".
  final String area;
}

const houseMeanings = <int, HouseMeaning>{
  1: HouseMeaning('Self', 'your self-image, body and first impressions'),
  2: HouseMeaning('Resources', 'money, possessions and self-worth'),
  3: HouseMeaning('Communication', 'learning, siblings and daily conversations'),
  4: HouseMeaning('Home & roots', 'home, family and your private foundations'),
  5: HouseMeaning('Creativity', 'romance, play, children and self-expression'),
  6: HouseMeaning('Health & work', 'routines, health and daily work'),
  7: HouseMeaning('Partnership', 'close partners, marriage and contracts'),
  8: HouseMeaning('Transformation', 'intimacy, shared money and deep change'),
  9: HouseMeaning('Philosophy', 'travel, higher learning and beliefs'),
  10: HouseMeaning('Career', 'career, reputation and public life'),
  11: HouseMeaning('Community', 'friends, groups and future hopes'),
  12: HouseMeaning('Inner world', 'solitude, dreams and the unconscious'),
};

/// What each planet represents, phrased for sentence templates.
class PlanetFunction {
  const PlanetFunction(this.keyword, this.short);

  /// One-word theme: "Identity".
  final String keyword;

  /// Short noun phrase: "your will".
  final String short;
}

const planetFunctions = <String, PlanetFunction>{
  'Sun': PlanetFunction('Identity', 'your will and sense of self'),
  'Moon': PlanetFunction('Emotions', 'your feelings and need for safety'),
  'Mercury': PlanetFunction('Mind', 'your thinking and communication'),
  'Venus': PlanetFunction('Love', 'your love, taste and values'),
  'Mars': PlanetFunction('Drive', 'your drive and courage'),
  'Jupiter': PlanetFunction('Growth', 'your optimism and growth'),
  'Saturn': PlanetFunction('Structure', 'your discipline and responsibilities'),
  'Uranus': PlanetFunction('Change', 'your need for freedom and change'),
  'Neptune': PlanetFunction('Dreams', 'your imagination and ideals'),
  'Pluto': PlanetFunction('Power', 'your power to transform'),
  'North Node': PlanetFunction('Path', 'your path of growth'),
  'Ascendant': PlanetFunction('Persona', 'the way you meet the world'),
  'Midheaven': PlanetFunction('Calling', 'your public direction and calling'),
};

enum Dignity {
  domicile('Domicile', 'At home in this sign: its qualities come through strongly and naturally.'),
  exaltation('Exalted', 'Honoured in this sign: its best qualities are lifted up.'),
  detriment('Detriment', 'In the sign opposite its home: it works harder and in unusual ways.'),
  fall('Fall', 'In the sign opposite its exaltation: it needs patience to express well.'),
  peregrine('Neutral', 'Neither strengthened nor weakened by this sign.');

  const Dignity(this.label, this.meaning);

  final String label;
  final String meaning;
}

const _domicile = <String, List<String>>{
  'Sun': ['Leo'],
  'Moon': ['Cancer'],
  'Mercury': ['Gemini', 'Virgo'],
  'Venus': ['Taurus', 'Libra'],
  'Mars': ['Aries', 'Scorpio'],
  'Jupiter': ['Sagittarius', 'Pisces'],
  'Saturn': ['Capricorn', 'Aquarius'],
  'Uranus': ['Aquarius'],
  'Neptune': ['Pisces'],
  'Pluto': ['Scorpio'],
};

const _exaltation = <String, String>{
  'Sun': 'Aries',
  'Moon': 'Taurus',
  'Mercury': 'Virgo',
  'Venus': 'Pisces',
  'Mars': 'Capricorn',
  'Jupiter': 'Cancer',
  'Saturn': 'Libra',
};

const _opposite = <String, String>{
  'Aries': 'Libra',
  'Taurus': 'Scorpio',
  'Gemini': 'Sagittarius',
  'Cancer': 'Capricorn',
  'Leo': 'Aquarius',
  'Virgo': 'Pisces',
  'Libra': 'Aries',
  'Scorpio': 'Taurus',
  'Sagittarius': 'Gemini',
  'Capricorn': 'Cancer',
  'Aquarius': 'Leo',
  'Pisces': 'Virgo',
};

/// Essential dignity of [planet] in [sign]. The node has none.
Dignity dignityOf(String planet, String sign) {
  final home = _domicile[planet] ?? const [];
  if (home.contains(sign)) return Dignity.domicile;
  if (_exaltation[planet] == sign) return Dignity.exaltation;
  if (home.any((h) => _opposite[h] == sign)) return Dignity.detriment;
  final ex = _exaltation[planet];
  if (ex != null && _opposite[ex] == sign) return Dignity.fall;
  return Dignity.peregrine;
}

/// What each aspect type does between two placements.
const aspectMeanings = <String, String>{
  'conjunction': 'merge and act as one, which intensifies both',
  'sextile': 'support each other, especially when you make an effort',
  'square': 'push against each other, creating friction that drives growth',
  'trine': 'flow together easily, a natural talent',
  'opposition': 'pull in opposite directions; balance comes from honouring both',
};

const moonPhaseMeanings = <String, String>{
  'New Moon':
      'Born at the New Moon: instinctive and self-starting, you tend to begin things on fresh ground.',
  'Waxing Crescent':
      'Born at the Waxing Crescent: you push forward with determination, building something new.',
  'First Quarter':
      'Born at the First Quarter: action-oriented, you grow through decisions and challenges.',
  'Waxing Gibbous':
      'Born at the Waxing Gibbous: you refine and perfect, always looking to improve.',
  'Full Moon':
      'Born at the Full Moon: aware of relationships and contrasts, you seek balance and clarity.',
  'Waning Gibbous':
      'Born at the Waning Gibbous: a natural teacher, you like to share what you have learned.',
  'Last Quarter':
      'Born at the Last Quarter: you rethink and reorganise, ready to let go of what no longer fits.',
  'Waning Crescent':
      'Born at the Waning Crescent: reflective and intuitive, you sense what is coming next.',
};

const elementTemperaments = <String, String>{
  'Fire': 'Fire-led: energetic, enthusiastic and quick to act.',
  'Earth': 'Earth-led: practical, grounded and steady.',
  'Air': 'Air-led: curious, social and idea-driven.',
  'Water': 'Water-led: emotional, intuitive and caring.',
};

const modalityStyles = <String, String>{
  'Cardinal': 'Mostly cardinal: you like to start things and take the lead.',
  'Fixed': 'Mostly fixed: you are steady, loyal and see things through.',
  'Mutable': 'Mostly mutable: you adapt easily and keep many options open.',
};
