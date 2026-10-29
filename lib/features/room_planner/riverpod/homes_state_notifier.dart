import 'package:flutter_riverpod/legacy.dart';

import '../../../core/network/app_exception.dart';
import '../model/home_model.dart';
import '../model/room_model.dart';
import '../repository/room_planner_repo.dart';

enum HomesStatus { initial, loading, ready, error }

class HomesState {
  const HomesState({this.status = HomesStatus.initial, this.homes = const [], this.message});

  final HomesStatus status;
  final List<HomeModel> homes;
  final String? message;

  List<RoomModel> get allRooms => [for (final h in homes) ...h.rooms];

  RoomModel? roomById(String id) {
    for (final r in allRooms) {
      if (r.id == id) return r;
    }
    return null;
  }

  HomesState copyWith({HomesStatus? status, List<HomeModel>? homes, String? message}) =>
      HomesState(status: status ?? this.status, homes: homes ?? this.homes, message: message);
}

/// The user's homes and their rooms (the Room Planner tab).
class HomesStateNotifier extends StateNotifier<HomesState> {
  HomesStateNotifier(this._repo, this._userId) : super(const HomesState());

  final RoomPlannerRepo _repo;
  final String? _userId;

  Future<void> load() async {
    final uid = _userId;
    if (uid == null) {
      state = const HomesState(status: HomesStatus.ready);
      return;
    }
    state = state.copyWith(status: HomesStatus.loading);
    try {
      final homes = await _repo.fetchHomes(uid);
      if (!mounted) return;
      state = HomesState(status: HomesStatus.ready, homes: homes);
    } on AppException catch (e) {
      if (!mounted) return;
      state = state.copyWith(status: HomesStatus.error, message: e.message);
    }
  }

  /// Each mutation returns null on success or an error message.
  Future<String?> _run(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on AppException catch (e) {
      return e.message;
    }
  }

  Future<String?> createHome(String name) => _run(() async {
    final uid = _userId;
    if (uid == null) throw const AppException('Please log in again.');
    final home = await _repo.createHome(uid, name);
    if (!mounted) return;
    state = state.copyWith(homes: [...state.homes, home]);
  });

  Future<String?> renameHome(String homeId, String name) => _run(() async {
    final updated = await _repo.renameHome(homeId, name);
    if (!mounted) return;
    state = state.copyWith(homes: [for (final h in state.homes) h.id == homeId ? updated : h]);
  });

  Future<String?> deleteHome(String homeId) => _run(() async {
    await _repo.deleteHome(homeId);
    if (!mounted) return;
    state = state.copyWith(homes: state.homes.where((h) => h.id != homeId).toList());
  });

  /// Saves a new or edited room. Returns the stored room, or throws.
  Future<RoomModel> saveRoom(RoomModel room) async {
    final saved = await _repo.saveRoom(room);
    if (mounted) {
      state = state.copyWith(
        homes: [
          for (final h in state.homes)
            if (h.id != saved.homeId)
              h
            else
              h.copyWith(
                rooms: room.id == null
                    ? [...h.rooms, saved]
                    : [for (final r in h.rooms) r.id == saved.id ? saved : r],
              ),
        ],
      );
    }
    return saved;
  }

  Future<String?> deleteRoom(RoomModel room) => _run(() async {
    await _repo.deleteRoom(room.id!);
    if (!mounted) return;
    state = state.copyWith(
      homes: [
        for (final h in state.homes)
          h.id == room.homeId
              ? h.copyWith(rooms: h.rooms.where((r) => r.id != room.id).toList())
              : h,
      ],
    );
  });
}
