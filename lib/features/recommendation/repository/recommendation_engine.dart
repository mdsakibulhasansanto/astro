import 'dart:math' as math;

import '../../../core/constants/astro_constants.dart';
import '../../../core/constants/feng_shui_constants.dart';
import '../../../core/constants/furniture_catalog.dart';
import '../../../core/utils/bagua_mapper.dart';
import '../../astrology/model/astrology_result_model.dart';
import '../../room_planner/model/furniture_model.dart';
import '../../room_planner/model/layout_checks.dart';
import '../../room_planner/model/room_model.dart';
import '../model/recommendation_model.dart';

/// Placement rule for a furniture type, from traditional feng shui.
class _Rule {
  const _Rule(this.preferred, this.why, {this.avoidCenter = false});

  /// Compass zones in order of preference. Empty = fits anywhere.
  final List<Compass> preferred;
  final String why;
  final bool avoidCenter;
}

const _heavy = _Rule(
  [Compass.w, Compass.nw, Compass.sw],
  'Heavy, solid pieces traditionally belong in the West, Northwest or Southwest, '
  'which are treated as stable zones.',
  avoidCenter: true,
);

const _rules = <FurnitureType, _Rule>{
  FurnitureType.bed: _Rule(
    [Compass.sw, Compass.s, Compass.w],
    'Southwest (Relationships) is the traditional anchor for a bed; South and West also support rest.',
    avoidCenter: true,
  ),
  FurnitureType.desk: _Rule([
    Compass.n,
    Compass.ne,
    Compass.se,
  ], 'North (Career), Northeast (Knowledge) and Southeast (Wealth) support focused work.'),
  FurnitureType.sofa: _Rule([
    Compass.sw,
    Compass.w,
    Compass.s,
  ], 'Southwest and West support togetherness and conversation.'),
  FurnitureType.wardrobe: _heavy,
  FurnitureType.storage: _heavy,
  FurnitureType.bookshelf: _heavy,
  FurnitureType.tv: _Rule([
    Compass.s,
    Compass.se,
    Compass.e,
  ], 'Screens carry Fire energy. South suits it, and the Wood zones East and Southeast feed it.'),
  FurnitureType.plant: _Rule([
    Compass.e,
    Compass.se,
    Compass.s,
  ], 'Plants are Wood. East and Southeast are Wood zones, and South welcomes them.'),
  FurnitureType.lamp: _Rule(
    [Compass.s, Compass.sw, Compass.ne],
    'Light is Fire. South is the Fire zone, and Fire feeds the Earth zones Southwest and Northeast.',
  ),
  FurnitureType.mirror: _Rule([
    Compass.n,
    Compass.e,
    Compass.se,
  ], 'Mirrors carry Water energy. North is Water, and East and Southeast welcome it.'),
  FurnitureType.table: _Rule([], 'Tables work anywhere; keep the paths around them clear.'),
  FurnitureType.chair: _Rule(
    [],
    'Chairs work anywhere; a solid wall behind one feels most secure.',
  ),
  FurnitureType.rug: _Rule([], 'A rug near the center grounds the room with Earth energy.'),
};

/// Element of the zone each compass direction rules.
const _directionElement = <Compass, FengShuiElement>{
  Compass.n: FengShuiElement.water,
  Compass.s: FengShuiElement.fire,
  Compass.e: FengShuiElement.wood,
  Compass.se: FengShuiElement.wood,
  Compass.w: FengShuiElement.metal,
  Compass.nw: FengShuiElement.metal,
  Compass.ne: FengShuiElement.earth,
  Compass.sw: FengShuiElement.earth,
};

const _fengShuiColors = <FengShuiElement, List<String>>{
  FengShuiElement.fire: ['Warm red', 'Amber'],
  FengShuiElement.earth: ['Sand', 'Terracotta'],
  FengShuiElement.metal: ['White', 'Soft grey'],
  FengShuiElement.water: ['Deep blue', 'Charcoal'],
  FengShuiElement.wood: ['Leaf green', 'Natural wood'],
};

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Rule-based recommendations for a room. Pure and deterministic: the same
/// chart and layout always give the same advice. No AI is involved.
class RecommendationEngine {
  const RecommendationEngine();

