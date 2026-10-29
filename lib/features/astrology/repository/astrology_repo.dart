import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/utils/local_cache.dart';
import '../model/astrology_result_model.dart';
import '../model/birth_profile_model.dart';

/// Birth profile storage (Supabase) and chart calculation (Edge Function
/// via Dio). The app never calculates planets itself.
class AstrologyRepo {
  AstrologyRepo(this._client, this._dio, [this._cache]);

  final SupabaseClient _client;
  final Dio _dio;

  /// Last known profile and chart, shown when the phone is offline.
  final LocalCache? _cache;

  Future<BirthProfileModel?> fetchBirthProfile(String userId) async {
    try {
      final row = await _client
          .from(ApiEndpoints.birthProfiles)
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      await _cache?.write('birth_profile_$userId', row);
      return row == null ? null : BirthProfileModel.fromJson(row);
    } catch (e) {
      final cached = isOfflineError(e) ? _cache?.read('birth_profile_$userId') : null;
      if (cached is Map) return BirthProfileModel.fromJson(Map<String, dynamic>.from(cached));
      throw AppException.from(e);
    }
  }

  /// One birth profile per user; saving again replaces it.
  Future<BirthProfileModel> saveBirthProfile(BirthProfileModel profile) async {
    try {
      final row = await _client
          .from(ApiEndpoints.birthProfiles)
          .upsert(profile.toJson(), onConflict: 'user_id')
          .select()
          .single();
      return BirthProfileModel.fromJson(row);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<AstrologyResultModel?> fetchResult(String profileId) async {
    try {
      final row = await _client
          .from(ApiEndpoints.astrologyResults)
          .select()
          .eq('profile_id', profileId)
          .maybeSingle();
      await _cache?.write('chart_$profileId', row);
      return row == null ? null : AstrologyResultModel.fromJson(row);
    } catch (e) {
      final cached = isOfflineError(e) ? _cache?.read('chart_$profileId') : null;
      if (cached is Map) return AstrologyResultModel.fromJson(Map<String, dynamic>.from(cached));
      throw AppException.from(e);
    }
  }

  /// Runs the calculation engine for a saved profile. The function reads
  /// the profile, calculates the chart, stores it and returns it.
  Future<AstrologyResultModel> calculateChart(String profileId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.astrologyChart,
        data: {'profile_id': profileId},
      );
      final result = res.data?['result'];
      if (result is! Map) {
        throw const AppException('The chart calculation returned no result.');
      }
      return AstrologyResultModel.fromJson(Map<String, dynamic>.from(result));
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
