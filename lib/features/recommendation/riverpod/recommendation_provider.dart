import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/network/supabase_provider.dart';
import '../../astrology/riverpod/astrology_provider.dart';
import '../../room_planner/riverpod/furniture_planner_state_notifier.dart';
import '../../room_planner/model/furniture_model.dart';
import '../../room_planner/riverpod/room_planner_provider.dart';
import '../model/recommendation_model.dart';
import '../repository/recommendation_engine.dart';
import '../repository/recommendation_history_repo.dart';
import 'recommendation_history_state_notifier.dart';

final recommendationEngineProvider = Provider<RecommendationEngine>(
  (ref) => const RecommendationEngine(),
);

/// Recommendations for a room, recomputed whenever the layout or the chart
/// changes (including unsaved moves in the planner). Null while loading.
///
/// This is a derived, read-only value, so a plain Provider is used; the
/// mutable state it reads lives in the planner and astrology notifiers.
final recommendationProvider = Provider.autoDispose.family<RecommendationModel?, String>((
  ref,
  roomId,
) {
  final planner = ref.watch(furniturePlannerStateNotifierProvider(roomId));
  final astrology = ref.watch(astrologyStateNotifierProvider);
  if (planner.status != PlannerStatus.ready || planner.room == null) return null;
  return ref
      .watch(recommendationEngineProvider)
      .build(
        room: planner.room!,
        items: planner.items,
        chart: astrology.result,
        kua: astrology.kua,
      );
});

/// The current layout with every piece moved to its suggested zone, or
/// null while loading. Derived (read-only).
final suggestedLayoutProvider = Provider.autoDispose.family<List<FurnitureModel>?, String>((
  ref,
  roomId,
) {
  final planner = ref.watch(furniturePlannerStateNotifierProvider(roomId));
  final rec = ref.watch(recommendationProvider(roomId));
  if (rec == null || planner.room == null) return null;
  return ref
      .watch(recommendationEngineProvider)
      .suggestLayout(room: planner.room!, items: planner.items, recommendation: rec);
});

final recommendationHistoryRepoProvider = Provider<RecommendationHistoryRepo>(
  (ref) => RecommendationHistoryRepo(ref.watch(supabaseClientProvider)),
);

/// Kept recommendations for one room.
final recommendationHistoryStateNotifierProvider = StateNotifierProvider.autoDispose
    .family<RecommendationHistoryStateNotifier, RecommendationHistoryState, String>((ref, roomId) {
      final n = RecommendationHistoryStateNotifier(
        ref.watch(recommendationHistoryRepoProvider),
        roomId,
      );
      n.load();
      return n;
    });
