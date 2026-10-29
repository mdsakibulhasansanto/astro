import 'recommendation_model.dart';

/// Row in `recommendation_history`: a recommendation the user kept.
class RecommendationHistoryModel {
  const RecommendationHistoryModel({
    required this.id,
    required this.roomId,
    required this.summary,
    required this.improvementCount,
    required this.pieceCount,
    required this.placements,
    this.createdAt,
  });

  final String id;
  final String roomId;
  final String summary;
  final int improvementCount;
  final int pieceCount;

  /// Saved placement advice (furniture, current_zone, verdict,
  /// suggested_zone, rule).
  final List<Map<String, dynamic>> placements;
  final DateTime? createdAt;

  factory RecommendationHistoryModel.fromJson(Map<String, dynamic> j) => RecommendationHistoryModel(
    id: j['id'] as String,
    roomId: j['room_id'] as String,
    summary: j['summary'] as String,
    improvementCount: (j['improvement_count'] as num?)?.toInt() ?? 0,
    pieceCount: (j['piece_count'] as num?)?.toInt() ?? 0,
    placements: ((j['placements'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(),
    createdAt: DateTime.tryParse((j['created_at'] as String?) ?? ''),
  );

  static Map<String, dynamic> rowFrom(String roomId, RecommendationModel rec) => {
    'room_id': roomId,
    'summary': rec.summary,
    'improvement_count': rec.improvementCount,
    'piece_count': rec.placements.length,
    'placements': [for (final p in rec.placements) p.toJson()],
  };
}