  RecommendationModel build({
    required RoomModel room,
    required List<FurnitureModel> items,
    AstrologyResultModel? chart,
    int? kua,
  }) {
    final mapper = room.mapper;
    final best = kua == null ? const <Compass>[] : kuaBestDirections[kua] ?? const [];
    final door = _doorRange(room);

    final placements = [for (final item in items) _adviseItem(item, room, mapper, best, door)];

    return RecommendationModel(
      roomName: room.roomName,
      summary: _summary(chart, placements),
      placements: placements,
      zones: _zones(room, items, chart),
      colors: _colors(room, chart),
      decorIdeas: _decor(room, items, chart),
      directionTips: _directionTips(room, kua, best),
    );
  }

  /// A suggested layout: each piece the rules want moved is placed in its
  /// suggested zone (the matching ninth of the room), avoiding collisions
  /// where possible. Pieces already in a good spot stay where they are.
  List<FurnitureModel> suggestLayout({
    required RoomModel room,
    required List<FurnitureModel> items,
    required RecommendationModel recommendation,
  }) {
    final mapper = room.mapper;
    final targets = <String, Compass>{};
    for (var i = 0; i < items.length && i < recommendation.placements.length; i++) {
      final advice = recommendation.placements[i];
      if (advice.verdict == PlacementVerdict.improve && advice.suggestedDirection != null) {
        targets[items[i].localKey] = advice.suggestedDirection!;
      }
    }

    final placed = <FurnitureModel>[
      for (final i in items)
        if (!targets.containsKey(i.localKey)) i,
    ];
    for (final item in items.where((i) => targets.containsKey(i.localKey))) {
      final cell = mapper.cellForDirection(targets[item.localKey]!);
      final cellX = cell.col / 3;
      final cellY = cell.row / 3;
      // Candidate spots: centre of the cell, then its corners, then edges.
      final xs = [cellX + (1 / 3 - item.width) / 2, cellX, cellX + 1 / 3 - item.width];
      final ys = [cellY + (1 / 3 - item.height) / 2, cellY, cellY + 1 / 3 - item.height];
      FurnitureModel? best;
      for (final y in ys) {
        for (final x in xs) {
          final candidate = item.copyWith(
            x: x.clamp(0.0, 1 - item.width),
            y: y.clamp(0.0, 1 - item.height),
          );
          if (overlappingKeys([...placed, candidate]).contains(candidate.localKey)) continue;
          best = candidate;
          break;
        }
        if (best != null) break;
      }
      placed.add(
        best ??
            item.copyWith(
              x: xs.first.clamp(0.0, 1 - item.width),
              y: ys.first.clamp(0.0, 1 - item.height),
            ),
      );
    }
    // Keep the original order so labels and advice still line up.
    final byKey = {for (final p in placed) p.localKey: p};
    return [for (final i in items) byKey[i.localKey]!];
  }

  /// Door opening as a share of the room width.
  ({double start, double end}) _doorRange(RoomModel room) {
    final dw = math.min(3 * room.unit.perFoot, room.width * 0.32) / room.width;
    final start = switch (room.doorPosition) {
      DoorPosition.left => 0.08,
      DoorPosition.center => (1 - dw) / 2,
      DoorPosition.right => 0.92 - dw,
    };
    return (start: start, end: start + dw);
  }

  bool _overlapsDoor(FurnitureModel i, ({double start, double end}) door) =>
      i.x < door.end && i.x + i.width > door.start;

