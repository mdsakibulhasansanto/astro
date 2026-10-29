import 'dart:io';

import 'package:astro_home/core/utils/local_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('stores and reads JSON, null when missing', () async {
    SharedPreferences.setMockInitialValues({});
    final cache = LocalCache(await SharedPreferences.getInstance());
    expect(cache.read('homes_u1'), isNull);
    await cache.write('homes_u1', [
      {'id': 'h1', 'home_name': 'My Home'},
    ]);
    final back = cache.read('homes_u1') as List;
    expect((back.single as Map)['home_name'], 'My Home');
  });

  test('tells network failures apart from server errors', () {
    expect(isOfflineError(const SocketException('no route')), isTrue);
    expect(isOfflineError(Exception('ClientException: Failed host lookup')), isTrue);
    expect(isOfflineError(Exception('permission denied for table homes')), isFalse);
  });
}
