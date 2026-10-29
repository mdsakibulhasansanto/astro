import '../../../core/constants/furniture_catalog.dart';
import 'furniture_model.dart';

/// Colours offered for furniture, as `#RRGGBB` with a display name.
const furnitureColors = <(String, String)>[
  ('#8B6B4A', 'Walnut'),
  ('#C8A97E', 'Oak'),
  ('#E8DFD0', 'Ivory'),
  ('#B9B4AA', 'Stone'),
  ('#5A6270', 'Slate'),
  ('#2F3A4A', 'Navy'),
  ('#7E9A7A', 'Sage'),
  ('#C77B5B', 'Terracotta'),
  ('#D8A7A0', 'Blush'),
  ('#3A3A3A', 'Charcoal'),
];

/// Keys of pieces that overlap another piece. Rugs are meant to sit under
/// furniture, so they never count as a collision.
Set<String> overlappingKeys(List<FurnitureModel> items, {double minOverlap = 0.0004}) {
  final solid = items.where((i) => i.type != FurnitureType.rug).toList();
  final out = <String>{};
  for (var i = 0; i < solid.length; i++) {
    for (var j = i + 1; j < solid.length; j++) {
      final a = solid[i];
      final b = solid[j];
      final w =
          (a.x + a.width < b.x + b.width ? a.x + a.width : b.x + b.width) - (a.x > b.x ? a.x : b.x);
      final h =
          (a.y + a.height < b.y + b.height ? a.y + a.height : b.y + b.height) -
          (a.y > b.y ? a.y : b.y);
      if (w > 0 && h > 0 && w * h > minOverlap) {
        out
          ..add(a.localKey)
          ..add(b.localKey);
      }
    }
  }
  return out;
}

/// True when every piece lies inside the room (relative 0–1 box).
bool insideRoom(FurnitureModel i) =>
    i.x >= -1e-9 && i.y >= -1e-9 && i.x + i.width <= 1 + 1e-9 && i.y + i.height <= 1 + 1e-9;
