import '../../../core/constants/feng_shui_constants.dart';
import '../../../core/constants/furniture_catalog.dart';
import '../../../core/utils/bagua_mapper.dart';

enum DoorPosition {
  left('Left'),
  center('Center'),
  right('Right');

  const DoorPosition(this.label);

  final String label;

  static DoorPosition fromName(String? v) =>
      DoorPosition.values.firstWhere((d) => d.name == v, orElse: () => DoorPosition.center);
}

enum WindowPosition {
  top('Far wall'),
  left('Left wall'),
  right('Right wall'),
  none('No window');

  const WindowPosition(this.label);

  final String label;

  static WindowPosition fromName(String? v) =>
      WindowPosition.values.firstWhere((w) => w.name == v, orElse: () => WindowPosition.top);
}

/// Row in `rooms`. The door is always on the bottom (door) wall of the plan.
class RoomModel {
  const RoomModel({
    this.id,
    required this.homeId,
    required this.roomName,
    required this.width,
    required this.height,
    this.unit = MeasurementUnit.ft,
    this.direction = Compass.n,
    this.doorPosition = DoorPosition.center,
    this.windowPosition = WindowPosition.top,
    this.baguaMethod = BaguaMethod.door,
    this.createdAt,
  });

  final String? id;
  final String homeId;
  final String roomName;

  /// Width along the door wall, in [unit].
  final double width;

  /// Depth from the door wall to the far wall, in [unit].
  final double height;
  final MeasurementUnit unit;

  /// Compass direction you face when you walk in through the door.
  final Compass direction;
  final DoorPosition doorPosition;
  final WindowPosition windowPosition;
  final BaguaMethod baguaMethod;
  final DateTime? createdAt;

  BaguaMapper get mapper => BaguaMapper(direction);

  RoomModel copyWith({
    String? roomName,
    double? width,
    double? height,
    MeasurementUnit? unit,
    Compass? direction,
    DoorPosition? doorPosition,
    WindowPosition? windowPosition,
    BaguaMethod? baguaMethod,
  }) => RoomModel(
    id: id,
    homeId: homeId,
    roomName: roomName ?? this.roomName,
    width: width ?? this.width,
    height: height ?? this.height,
    unit: unit ?? this.unit,
    direction: direction ?? this.direction,
    doorPosition: doorPosition ?? this.doorPosition,
    windowPosition: windowPosition ?? this.windowPosition,
    baguaMethod: baguaMethod ?? this.baguaMethod,
    createdAt: createdAt,
  );

  factory RoomModel.fromJson(Map<String, dynamic> j) => RoomModel(
    id: j['id'] as String?,
    homeId: j['home_id'] as String,
    roomName: j['room_name'] as String,
    width: (j['width'] as num).toDouble(),
    height: (j['height'] as num).toDouble(),
    unit: MeasurementUnit.fromName(j['unit'] as String? ?? 'ft'),
    direction: Compass.fromCode(j['direction'] as String? ?? 'N'),
    doorPosition: DoorPosition.fromName(j['door_position'] as String?),
    windowPosition: WindowPosition.fromName(j['window_position'] as String?),
    baguaMethod: BaguaMethod.fromName(j['bagua_method'] as String?),
    createdAt: DateTime.tryParse((j['created_at'] as String?) ?? ''),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'home_id': homeId,
    'room_name': roomName.trim(),
    'width': width,
    'height': height,
    'unit': unit.name,
    'direction': direction.code,
    'door_position': doorPosition.name,
    'window_position': windowPosition.name,
    'bagua_method': baguaMethod.name,
  };
}
