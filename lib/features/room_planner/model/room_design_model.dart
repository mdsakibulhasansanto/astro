import 'furniture_model.dart';

enum DesignKind { saved, suggested }

/// Row in `room_designs`: a named snapshot of a room's furniture layout.
class RoomDesignModel {
  const RoomDesignModel({
    required this.id,
    required this.roomId,
    required this.name,
    required this.items,
    this.kind = DesignKind.saved,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String roomId;
  final String name;
  final List<FurnitureModel> items;
  final DesignKind kind;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory RoomDesignModel.fromJson(Map<String, dynamic> j) {
    final id = j['id'] as String;
    final roomId = j['room_id'] as String;
    final raw = (j['items'] as List?) ?? const [];
    return RoomDesignModel(
      id: id,
      roomId: roomId,
      name: j['name'] as String,
      kind: j['kind'] == 'suggested' ? DesignKind.suggested : DesignKind.saved,
      items: [
        for (var i = 0; i < raw.length; i++)
          FurnitureModel.fromLayoutJson(
            Map<String, dynamic>.from(raw[i] as Map),
            roomId: roomId,
            localKey: '$id-$i',
          ),
      ],
      createdAt: DateTime.tryParse((j['created_at'] as String?) ?? ''),
      updatedAt: DateTime.tryParse((j['updated_at'] as String?) ?? ''),
    );
  }
}
