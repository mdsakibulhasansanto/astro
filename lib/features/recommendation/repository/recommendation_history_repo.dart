import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/app_exception.dart';
import '../model/recommendation_history_model.dart';
import '../model/recommendation_model.dart';

/// Recommendations the user chose to keep, per room.
class RecommendationHistoryRepo {
  RecommendationHistoryRepo(this._client);

  final SupabaseClient _client;

  Future<List<RecommendationHistoryModel>> fetch(String roomId) async {
    try {
      final rows = await _client
          .from(ApiEndpoints.recommendationHistory)
          .select()
          .eq('room_id', roomId)
          .order('created_at', ascending: false)
          .limit(50);
      return rows.map(RecommendationHistoryModel.fromJson).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<RecommendationHistoryModel> save(String roomId, RecommendationModel rec) async {
    try {
      final row = await _client
          .from(ApiEndpoints.recommendationHistory)
          .insert(RecommendationHistoryModel.rowFrom(roomId, rec))
          .select()
          .single();
      return RecommendationHistoryModel.fromJson(row);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from(ApiEndpoints.recommendationHistory).delete().eq('id', id);
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
