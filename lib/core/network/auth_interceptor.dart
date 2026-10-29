import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/env.dart';

/// Attaches the Supabase publishable key and the signed-in user's access
/// token to every Edge Function request. Refreshes an expired session first.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._client);

  final SupabaseClient _client;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    options.headers['apikey'] = Env.supabasePublishableKey;
    var session = _client.auth.currentSession;
    if (session != null && session.isExpired) {
      try {
        session = (await _client.auth.refreshSession()).session;
      } catch (_) {
        // Fall through: the function returns 401 and the UI asks to log in.
      }
    }
    if (session != null) {
      options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    handler.next(options);
  }
}
