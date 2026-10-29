import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/app_exception.dart';

/// Account changes: display name and account deletion.
class ProfileRepo {
  ProfileRepo(this._client, this._dio);

  final SupabaseClient _client;
  final Dio _dio;

  /// Updates the name in the auth profile and the `profiles` table.
  Future<void> updateName(String name) async {
    try {
      final clean = name.trim();
      final user = _client.auth.currentUser;
      if (user == null) throw const AppException('Please log in again.');
      await _client.auth.updateUser(UserAttributes(data: {'name': clean}));
      await _client.from(ApiEndpoints.profiles).update({'name': clean}).eq('id', user.id);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Permanently deletes the account and all its data (server side).
  Future<void> deleteAccount() async {
    try {
      await _dio.post<Map<String, dynamic>>(ApiEndpoints.deleteAccount);
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
