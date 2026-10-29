import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// Small JSON cache on the device, used to show the last known data when
/// the phone is offline.
class LocalCache {
  LocalCache(this._prefs);

  final SharedPreferences _prefs;

  static const _prefix = 'cache_v1_';

  Future<void> write(String key, Object? value) =>
      _prefs.setString('$_prefix$key', jsonEncode(value));

  /// The cached value, or null when nothing is stored.
  Object? read(String key) {
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }
}

/// True for "no connection" style failures (as opposed to the server
/// rejecting the request), where cached data is a sensible fallback.
bool isOfflineError(Object error) {
  if (error is SocketException || error is HttpException) return true;
  final text = error.toString();
  return text.contains('SocketException') ||
      text.contains('ClientException') ||
      text.contains('Failed host lookup') ||
      text.contains('Connection refused') ||
      text.contains('Network is unreachable');
}
