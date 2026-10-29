import '../../../core/constants/astro_constants.dart';
import 'aspect_model.dart';

/// One planet's position, as calculated by the `astrology-chart` function.
class PlanetPosition {
  const PlanetPosition({
    required this.name,
    required this.longitude,
    required this.sign,
    this.house,
    this.retrograde = false,
    this.speed,
  });

  final String name;

  /// Ecliptic longitude in degrees (0–360).
  final double longitude;
  final String sign;

  /// Placidus house, or null without a birth time.
  final int? house;
  final bool retrograde;

  /// Degrees per day along the zodiac.
  final double? speed;

  String get symbol => planetSymbols[name] ?? '•';

  bool get isNode => name == 'North Node';

  factory PlanetPosition.fromJson(Map<String, dynamic> j) => PlanetPosition(
    name: j['name'] as String,
    longitude: (j['longitude'] as num).toDouble(),
    sign: j['sign'] as String,
    house: (j['house'] as num?)?.toInt(),
    retrograde: (j['retrograde'] as bool?) ?? false,
    speed: (j['speed'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'longitude': longitude,
    'sign': sign,
    'house': house,
    'retrograde': retrograde,
    'speed': speed,
  };
}

/// Start of a house: house [number] begins at [cusp] in [sign].
class HouseCusp {
  const HouseCusp({required this.number, required this.sign, required this.cusp});

  final int number;
  final String sign;
  final double cusp;

  factory HouseCusp.fromJson(Map<String, dynamic> j) => HouseCusp(
    number: (j['house'] as num).toInt(),
    sign: j['sign'] as String,
    cusp: (j['cusp'] as num).toDouble(),
  );
}

/// Moon phase at the moment of birth.
class MoonPhaseModel {
  const MoonPhaseModel({required this.name, required this.angle, required this.illumination});

  final String name;

  /// Sun–Moon elongation, 0–360 (0 = New, 180 = Full).
  final double angle;

  /// Lit fraction of the Moon, 0–1.
  final double illumination;

  bool get waxing => angle < 180;

  factory MoonPhaseModel.fromJson(Map<String, dynamic> j) => MoonPhaseModel(
    name: j['name'] as String,
    angle: (j['angle'] as num).toDouble(),
    illumination: (j['illumination'] as num).toDouble(),
  );
}

enum Modality { cardinal, fixed, mutable }

/// Row in `astrology_results`. Written only by the Edge Function.
class AstrologyResultModel {
  const AstrologyResultModel({
    required this.profileId,
    required this.sunSign,
    required this.moonSign,
    this.ascendant,
    this.ascendantLongitude,
    this.mcLongitude,
    this.houseSystem,
    required this.planets,
    required this.houses,
    this.aspects = const [],
    required this.elementBalance,
    this.modalityBalance = const {},
    required this.dominantElement,
    required this.weakestElement,
    this.moonPhase,
    this.calculatedAt,
  });

  final String profileId;
  final String sunSign;
  final String moonSign;

  /// Rising sign; null when the birth time is unknown.
  final String? ascendant;
  final double? ascendantLongitude;

  /// Midheaven longitude; null without a birth time.
  final double? mcLongitude;

  /// "placidus", or null without a birth time.
  final String? houseSystem;
  final List<PlanetPosition> planets;
  final List<HouseCusp> houses;
  final List<AspectModel> aspects;

  /// Percent share of each element, weighted toward Sun, Moon and Rising.
  final Map<AstroElement, int> elementBalance;
  final Map<Modality, int> modalityBalance;
  final AstroElement dominantElement;
  final AstroElement weakestElement;
  final MoonPhaseModel? moonPhase;
  final DateTime? calculatedAt;

  /// True when the chart was calculated by the current engine (with
  /// aspects and modalities). Older results should be recalculated.
  bool get isAdvanced => modalityBalance.isNotEmpty;

  bool get hasHouses => houses.length == 12;

  PlanetPosition? planet(String name) {
    for (final p in planets) {
      if (p.name == name) return p;
    }
    return null;
  }

  /// The ten planets, without the lunar node.
  List<PlanetPosition> get mainPlanets => planets.where((p) => !p.isNode).toList();

  double get sunLongitude => planet('Sun')?.longitude ?? 0;

  /// Longitude of any named point, including Ascendant and Midheaven.
  double? longitudeOf(String name) => switch (name) {
    'Ascendant' => ascendantLongitude,
    'Midheaven' => mcLongitude,
    _ => planet(name)?.longitude,
  };

  List<AspectModel> aspectsFor(String name) => aspects.where((a) => a.involves(name)).toList();

  factory AstrologyResultModel.fromJson(Map<String, dynamic> j) {
    final elements = <AstroElement, int>{};
    ((j['element_balance'] as Map?) ?? const {}).forEach((k, v) {
      elements[AstroElement.fromName(k as String)] = (v as num).round();
    });
    final modes = <Modality, int>{};
    ((j['modality_balance'] as Map?) ?? const {}).forEach((k, v) {
      final m = Modality.values.where((x) => x.name == (k as String).toLowerCase());
      if (m.isNotEmpty) modes[m.first] = (v as num).round();
    });
    List<Map<String, dynamic>> rows(String key) =>
        ((j[key] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final phase = j['moon_phase'];

    return AstrologyResultModel(
      profileId: j['profile_id'] as String,
      sunSign: j['sun_sign'] as String,
      moonSign: j['moon_sign'] as String,
      ascendant: j['ascendant'] as String?,
      ascendantLongitude: (j['ascendant_longitude'] as num?)?.toDouble(),
      mcLongitude: (j['mc_longitude'] as num?)?.toDouble(),
      houseSystem: j['house_system'] as String?,
      planets: rows('planet_data').map(PlanetPosition.fromJson).toList(),
      houses: rows('houses').map(HouseCusp.fromJson).toList(),
      aspects: rows('aspects').map(AspectModel.fromJson).toList(),
      elementBalance: elements,
      modalityBalance: modes,
      dominantElement: AstroElement.fromName(j['dominant_element'] as String),
      weakestElement: AstroElement.fromName(j['weakest_element'] as String),
      moonPhase: phase is Map ? MoonPhaseModel.fromJson(Map<String, dynamic>.from(phase)) : null,
      calculatedAt: j['calculated_at'] == null
          ? null
          : DateTime.tryParse(j['calculated_at'] as String),
    );
  }
}
