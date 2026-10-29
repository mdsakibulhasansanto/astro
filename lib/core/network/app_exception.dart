import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The single error type repositories throw. UI shows [message].
class AppException implements Exception {
  const AppException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory AppException.from(Object error) {
    if (error is AppException) return error;
    if (error is DioException) return AppException._fromDio(error);
    if (error is AuthException) {
      return AppException(error.message, statusCode: _int(error.statusCode));
    }
    if (error is PostgrestException) {
      return AppException(
        'The server could not save or load your data. ${error.message}',
        statusCode: _int(error.code),
      );
    }
    return const AppException('Something went wrong. Please try again.');
  }

  static AppException _fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppException('The request timed out. Please try again.');
      case DioExceptionType.connectionError:
        return const AppException('No connection. Check your internet.');
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final data = e.response?.data;
        final serverMessage = data is Map ? data['error'] ?? data['message'] : null;
        if (code == 401) {
          return const AppException(
            'Your session has expired. Please log in again.',
            statusCode: 401,
          );
        }
        return AppException(serverMessage?.toString() ?? 'Server error ($code).', statusCode: code);
      case DioExceptionType.cancel:
        return const AppException('Request cancelled.');
      default:
        return const AppException('Something went wrong. Please try again.');
    }
  }

  static int? _int(String? v) => v == null ? null : int.tryParse(v);

  @override
  String toString() => message;
}
