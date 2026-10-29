import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/utils/preferences.dart';
import '../../auth/riverpod/auth_provider.dart';
import '../model/chart_insights_model.dart';
import '../repository/astrology_repo.dart';
import '../repository/chart_insights_engine.dart';
import 'astrology_state_notifier.dart';

final astrologyRepoProvider = Provider<AstrologyRepo>(
  (ref) => AstrologyRepo(
    ref.watch(supabaseClientProvider),
    ref.watch(dioProvider),
    ref.watch(localCacheProvider),
  ),
);

/// Rebuilt (and reloaded) whenever the signed-in user changes.
final astrologyStateNotifierProvider =
    StateNotifierProvider<AstrologyStateNotifier, AstrologyState>((ref) {
      final notifier = AstrologyStateNotifier(
        ref.watch(astrologyRepoProvider),
        ref.watch(currentUserIdProvider),
      );
      notifier.load();
      return notifier;
    });

final chartInsightsEngineProvider = Provider<ChartInsightsEngine>(
  (ref) => const ChartInsightsEngine(),
);

/// Interpretations of the current chart, or null when there is none.
/// Derived (read-only), so a plain Provider is enough.
final chartInsightsProvider = Provider<ChartInsights?>((ref) {
  final result = ref.watch(astrologyStateNotifierProvider.select((s) => s.result));
  return result == null ? null : ref.watch(chartInsightsEngineProvider).build(result);
});
