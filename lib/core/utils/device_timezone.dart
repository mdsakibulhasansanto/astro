import 'package:flutter_timezone/flutter_timezone.dart';

/// IANA timezone of the phone (e.g. `Asia/Dhaka`), or [fallback] if the
/// platform cannot tell.
Future<String> deviceTimezone({String fallback = 'UTC'}) async {
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    return info.identifier.isEmpty ? fallback : info.identifier;
  } catch (_) {
    return fallback;
  }
}
