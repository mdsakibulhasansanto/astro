import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/env.dart';
import 'auth_interceptor.dart';
import 'supabase_provider.dart';

/// The one Dio client for REST calls to Supabase Edge Functions.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.functionsUrl,
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      // AI explanations can take a while to generate.
      receiveTimeout: const Duration(seconds: 60),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );
  dio.interceptors.add(AuthInterceptor(ref.watch(supabaseClientProvider)));
  if (kDebugMode) {
    // Headers are not logged so tokens never reach the console.
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        responseHeader: false,
        requestBody: true,
        responseBody: false,
      ),
    );
  }
  ref.onDispose(dio.close);
  return dio;
});
