import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/supabase_provider.dart';
import '../../astrology/riverpod/astrology_provider.dart';
import '../../auth/riverpod/auth_provider.dart';
import '../repository/daily_insight_engine.dart';
import '../repository/daily_reading_repo.dart';
import 'daily_reading_state_notifier.dart';

final dailyReadingRepoProvider = Provider<DailyReadingRepo>(
  (ref) => DailyReadingRepo(ref.watch(supabaseClientProvider), ref.watch(dioProvider)),
);

final dailyInsightEngineProvider = Provider<DailyInsightEngine>(
  (ref) => const DailyInsightEngine(),
);

/// Today's reading. Recreated (and recalculated) when the user or their
/// birth chart changes.
final dailyReadingStateNotifierProvider =
    StateNotifierProvider<DailyReadingStateNotifier, DailyReadingState>((ref) {
      ref.watch(currentUserIdProvider);
      final chartId = ref.watch(
        astrologyStateNotifierProvider.select((s) => s.result?.calculatedAt),
      );
      final birthTz = ref.read(astrologyStateNotifierProvider).profile?.timezone ?? 'UTC';
      final notifier = DailyReadingStateNotifier(
        ref.watch(dailyReadingRepoProvider),
        hasChart: chartId != null,
        fallbackTimezone: birthTz,
      );
      notifier.load();
      return notifier;
    });

final readingHistoryStateNotifierProvider =
    StateNotifierProvider.autoDispose<ReadingHistoryStateNotifier, ReadingHistoryState>((ref) {
      final notifier = ReadingHistoryStateNotifier(
        ref.watch(dailyReadingRepoProvider),
        ref.watch(currentUserIdProvider),
      );
      notifier.load();
      return notifier;
    });
