import '../../../core/constants/furniture_catalog.dart';
import '../../../core/utils/bagua_mapper.dart';

/// Row in `furniture`. Position and size are relative to the room
/// (0–1 of its width and depth) so the plan scales to any screen.
///
/// The box is axis-aligned on the plan. [rotation] (0, 90, 180, 270) says
/// which wall the piece's back faces: 0 = far wall, 90 = right wall,
/// 180 = door wall, 270 = left wall.
class FurnitureModel {
  const FurnitureModel({
    this.id,
    required this.localKey,
    required this.roomId,
    required this.type,
    required this.label,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0,
    this.color,
  });

  /// Database id; null until saved.
  final String? id;

  /// Stable key for the UI, also for items not saved yet.
  final String localKey;
  final String roomId;
  final FurnitureType type;
  final String label;
  final double x;
  final double y;
  final double width;
  final double height;
  final int rotation;

  /// Fill colour as `#RRGGBB`, or null for the default surface colour.
  final String? color;

  double get centerX => x + width / 2;
  double get centerY => y + height / 2;

  /// The wall the piece's back faces.
  Wall get backWall => Wall.values[(rotation ~/ 90) % 4];

  FurnitureModel copyWith({
    String? id,
    String? label,
    double? x,
    double? y,
    double? width,
    double? height,
    int? rotation,
    String? Function()? color,
  }) => FurnitureModel(
    id: id ?? this.id,
    localKey: localKey,
    roomId: roomId,
    type: type,
    label: label ?? this.label,
    x: x ?? this.x,
    y: y ?? this.y,
    width: width ?? this.width,
    height: height ?? this.height,
    rotation: rotation ?? this.rotation,
    color: color != null ? color() : this.color,
  );

  /// A copy for another room or a new design: no database id.
  FurnitureModel cloneFor(String roomId, String localKey) => FurnitureModel(
    localKey: localKey,
    roomId: roomId,
    type: type,
    label: label,
    x: x,
    y: y,
    width: width,
    height: height,
    rotation: rotation,
    color: color,
  );

  factory FurnitureModel.fromJson(Map<String, dynamic> j) {
    final id = j['id'] as String;
    return FurnitureModel.fromLayoutJson(j, roomId: j['room_id'] as String, id: id, localKey: id);
  }

  /// Reads a furniture row or an item stored inside a saved design.
  factory FurnitureModel.fromLayoutJson(
    Map<String, dynamic> j, {
    required String roomId,
    String? id,
    required String localKey,
  }) {
    final type = FurnitureType.fromName(j['type'] as String);
    return FurnitureModel(
      id: id,
      localKey: localKey,
      roomId: roomId,
      type: type,
      label: (j['label'] as String?) ?? type.label,
      x: (j['x_position'] as num).toDouble(),
      y: (j['y_position'] as num).toDouble(),
      width: (j['width'] as num).toDouble(),
      height: (j['height'] as num).toDouble(),
      rotation: (j['rotation'] as num?)?.toInt() ?? 0,
      color: j['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {if (id != null) 'id': id, 'room_id': roomId, ...toLayoutJson()};

  /// Position, size and look only; used inside saved designs.
  Map<String, dynamic> toLayoutJson() => {
    'type': type.name,
    'label': label,
    'x_position': x,
    'y_position': y,
    'width': width,
    'height': height,
    'rotation': rotation,
    'color': color,
  };
}
