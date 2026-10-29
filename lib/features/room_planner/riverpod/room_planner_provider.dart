import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/network/supabase_provider.dart';
import '../../../core/utils/preferences.dart';
import '../../auth/riverpod/auth_provider.dart';
import '../repository/layout_export_repo.dart';
import '../repository/room_planner_repo.dart';
import 'designs_state_notifier.dart';
import 'furniture_planner_state_notifier.dart';
import 'homes_state_notifier.dart';

final roomPlannerRepoProvider = Provider<RoomPlannerRepo>(
  (ref) => RoomPlannerRepo(ref.watch(supabaseClientProvider), ref.watch(localCacheProvider)),
);

/// Homes and rooms of the signed-in user.
final homesStateNotifierProvider = StateNotifierProvider<HomesStateNotifier, HomesState>((ref) {
  final notifier = HomesStateNotifier(
    ref.watch(roomPlannerRepoProvider),
    ref.watch(currentUserIdProvider),
  );
  notifier.load();
  return notifier;
});

/// Furniture layout for one room, keyed by room id. Disposed when no
/// screen is showing that room.
final furniturePlannerStateNotifierProvider = StateNotifierProvider.autoDispose
    .family<FurniturePlannerStateNotifier, PlannerState, String>((ref, roomId) {
      final notifier = FurniturePlannerStateNotifier(ref.watch(roomPlannerRepoProvider), roomId);
      notifier.load();
      return notifier;
    });

/// Saved designs for one room, keyed by room id.
final designsStateNotifierProvider = StateNotifierProvider.autoDispose
    .family<DesignsStateNotifier, DesignsState, String>((ref, roomId) {
      final notifier = DesignsStateNotifier(ref.watch(roomPlannerRepoProvider), roomId);
      notifier.load();
      return notifier;
    });

final layoutExportRepoProvider = Provider<LayoutExportRepo>((ref) => const LayoutExportRepo());