  PlacementAdvice _adviseItem(
    FurnitureModel item,
    RoomModel room,
    BaguaMapper mapper,
    List<Compass> best,
    ({double start, double end}) door,
  ) {
    final rule = _rules[item.type] ?? const _Rule([], '');
    final current = mapper.directionAt(item.centerX, item.centerY);
    final where = current == null ? 'the center' : 'the ${current.label} zone';
    final notes = <String>[];
    var verdict = PlacementVerdict.info;
    Compass? suggested;
    String? spot;

    if (rule.preferred.isNotEmpty) {
      if (current != null && rule.preferred.contains(current)) {
        verdict = PlacementVerdict.good;
        notes.add('${item.label} is in $where, a supportive spot. ${rule.why}');
      } else {
        verdict = PlacementVerdict.improve;
        suggested = rule.preferred.first;
        final cell = mapper.cellForDirection(suggested);
        spot = BaguaMapper.describeCell(cell.col, cell.row);
        notes.add(
          '${item.label} is in $where. Traditional feng shui places a ${item.type.label.toLowerCase()} '
          'in the ${suggested.label} zone, which is $spot in this room. ${rule.why}',
        );
      }
    } else {
      notes.add('${item.label} is in $where. ${rule.why}');
    }

    if (rule.avoidCenter && current == null) {
      verdict = PlacementVerdict.improve;
      notes.add('Keep the center open; it is the room\'s balance point.');
    }

    final backDir = mapper.wallDirection(item.backWall);
    switch (item.type) {
      case FurnitureType.bed:
        if (best.isNotEmpty) {
          final i = best.indexOf(backDir);
          notes.add(
            i >= 0
                ? 'Your head points ${backDir.label}, your ${kuaDirectionLabels[i].toLowerCase()} direction.'
                : 'Your head points ${backDir.label}. If you can, turn the bed so your head points '
                      '${best[1].label} (health) or ${best[0].label} (success).',
          );
          if (i < 0 && verdict == PlacementVerdict.good) verdict = PlacementVerdict.improve;
        }
        if (item.y + item.height > 0.66 && _overlapsDoor(item, door)) {
          verdict = PlacementVerdict.improve;
          notes.add(
            'The bed is in line with the door. Feng shui avoids this; move it out of the door\'s path.',
          );
        }
      case FurnitureType.desk:
        if (best.isNotEmpty) {
          final i = best.indexOf(backDir);
          notes.add(
            i >= 0
                ? 'You face ${backDir.label} at this desk, your ${kuaDirectionLabels[i].toLowerCase()} direction.'
                : 'You face ${backDir.label} at this desk. Facing ${best[0].label} or ${best[1].label} '
                      'suits your Kua number better.',
          );
          if (i < 0 && verdict == PlacementVerdict.good) verdict = PlacementVerdict.improve;
        }
        notes.add(switch (item.backWall) {
          Wall.top =>
            'Your back is to the door. A small mirror on the desk lets you see who comes in.',
          Wall.bottom => 'You face the door, the classic commanding position.',
          _ => 'The door is beside you, which is fine.',
        });
      case FurnitureType.mirror:
        if (item.backWall == Wall.top && _overlapsDoor(item, door)) {
          verdict = PlacementVerdict.improve;
          notes.add(
            'This mirror faces the door, which feng shui says pushes energy back out. Move it to a side wall.',
          );
        }
      default:
        break;
    }

    return PlacementAdvice(
      label: item.label,
      type: item.type,
      currentDirection: current,
      verdict: verdict,
      message: notes.join(' '),
      suggestedDirection: suggested,
      suggestedSpot: spot,
    );
  }

  String _summary(AstrologyResultModel? chart, List<PlacementAdvice> placements) {
    final buf = StringBuffer();
    if (chart != null) {
      buf.write(
        'Your chart leans ${chart.dominantElement.label}, so ${chart.dominantElement.remedy.split(',').first} '
        'will feel familiar. Your quietest element is ${chart.weakestElement.label}'
        '${chart.weakestElement == AstroElement.air ? ' (Metal in feng shui)' : ''}; '
        'adding ${chart.weakestElement.remedy} balances the room.',
      );
    } else {
      buf.write(
        'Add your birth details to personalise these suggestions with your chart and Kua number.',
      );
    }
    if (placements.isEmpty) {
      buf.write(' Place your furniture on the plan to get placement advice.');
    } else {
      final n = placements.where((p) => p.verdict == PlacementVerdict.improve).length;
      buf.write(
        n == 0
            ? ' Every piece already sits in a supportive spot.'
            : ' $n of ${placements.length} pieces could move to a better spot.',
      );
    }
    return buf.toString();
  }

