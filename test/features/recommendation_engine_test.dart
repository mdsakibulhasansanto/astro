import 'package:astro_home/core/constants/astro_constants.dart';
import 'package:astro_home/core/constants/feng_shui_constants.dart';
import 'package:astro_home/core/constants/furniture_catalog.dart';
import 'package:astro_home/core/utils/bagua_mapper.dart';
import 'package:astro_home/features/astrology/model/astrology_result_model.dart';
import 'package:astro_home/features/recommendation/model/recommendation_model.dart';
import 'package:astro_home/features/recommendation/repository/recommendation_engine.dart';
import 'package:astro_home/features/room_planner/model/furniture_model.dart';
import 'package:astro_home/features/room_planner/model/room_model.dart';
import 'package:flutter_test/flutter_test.dart';

FurnitureModel _item(FurnitureType type, double x, double y, {int rotation = 0}) => FurnitureModel(
  localKey: '${type.name}-$x-$y',
  roomId: 'r1',
  type: type,
  label: type.label,
  x: x,
  y: y,
  width: 0.2,
  height: 0.2,
  rotation: rotation,
);

final _chart = AstrologyResultModel.fromJson({
  'profile_id': 'p1',
  'sun_sign': 'Leo',
  'moon_sign': 'Cancer',
  'ascendant': 'Libra',
  'ascendant_longitude': 190.0,
  'planet_data': [
    {'name': 'Sun', 'longitude': 130.0, 'sign': 'Leo', 'house': 11, 'retrograde': false},
    {'name': 'Moon', 'longitude': 100.0, 'sign': 'Cancer', 'house': 10, 'retrograde': false},
    {'name': 'Venus', 'longitude': 150.0, 'sign': 'Virgo', 'house': 12, 'retrograde': false},
  ],
  'houses': [],
  'element_balance': {'Fire': 40, 'Earth': 10, 'Air': 30, 'Water': 20},
  'dominant_element': 'Fire',
  'weakest_element': 'Earth',
});

void main() {
  const engine = RecommendationEngine();
  const room = RoomModel(
    id: 'r1',
    homeId: 'h1',
    roomName: 'Bedroom',
    width: 12,
    height: 12,
    direction: Compass.n,
    baguaMethod: BaguaMethod.compass,
  );

  test('bed in the North-East is moved to the South-West (requirement example)', () {
    final rec = engine.build(room: room, items: [_item(FurnitureType.bed, 0.75, 0.05)]);
    final bed = rec.placements.single;
    expect(bed.currentDirection, Compass.ne);
    expect(bed.verdict, PlacementVerdict.improve);
    expect(bed.suggestedDirection, Compass.sw);
    expect(bed.suggestedSpot, 'the door-side left corner');
    expect(bed.message, contains('Southwest'));
  });

  test('bed in the West zone is a good spot', () {
    final rec = engine.build(room: room, items: [_item(FurnitureType.bed, 0.05, 0.4)]);
    // Center (0.15, 0.5) is the middle-left cell, which faces West.
    expect(rec.placements.single.currentDirection, Compass.w);
    expect(rec.placements.single.verdict, PlacementVerdict.good);
  });

  test('bed in the center is flagged', () {
    final rec = engine.build(room: room, items: [_item(FurnitureType.bed, 0.4, 0.4)]);
    expect(rec.placements.single.currentDirection, isNull);
    expect(rec.placements.single.verdict, PlacementVerdict.improve);
  });

  test('desk facing a Kua direction is praised, back to door is noted', () {
    // Kua 1: best SE, E, S, N. Rotation 0 = sitter faces the far wall (N).
    final rec = engine.build(room: room, items: [_item(FurnitureType.desk, 0.4, 0.02)], kua: 1);
    final desk = rec.placements.single;
    expect(desk.currentDirection, Compass.n);
    expect(desk.message, contains('growth direction'));
    expect(desk.message, contains('back is to the door'));
  });

  test('chart drives summary, colours and decor; zones cover all nine', () {
    final rec = engine.build(
      room: room,
      items: [_item(FurnitureType.plant, 0.75, 0.75)],
      chart: _chart,
      kua: 8,
    );
    expect(rec.summary, contains('leans Fire'));
    expect(rec.colors.map((c) => c.name), contains(AstroElement.earth.colors.first));
    expect(rec.decorIdeas.first, contains('Leo'));
    expect(rec.zones, hasLength(9));
    expect(rec.zones.where((z) => z.items.contains('Plant')), hasLength(1));
    expect(rec.directionTips.any((t) => t.contains('Kua 8')), isTrue);
  });

  test('is deterministic', () {
    final items = [_item(FurnitureType.sofa, 0.1, 0.1), _item(FurnitureType.tv, 0.7, 0.7)];
    final a = engine.build(room: room, items: items, chart: _chart, kua: 3);
    final b = engine.build(room: room, items: items, chart: _chart, kua: 3);
    expect(a.summary, b.summary);
    expect(a.placements.map((p) => p.message), b.placements.map((p) => p.message));
  });

  test('suggested layout moves pieces into their suggested zones', () {
    final items = [
      _item(FurnitureType.bed, 0.75, 0.05), // North-East: should go South-West
      _item(FurnitureType.plant, 0.75, 0.4), // East: already good
    ];
    final rec = engine.build(room: room, items: items);
    final suggested = engine.suggestLayout(room: room, items: items, recommendation: rec);
    expect(suggested.map((i) => i.localKey), items.map((i) => i.localKey));
    // The plant did not move.
    expect(suggested[1].x, items[1].x);
    // The bed is now in the South-West ninth and passes the rules.
    final after = engine.build(room: room, items: suggested);
    expect(after.placements.first.currentDirection, Compass.sw);
    expect(after.placements.first.verdict, PlacementVerdict.good);
    expect(after.improvementCount, lessThan(rec.improvementCount));
  });
}
