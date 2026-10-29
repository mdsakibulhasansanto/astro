import '../../astrology/model/aspect_model.dart';

/// Today's planet in aspect to a birth-chart point.
class TransitModel {
  const TransitModel({
    required this.transit,
    required this.natal,
    required this.type,
    required this.orb,
  });

  /// Moving planet today, e.g. "Venus".
  final String transit;

  /// Birth-chart point it touches, e.g. "Sun" or "Ascendant".
  final String natal;
  final AspectType type;
  final double orb;

  factory TransitModel.fromJson(Map<String, dynamic> j) => TransitModel(
    transit: j['transit'] as String,
    natal: j['natal'] as String,
    type: AspectType.fromName(j['type'] as String),
    orb: (j['orb'] as num).toDouble(),
  );
}

/// Row in `daily_readings`, calculated by the daily-reading function.
class DailyReadingModel {
  const DailyReadingModel({
    required this.date,
    required this.moonSign,
    required this.moonPhase,
    required this.illumination,
    required this.transits,
    required this.retrogrades,
    required this.planetSigns,
  });

  final DateTime date;
  final String moonSign;
  final String moonPhase;

  /// Lit fraction of the Moon, 0–1.
  final double illumination;
  final List<TransitModel> transits;
  final List<String> retrogrades;

  /// Today's sign for each planet.
  final Map<String, String> planetSigns;

  factory DailyReadingModel.fromJson(Map<String, dynamic> row) {
    final d = Map<String, dynamic>.from(row['data'] as Map);
    final moon = Map<String, dynamic>.from(d['moon'] as Map);
    return DailyReadingModel(
      date: DateTime.parse(row['reading_date'] as String),
      moonSign: moon['sign'] as String,
      moonPhase: moon['name'] as String,
      illumination: (moon['illumination'] as num).toDouble(),
      transits: ((d['transits'] as List?) ?? const [])
          .map((e) => TransitModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      retrogrades: ((d['retrogrades'] as List?) ?? const []).cast<String>(),
      planetSigns: {
        for (final p in ((d['planets'] as List?) ?? const []))
          (p as Map)['name'] as String: p['sign'] as String,
      },
    );
  }
}
