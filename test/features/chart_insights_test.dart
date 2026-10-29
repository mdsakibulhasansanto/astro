import 'dart:convert';
import 'dart:io';

import 'package:astro_home/core/constants/astro_interpretations.dart';
import 'package:astro_home/features/astrology/model/aspect_model.dart';
import 'package:astro_home/features/astrology/model/astrology_result_model.dart';
import 'package:astro_home/features/astrology/repository/chart_insights_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixtures are real output of supabase/functions/astrology-chart/chart.ts.
/// chart_with_time: 1 Jul 1961, 19:45, Sandringham (a well-documented chart).
AstrologyResultModel _load(String name) => AstrologyResultModel.fromJson(
  jsonDecode(File('test/fixtures/$name.json').readAsStringSync()) as Map<String, dynamic>,
);

void main() {
  const engine = ChartInsightsEngine();

  group('chart model', () {
    test('parses houses, aspects, modalities and Moon phase', () {
      final c = _load('chart_with_time');
      expect(c.isAdvanced, isTrue);
      expect(c.hasHouses, isTrue);
      expect(c.houseSystem, 'placidus');
      expect(c.ascendant, 'Sagittarius');
      expect(c.mcLongitude, closeTo(203.05, 0.1)); // 23°03′ Libra
      expect(c.planet('Sun')!.house, 7);
      expect(c.planet('Moon')!.house, 2);
      expect(c.planet('North Node')!.sign, 'Leo');
      expect(c.mainPlanets, hasLength(10));
      expect(c.aspects, isNotEmpty);
      expect(c.modalityBalance.values.reduce((a, b) => a + b), inInclusiveRange(98, 102));
      expect(c.moonPhase!.name, 'Waning Gibbous');
    });

    test('chart without a birth time has no houses or rising sign', () {
      final c = _load('chart_without_time');
      expect(c.ascendant, isNull);
      expect(c.hasHouses, isFalse);
      expect(c.planets.every((p) => p.house == null), isTrue);
      expect(c.aspects.any((a) => a.involves('Ascendant')), isFalse);
    });
  });

  group('dignities', () {
    test('follow the traditional tables', () {
      expect(dignityOf('Saturn', 'Capricorn'), Dignity.domicile);
      expect(dignityOf('Venus', 'Taurus'), Dignity.domicile);
      expect(dignityOf('Sun', 'Aries'), Dignity.exaltation);
      expect(dignityOf('Moon', 'Capricorn'), Dignity.detriment);
      expect(dignityOf('Mars', 'Cancer'), Dignity.fall);
      expect(dignityOf('Mars', 'Virgo'), Dignity.peregrine);
    });
  });

  group('insights', () {
    test('finds the Moon–Uranus–Venus T-square', () {
      final patterns = engine.findPatterns(_load('chart_with_time'));
      final t = patterns.where((p) => p.name == 'T-square').toList();
      expect(t, isNotEmpty);
      expect(t.first.planets.toSet(), {'Moon', 'Uranus', 'Venus'});
      expect(t.first.planets.last, 'Venus'); // the apex
    });

    test('fills core, life-area and temperament cards', () {
      final i = engine.build(_load('chart_with_time'));
      expect(i.core.map((c) => c.eyebrow), [
        'Core self',
        'Emotional world',
        'First impression',
        'Chart ruler',
        'Moon phase',
      ]);
      // Sagittarius rising: Jupiter rules the chart.
      expect(i.core[3].title, startsWith('Jupiter in Aquarius'));
      expect(i.lifeAreas.map((c) => c.eyebrow), contains('Career & calling'));
      expect(i.lifeAreas.map((c) => c.eyebrow), contains('Home & space'));
      expect(i.temperament.map((c) => c.eyebrow), contains('Hemispheres'));
      expect(i.planets.keys, containsAll(['Sun', 'Moon', 'Pluto', 'North Node']));
      expect(i.planets['Saturn']!.dignity, Dignity.domicile);
      expect(i.planets['Sun']!.title, 'Sun in Cancer, 7th house');
      for (final card in [...i.core, ...i.lifeAreas, ...i.temperament]) {
        expect(card.body.trim(), isNotEmpty);
        expect(card.body, isNot(contains('null')));
        expect(card.body, isNot(contains('..')));
      }
    });

    test('aspect readings describe both planets', () {
      final i = engine.build(_load('chart_with_time'));
      final sq = i.aspects.firstWhere(
        (r) =>
            r.aspect.type == AspectType.square &&
            r.aspect.involves('Venus') &&
            r.aspect.involves('Moon'),
      );
      expect(sq.title, 'Moon square Venus');
      expect(sq.body, contains('Your feelings'));
      expect(sq.body, contains('your love'));
      expect(sq.body, contains('friction'));
    });

    test('without a birth time it asks for one instead of guessing', () {
      final i = engine.build(_load('chart_without_time'));
      expect(i.core.any((c) => c.title == 'Rising sign unknown'), isTrue);
      expect(i.lifeAreas.any((c) => c.eyebrow == 'Career & calling'), isFalse);
      expect(i.temperament.any((c) => c.eyebrow == 'Hemispheres'), isFalse);
    });

    test('is deterministic', () {
      final a = engine.build(_load('chart_with_time'));
      final b = engine.build(_load('chart_with_time'));
      expect(a.core.map((c) => c.body), b.core.map((c) => c.body));
    });
  });
}
