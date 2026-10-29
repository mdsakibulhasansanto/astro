import 'dart:convert';
import 'dart:io';

import 'package:astro_home/features/astrology/model/aspect_model.dart';
import 'package:astro_home/features/astrology/model/astrology_result_model.dart';
import 'package:astro_home/features/daily_reading/model/daily_reading_model.dart';
import 'package:astro_home/features/daily_reading/repository/daily_insight_engine.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map<String, dynamic>;

void main() {
  // Real output of the daily-reading logic for 29 Oct 2026 against the
  // chart_with_time fixture.
  final day = DailyReadingModel.fromJson(_json('daily_reading'));
  final natal = AstrologyResultModel.fromJson(_json('chart_with_time'));
  const engine = DailyInsightEngine();

  test('parses the stored reading', () {
    expect(day.date, DateTime(2026, 10, 29));
    expect(day.moonSign, 'Gemini');
    expect(day.transits, isNotEmpty);
    expect(day.transits.first.orb, lessThanOrEqualTo(day.transits.last.orb));
    expect(day.retrogrades, contains('Mercury'));
    expect(day.planetSigns['Sun'], 'Scorpio');
  });

  test('builds a headline from the tightest transit, plus Moon and tip', () {
    final i = engine.build(day, natal: natal);
    final top = day.transits.first;
    expect(i.headline, contains(top.transit));
    expect(i.headline, contains(top.natal));
    expect(i.moonText, contains('Gemini'));
    expect(i.transitTexts.length, lessThanOrEqualTo(4));
    expect(i.transitTexts.first.$2, contains("Today's ${top.transit}"));
    expect(i.retrogradeText, contains('Mercury'));
    // Air Moon tip, plus the chart's weakest element (Fire).
    expect(i.designTip, contains('Air the room'));
    expect(i.designTip, contains('Fire'));
    for (final (_, body) in i.transitTexts) {
      expect(body, isNot(contains('null')));
    }
  });

  test('works without a birth chart and with no transits', () {
    final quiet = DailyReadingModel(
      date: DateTime(2026, 1, 1),
      moonSign: 'Taurus',
      moonPhase: 'Full Moon',
      illumination: 1,
      transits: const [],
      retrogrades: const [],
      planetSigns: const {},
    );
    final i = engine.build(quiet);
    expect(i.headline, contains('Moon in Taurus'));
    expect(i.retrogradeText, isNull);
    expect(i.designTip, contains('plant'));
    expect(AspectType.trine.harmonious, isTrue);
  });
}
