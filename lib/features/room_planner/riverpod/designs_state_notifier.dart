import 'package:flutter_riverpod/legacy.dart';

import '../../../core/network/app_exception.dart';
import '../model/furniture_model.dart';
import '../model/room_design_model.dart';
import '../repository/room_planner_repo.dart';

class DesignsState {
  const DesignsState({this.loading = true, this.designs = const [], this.message});

  final bool loading;
  final List<RoomDesignModel> designs;
  final String? message;
}

/// Saved designs (layout snapshots) for one room.
class DesignsStateNotifier extends StateNotifier<DesignsState> {
  DesignsStateNotifier(this._repo, this.roomId) : super(const DesignsState());

  final RoomPlannerRepo _repo;
  final String roomId;

  Future<void> load() async {
    try {
      final designs = await _repo.fetchDesigns(roomId);
      if (mounted) state = DesignsState(loading: false, designs: designs);
    } on AppException catch (e) {
      if (mounted) state = DesignsState(loading: false, message: e.message);
    }
  }

  Future<String?> _run(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }

  /// Saves [items] as a new design. Returns null or an error message.
  Future<String?> saveAs(
    String name,
    List<FurnitureModel> items, {
    DesignKind kind = DesignKind.saved,
  }) => _run(() async {
    final d = await _repo.createDesign(roomId: roomId, name: name, items: items, kind: kind);
    if (mounted) state = DesignsState(loading: false, designs: [d, ...state.designs]);
  });

  Future<String?> duplicate(RoomDesignModel design) =>
      saveAs('${design.name} (copy)', design.items, kind: design.kind);

  Future<String?> rename(RoomDesignModel design, String name) => _run(() async {
    final updated = await _repo.renameDesign(design.id, name);
    if (mounted) {
      state = DesignsState(
        loading: false,
        designs: [for (final d in state.designs) d.id == design.id ? updated : d],
      );
    }
  });

  Future<String?> delete(RoomDesignModel design) => _run(() async {
    await _repo.deleteDesign(design.id);
    if (mounted) {
      state = DesignsState(
        loading: false,
        designs: state.designs.where((d) => d.id != design.id).toList(),
      );
    }
  });
}
