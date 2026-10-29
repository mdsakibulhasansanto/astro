import 'package:astro_home/core/constants/feng_shui_constants.dart';
import 'package:astro_home/core/constants/furniture_catalog.dart';
import 'package:astro_home/core/theme/app_colors.dart';
import 'package:astro_home/features/room_planner/model/furniture_model.dart';
import 'package:astro_home/features/room_planner/model/room_model.dart';
import 'package:astro_home/features/room_planner/views/widgets/room_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the plan and reports drags in relative units', (tester) async {
    String? selected;
    double totalDx = 0;
    const room = RoomModel(id: 'r1', homeId: 'h1', roomName: 'Bedroom', width: 12, height: 10);
    const bed = FurnitureModel(
      localKey: 'bed',
      roomId: 'r1',
      type: FurnitureType.bed,
      label: 'Bed',
      x: 0.3,
      y: 0.3,
      width: 0.4,
      height: 0.4,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppColors.light]),
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: RoomCanvas(
              room: room,
              items: const [bed],
              highlightDirections: const [Compass.n, Compass.se],
              onSelect: (k) => selected = k,
              onMove: (_, dx, _) => totalDx += dx,
              onResize: (_, _, _) {},
            ),
          ),
        ),
      ),
    );

    // Pieces are drawn as pictures; the name shows only when selected.
    expect(find.bySemanticsLabel('Bed'), findsOneWidget);
    await tester.drag(find.byKey(const ValueKey('bed')), const Offset(60, 0));
    expect(selected, 'bed');
    // 60 px across a room drawn ~300 px wide is a sizeable share of it.
    expect(totalDx, greaterThan(0.1));
    expect(totalDx, lessThan(0.3));
    expect(tester.takeException(), isNull);
  });
}
