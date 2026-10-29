import '../../../core/constants/feng_shui_constants.dart';
import '../../../core/constants/furniture_catalog.dart';

enum PlacementVerdict { good, improve, info }

/// Rule result for one piece of furniture.
class PlacementAdvice {
  const PlacementAdvice({
    required this.label,
    required this.type,
    required this.currentDirection,
    required this.verdict,
    required this.message,
    this.suggestedDirection,
    this.suggestedSpot,
  });

  final String label;
  final FurnitureType type;

  /// Compass zone the piece sits in, or null for the center of the room.
  final Compass? currentDirection;
  final PlacementVerdict verdict;
  final String message;
  final Compass? suggestedDirection;

  /// Where that direction is in this room, e.g. "the far left corner".
  final String? suggestedSpot;

  String get currentLabel => currentDirection?.label ?? 'Center';

  Map<String, dynamic> toJson() => {
    'furniture': label,
    'type': type.name,
    'current_zone': currentLabel,
    'verdict': verdict.name,
    if (suggestedDirection != null) 'suggested_zone': suggestedDirection!.label,
    'rule': message,
  };
}

/// One bagua zone of the room with what is in it and what suits it.
class ZoneReading {
  const ZoneReading({
    required this.zone,
    required this.items,
    required this.chartNote,
    required this.hasKeyPiece,
  });

  final BaguaZone zone;
  final List<String> items;

  /// Ties the zone's planet to the user's chart; null without a chart.
  final String? chartNote;

  /// A desk or bed sits here.
  final bool hasKeyPiece;
}

class ColorSuggestion {
  const ColorSuggestion({required this.name, required this.reason});

  final String name;
  final String reason;
}

/// Everything the Recommendation Result screen shows. Produced by the
/// rule engine; the AI only explains it.
class RecommendationModel {
  const RecommendationModel({
    required this.roomName,
    required this.summary,
    required this.placements,
    required this.zones,
    required this.colors,
    required this.decorIdeas,
    required this.directionTips,
  });

  final String roomName;
  final String summary;
  final List<PlacementAdvice> placements;
  final List<ZoneReading> zones;
  final List<ColorSuggestion> colors;
  final List<String> decorIdeas;
  final List<String> directionTips;

  int get improvementCount => placements.where((p) => p.verdict == PlacementVerdict.improve).length;
}
