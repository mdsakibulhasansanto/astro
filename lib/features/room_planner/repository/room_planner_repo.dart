import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/utils/local_cache.dart';
import '../model/furniture_model.dart';
import '../model/home_model.dart';
import '../model/room_design_model.dart';
import '../model/room_model.dart';

/// Homes, rooms and furniture in Supabase. Row-level security limits every
/// query to the signed-in user's own data.
class RoomPlannerRepo {
  RoomPlannerRepo(this._client, [this._cache]);

  final SupabaseClient _client;

  /// Last known homes and rooms, shown when the phone is offline.
  final LocalCache? _cache;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<List<HomeModel>> fetchHomes(String userId) async {
    try {
      final rows = await _client
          .from(ApiEndpoints.homes)
          .select('*, rooms(*)')
          .eq('user_id', userId)
          .order('created_at');
      await _cache?.write('homes_$userId', rows);
      return rows.map(HomeModel.fromJson).toList();
    } catch (e) {
      final cached = isOfflineError(e) ? _cache?.read('homes_$userId') : null;
      if (cached is List) {
        return [for (final r in cached) HomeModel.fromJson(Map<String, dynamic>.from(r as Map))];
      }
      throw AppException.from(e);
    }
  }

  Future<HomeModel> createHome(String userId, String name) => _guard(() async {
    final row = await _client
        .from(ApiEndpoints.homes)
        .insert({'user_id': userId, 'home_name': name.trim()})
        .select('*, rooms(*)')
        .single();
    return HomeModel.fromJson(row);
  });

  Future<HomeModel> renameHome(String homeId, String name) => _guard(() async {
    final row = await _client
        .from(ApiEndpoints.homes)
        .update({'home_name': name.trim()})
        .eq('id', homeId)
        .select('*, rooms(*)')
        .single();
    return HomeModel.fromJson(row);
  });

  /// Deletes the home with its rooms and furniture (cascade).
  Future<void> deleteHome(String homeId) =>
      _guard(() => _client.from(ApiEndpoints.homes).delete().eq('id', homeId));

  Future<RoomModel> fetchRoom(String roomId) async {
    try {
      final row = await _client.from(ApiEndpoints.rooms).select().eq('id', roomId).single();
      await _cache?.write('room_$roomId', row);
      return RoomModel.fromJson(row);
    } catch (e) {
      final cached = isOfflineError(e) ? _cache?.read('room_$roomId') : null;
      if (cached is Map) return RoomModel.fromJson(Map<String, dynamic>.from(cached));
      throw AppException.from(e);
    }
  }

  /// Inserts a new room or updates an existing one.
  Future<RoomModel> saveRoom(RoomModel room) => _guard(() async {
    final table = _client.from(ApiEndpoints.rooms);
    final row = room.id == null
        ? await table.insert(room.toJson()).select().single()
        : await table.update(room.toJson()).eq('id', room.id!).select().single();
    return RoomModel.fromJson(row);
  });

  Future<void> deleteRoom(String roomId) =>
      _guard(() => _client.from(ApiEndpoints.rooms).delete().eq('id', roomId));

  Future<List<FurnitureModel>> fetchFurniture(String roomId) async {
    try {
      final rows = await _client
          .from(ApiEndpoints.furniture)
          .select()
          .eq('room_id', roomId)
          .order('created_at');
      await _cache?.write('furniture_$roomId', rows);
      return rows.map(FurnitureModel.fromJson).toList();
    } catch (e) {
      final cached = isOfflineError(e) ? _cache?.read('furniture_$roomId') : null;
      if (cached is List) {
        return [
          for (final r in cached) FurnitureModel.fromJson(Map<String, dynamic>.from(r as Map)),
        ];
      }
      throw AppException.from(e);
    }
  }

  /// Saves the room's whole layout: removes deleted pieces, updates
  /// existing ones and inserts new ones. Returns the stored layout.
  Future<List<FurnitureModel>> saveFurniture({
    required String roomId,
    required List<FurnitureModel> items,
    required Set<String> removedIds,
  }) => _guard(() async {
    final table = _client.from(ApiEndpoints.furniture);
    if (removedIds.isNotEmpty) {
      await table.delete().inFilter('id', removedIds.toList());
    }
    final existing = items.where((i) => i.id != null).map((i) => i.toJson()).toList();
    final fresh = items.where((i) => i.id == null).map((i) => i.toJson()).toList();
    if (existing.isNotEmpty) await table.upsert(existing);
    if (fresh.isNotEmpty) await table.insert(fresh);
    return fetchFurniture(roomId);
  });

  // ------------------------------------------------------------ designs

  Future<List<RoomDesignModel>> fetchDesigns(String roomId) => _guard(() async {
    final rows = await _client
        .from(ApiEndpoints.roomDesigns)
        .select()
        .eq('room_id', roomId)
        .order('updated_at', ascending: false);
    return rows.map(RoomDesignModel.fromJson).toList();
  });

  Future<RoomDesignModel> createDesign({
    required String roomId,
    required String name,
    required List<FurnitureModel> items,
    DesignKind kind = DesignKind.saved,
  }) => _guard(() async {
    final row = await _client
        .from(ApiEndpoints.roomDesigns)
        .insert({
          'room_id': roomId,
          'name': name.trim(),
          'kind': kind.name,
          'items': [for (final i in items) i.toLayoutJson()],
        })
        .select()
        .single();
    return RoomDesignModel.fromJson(row);
  });

  Future<RoomDesignModel> renameDesign(String id, String name) => _guard(() async {
    final row = await _client
        .from(ApiEndpoints.roomDesigns)
        .update({'name': name.trim()})
        .eq('id', id)
        .select()
        .single();
    return RoomDesignModel.fromJson(row);
  });

  Future<void> deleteDesign(String id) =>
      _guard(() => _client.from(ApiEndpoints.roomDesigns).delete().eq('id', id));
}
