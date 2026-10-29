import '../../../core/constants/astro_interpretations.dart';
import 'aspect_model.dart';
import 'astrology_result_model.dart';

/// A titled paragraph of interpretation.
class InsightCard {
  const InsightCard({
    required this.eyebrow,
    required this.title,
    required this.body,
    this.tags = const [],
  });

  /// Small label above the title: "Core self", "Love".
  final String eyebrow;
  final String title;
  final String body;
  final List<String> tags;
}

/// Interpretation of one planet's placement.
class PlanetReading {
  const PlanetReading({
    required this.planet,
    required this.dignity,
    required this.title,
    required this.body,
    required this.keywords,
    required this.aspects,
  });

  final PlanetPosition planet;
  final Dignity dignity;

  /// "Moon in Aquarius, 2nd house".
  final String title;
  final String body;
  final List<String> keywords;
  final List<AspectReading> aspects;
}

class AspectReading {
  const AspectReading({required this.aspect, required this.title, required this.body});

  final AspectModel aspect;

  /// "Moon square Venus".
  final String title;
  final String body;
}

/// A recognised configuration of several planets.
class ChartPattern {
  const ChartPattern({required this.name, required this.planets, required this.body});

  final String name;
  final List<String> planets;
  final String body;
}

/// Everything shown on the Insights, Planets and Aspects tabs.
class ChartInsights {
  const ChartInsights({
    required this.core,
    required this.lifeAreas,
    required this.temperament,
    required this.planets,
    required this.aspects,
    required this.patterns,
  });

  /// Sun, Moon, Rising, chart ruler, Moon phase.
  final List<InsightCard> core;

  /// Love, career, home, mind.
  final List<InsightCard> lifeAreas;

  /// Element, modality and hemisphere emphasis.
  final List<InsightCard> temperament;
  final Map<String, PlanetReading> planets;
  final List<AspectReading> aspects;
  final List<ChartPattern> patterns;
}
