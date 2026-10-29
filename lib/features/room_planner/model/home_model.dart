import 'room_model.dart';

/// Row in `homes`, with its rooms.
class HomeModel {
  const HomeModel({
    required this.id,
    required this.userId,
    required this.homeName,
    this.rooms = const [],
    this.createdAt,
  });

  final String id;
  final String userId;
  final String homeName;
  final List<RoomModel> rooms;
  final DateTime? createdAt;

  HomeModel copyWith({String? homeName, List<RoomModel>? rooms}) => HomeModel(
    id: id,
    userId: userId,
    homeName: homeName ?? this.homeName,
    rooms: rooms ?? this.rooms,
    createdAt: createdAt,
  );

  /// Accepts a `homes` row selected with `*, rooms(*)`.
  factory HomeModel.fromJson(Map<String, dynamic> j) {
    final rooms =
        ((j['rooms'] as List?) ?? const [])
            .map((e) => RoomModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList()
          ..sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
    return HomeModel(
      id: j['id'] as String,
      userId: j['user_id'] as String,
      homeName: j['home_name'] as String,
      rooms: rooms,
      createdAt: DateTime.tryParse((j['created_at'] as String?) ?? ''),
    );
  }
}
