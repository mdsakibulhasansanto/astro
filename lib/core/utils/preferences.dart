import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_cache.dart';

/// Device-local settings (e.g. "onboarding seen"). Loaded in `main.dart`
/// before the first frame and injected with `overrideWithValue`, so reads
/// are synchronous everywhere else.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden in main()'),
);

/// Offline copies of the user's chart and homes.
final localCacheProvider = Provider<LocalCache>(
  (ref) => LocalCache(ref.watch(sharedPreferencesProvider)),
);
