import 'dart:convert';
import 'dart:io';

import 'package:astro_home/core/theme/app_colors.dart';
import 'package:astro_home/features/astrology/model/astrology_result_model.dart';
import 'package:astro_home/features/astrology/repository/chart_insights_engine.dart';
import 'package:astro_home/features/astrology/views/widgets/aspects_tab.dart';
import 'package:astro_home/features/astrology/views/widgets/chart_wheel.dart';
import 'package:astro_home/features/astrology/views/widgets/insights_tab.dart';
import 'package:astro_home/features/astrology/views/widgets/planets_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

AstrologyResultModel _load(String name) => AstrologyResultModel.fromJson(
  jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map<String, dynamic>,
);

Widget _host(Widget child) => MaterialApp(
  theme: ThemeData(extensions: const [AppColors.light]),
  home: Scaffold(body: SizedBox(width: 390, height: 800, child: child)),
);

void main() {
  // Tests run offline: draw text with the fallback font.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final chart = _load('chart_with_time');
  final insights = const ChartInsightsEngine().build(chart);

  testWidgets('chart wheel paints with houses and aspects', (tester) async {
    await tester.pumpWidget(_host(Center(child: ChartWheel(result: chart))));
    expect(find.byType(ChartWheel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('planets tab lists every planet with badges', (tester) async {
    await tester.pumpWidget(_host(PlanetsTab(result: chart, insights: insights)));
    expect(find.text('Sun'), findsOneWidget);
    expect(find.text('7th house'), findsWidgets);
    // Saturn in Capricorn is at home in its own sign.
    await tester.scrollUntilVisible(find.text('Saturn'), 300);
    expect(find.text('Domicile'), findsWidgets);
    await tester.scrollUntilVisible(find.text('North Node'), 300);
    expect(find.text('North Node'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('aspects tab shows grid and filters', (tester) async {
    await tester.pumpWidget(_host(AspectsTab(result: chart, insights: insights)));
    final list = find.byType(Scrollable).first; // the vertical list, not the grid
    await tester.scrollUntilVisible(find.text('Moon square Venus'), 300, scrollable: list);
    expect(find.text('Moon square Venus'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Easy'), -300, scrollable: list);
    await tester.tap(find.text('Easy'));
    await tester.pumpAndSettle();
    expect(find.text('Moon square Venus'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('insights tab shows the T-square pattern first', (tester) async {
    await tester.pumpWidget(_host(InsightsTab(insights: insights)));
    expect(find.text('T-square'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Sun in Cancer'), 300);
    expect(find.text('Sun in Cancer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