  List<ZoneReading> _zones(
    RoomModel room,
    List<FurnitureModel> items,
    AstrologyResultModel? chart,
  ) {
    final mapper = room.mapper;
    final zones = <ZoneReading>[];
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        final zone = mapper.zoneForCell(room.baguaMethod, col, row);
        final here = items.where((i) {
          if (i.type == FurnitureType.rug) return false;
          final c = BaguaMapper.cellOf(i.centerX, i.centerY);
          return c.col == col && c.row == row;
        }).toList();
        zones.add(
          ZoneReading(
            zone: zone,
            items: here.map((i) => i.label).toList(),
            chartNote: _chartNote(zone, chart),
            hasKeyPiece: here.any(
              (i) => i.type == FurnitureType.desk || i.type == FurnitureType.bed,
            ),
          ),
        );
      }
    }
    return zones;
  }

  String? _chartNote(BaguaZone zone, AstrologyResultModel? chart) {
    if (chart == null) return null;
    if (zone.planet == null) {
      return 'Your quietest element is ${chart.weakestElement.label}. '
          'Bring it in here: ${chart.weakestElement.remedy}.';
    }
    String label;
    String signName;
    if (zone.planet == 'Ascendant' && chart.ascendant != null) {
      label = 'Your rising sign';
      signName = chart.ascendant!;
    } else {
      final p = chart.planet(zone.planet == 'Ascendant' ? 'Sun' : zone.planet!);
      if (p == null) return null;
      label = p.name;
      signName = p.sign;
    }
    final sign = signByName(signName);
    return '$label in ${sign.name}: ${sign.decor}.';
  }

  List<ColorSuggestion> _colors(RoomModel room, AstrologyResultModel? chart) {
    final out = <ColorSuggestion>[];
    if (chart != null) {
      out.add(
        ColorSuggestion(
          name: chart.dominantElement.colors.first,
          reason: 'Feels familiar: your chart leans ${chart.dominantElement.label}.',
        ),
      );
      for (final c in chart.weakestElement.colors.take(2)) {
        out.add(
          ColorSuggestion(
            name: c,
            reason: 'Balances your quiet ${chart.weakestElement.label} element.',
          ),
        );
      }
    }
    final el = _directionElement[room.direction]!;
    out.add(
      ColorSuggestion(
        name: _fengShuiColors[el]!.first,
        reason: 'You face ${room.direction.label} walking in, a ${_cap(el.name)} direction.',
      ),
    );
    return out;
  }

  List<String> _decor(RoomModel room, List<FurnitureModel> items, AstrologyResultModel? chart) {
    final out = <String>[];
    if (chart != null) {
      final sun = signByName(chart.sunSign);
      final moon = signByName(chart.moonSign);
      out.add('For your ${sun.name} Sun: ${sun.decor}.');
      if (moon.name != sun.name) out.add('For comfort (${moon.name} Moon): ${moon.decor}.');
    }
    final occupied = <BaguaZone>{
      for (final i in items)
        if (i.type != FurnitureType.rug) room.mapper.zoneAt(room.baguaMethod, i.centerX, i.centerY),
    };
    final empty = BaguaZone.values.where((z) => z != BaguaZone.center && !occupied.contains(z));
    for (final z in empty.take(2)) {
      out.add('${z.label} zone is empty: ${z.tip}');
    }
    return out;
  }

  List<String> _directionTips(RoomModel room, int? kua, List<Compass> best) {
    final out = <String>[
      'You face ${room.direction.label} as you walk in. The far wall is ${room.direction.label}, '
          'the door wall ${room.mapper.wallDirection(Wall.bottom).label}.',
    ];
    if (kua != null && best.isNotEmpty) {
      out.add(
        'Kua $kua (${isEastGroup(kua) ? 'East' : 'West'} group): '
        '${[for (var i = 0; i < best.length; i++) '${kuaDirectionLabels[i]} ${best[i].label}'].join(', ')}.',
      );
      out.add(
        'Sit facing ${best[0].label} to work, and sleep with your head toward ${best[1].label}.',
      );
    }
    return out;
  }
}
