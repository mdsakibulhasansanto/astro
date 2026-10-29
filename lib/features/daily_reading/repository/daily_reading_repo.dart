import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/utils/formatters.dart';
import '../model/daily_reading_model.dart';

/// Daily readings: calculated by the `daily-reading` Edge Function (Dio),
/// read back from the `daily_readings` table (Supabase).
class DailyReadingRepo {
  DailyReadingRepo(this._client, this._dio);

  final SupabaseClient _client;
  final Dio _dio;

  /// Calculates (or refreshes) the reading for [date] in [timezone].
  Future<DailyReadingModel> fetchFor(DateTime date, String timezone) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.dailyReading,
        data: {'date': formatIsoDate(date), 'timezone': timezone},
      );
      final row = res.data?['reading'];
      if (row is! Map) throw const AppException('The daily reading came back empty.');
      return DailyReadingModel.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Past readings, newest first.
  Future<List<DailyReadingModel>> history(String userId, {int limit = 30}) async {
    try {
      final rows = await _client
          .from(ApiEndpoints.dailyReadings)
          .select()
          .eq('user_id', userId)
          .order('reading_date', ascending: false)
          .limit(limit);
      return rows.map(DailyReadingModel.fromJson).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
