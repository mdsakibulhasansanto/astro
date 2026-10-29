import 'dart:convert';

import '../../astrology/model/astrology_result_model.dart';
import '../../recommendation/model/recommendation_model.dart';
import '../../room_planner/model/room_model.dart';

/// What the AI receives: only results the engines already calculated.
/// No birth date, time or place is sent, and nothing for the AI to work out.
class AiExplanationRequestModel {
  const AiExplanationRequestModel({required this.payload});

  final Map<String, dynamic> payload;

  factory AiExplanationRequestModel.from({
    required RoomModel room,
    required RecommendationModel recommendation,
    AstrologyResultModel? chart,
    int? kua,
  }) {
    return AiExplanationRequestModel(
      payload: {
        if (chart != null)
          'astrology': {
            'sun_sign': chart.sunSign,
            'moon_sign': chart.moonSign,
            'rising_sign': chart.ascendant,
            'dominant_element': chart.dominantElement.label,
            'weakest_element': chart.weakestElement.label,
          },
        'kua_number': kua,
        'room': {
          'name': room.roomName,
          'facing_on_entry': room.direction.label,
          'bagua_method': room.baguaMethod.name,
        },
        'furniture': [for (final p in recommendation.placements) p.toJson()],
        'colors': [for (final c in recommendation.colors) '${c.name}: ${c.reason}'],
        'decor_ideas': recommendation.decorIdeas,
        'direction_tips': recommendation.directionTips,
      },
    );
  }

  Map<String, dynamic> toJson() => payload;

  /// Identifies the inputs, so the UI can tell when an explanation is stale.
  String get signature => jsonEncode(payload);
}
