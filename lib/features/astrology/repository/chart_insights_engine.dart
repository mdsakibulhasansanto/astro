import '../../../core/constants/astro_constants.dart';
import '../../../core/constants/astro_interpretations.dart';
import '../model/aspect_model.dart';
import '../model/astrology_result_model.dart';
import '../model/chart_insights_model.dart';

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String ordinal(int n) {
  if (n >= 11 && n <= 13) return '${n}th';
  return switch (n % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th',
  };
}

const _outer = {'Uranus', 'Neptune', 'Pluto'};

/// The first [n] sentences of [text], ending with a full stop.
String _firstSentences(String text, int n) {
  final parts = text.split('. ');
  final out = parts.take(n).join('. ');
  return out.endsWith('.') ? out : '$out.';
}

/// Turns a calculated chart into readable insights using fixed
/// interpretation rules. Deterministic: same chart, same text.
class ChartInsightsEngine {
  const ChartInsightsEngine();

  ChartInsights build(AstrologyResultModel chart) {
    final aspectReadings = chart.aspects.map(_aspectReading).toList();
    final planets = <String, PlanetReading>{
      for (final p in chart.planets)
        p.name: _planetReading(p, aspectReadings.where((r) => r.aspect.involves(p.name)).toList()),
    };
    return ChartInsights(
      core: _core(chart, planets),
      lifeAreas: _lifeAreas(chart, planets),
      temperament: _temperament(chart),
      planets: planets,
      aspects: aspectReadings,
      patterns: findPatterns(chart),
    );
  }

  // ---------------------------------------------------------------- planets

  String _placementText(PlanetPosition p) {
    final s = signProfiles[p.sign]!;
    return switch (p.name) {
      'Sun' =>
        'Your core identity grows through ${s.needs}. You shine ${s.style}, and your gift '
            'is ${s.gift}. Watch for ${s.shadow} when you feel unseen.',
      'Moon' =>
        'You feel emotionally safe with ${s.needs}. You process feelings ${s.style}; at your '
            'best you offer ${s.gift}, and under stress ${s.shadow} can surface.',
      'Mercury' =>
        'You think and communicate ${s.style}. Your mind is drawn to ${s.needs}, and its '
            'gift is ${s.gift}.',
      'Venus' =>
        'In love and taste you are drawn to ${s.needs}. You show affection ${s.style}, and '
            'your gift in relationships is ${s.gift}.',
      'Mars' =>
        'You go after what you want ${s.style}, energised by ${s.needs}. Under pressure, '
            '${s.shadow} can show.',
      'Jupiter' =>
        'Growth and good fortune come through ${s.needs}. You expand your world ${s.style}.',
      'Saturn' =>
        'Your long-term lessons involve ${s.needs}. Maturity comes from working '
            '${s.style} and from handling ${s.shadow}.',
      'North Node' => 'Your path of growth points toward ${s.needs}, developing ${s.gift}.',
      _ =>
        '${p.name} in ${p.sign} is shared by your whole generation: a collective '
            '${planetFunctions[p.name]!.keyword.toLowerCase()} expressed ${s.style}.',
    };
  }

  PlanetReading _planetReading(PlanetPosition p, List<AspectReading> aspects) {
    final dignity = p.isNode ? Dignity.peregrine : dignityOf(p.name, p.sign);
    final parts = <String>[_placementText(p)];
    if (p.house != null) {
      final h = houseMeanings[p.house]!;
      parts.add(
        _outer.contains(p.name)
            ? 'In your ${ordinal(p.house!)} house it becomes personal, stirring ${h.area}.'
            : 'In the ${ordinal(p.house!)} house, this plays out through ${h.area}.',
      );
    }
    if (p.retrograde && !p.isNode) {
      parts.add('Retrograde at birth: its themes turn inward and mature through reflection.');
    }
    if (dignity != Dignity.peregrine) parts.add('${dignity.label}: ${dignity.meaning}');

    return PlanetReading(
      planet: p,
      dignity: dignity,
      title: '${p.name} in ${p.sign}${p.house != null ? ', ${ordinal(p.house!)} house' : ''}',
      body: parts.join(' '),
      keywords: signProfiles[p.sign]!.keywords,
      aspects: aspects,
    );
  }

  AspectReading _aspectReading(AspectModel a) {
    final fa = planetFunctions[a.a]?.short ?? a.a;
    final fb = planetFunctions[a.b]?.short ?? a.b;
    final timing = a.applying == null ? '' : (a.applying! ? ', applying' : ', separating');
    return AspectReading(
      aspect: a,
      title: '${a.a} ${a.type.label.toLowerCase()} ${a.b}',
      body:
          '${_cap(fa)} and $fb ${aspectMeanings[a.type.name]}. '
          'Orb ${a.orb.toStringAsFixed(1)}°$timing.',
    );
  }

  // -------------------------------------------------------------- patterns

  /// Stelliums, grand trines and T-squares among the ten planets.
  List<ChartPattern> findPatterns(AstrologyResultModel chart) {
    final out = <ChartPattern>[];
    final planets = chart.mainPlanets;

    // Stellium: three or more planets in one sign, or one house.
    final bySign = <String, List<String>>{};
    final byHouse = <int, List<String>>{};
    for (final p in planets) {
      (bySign[p.sign] ??= []).add(p.name);
      if (p.house != null) (byHouse[p.house!] ??= []).add(p.name);
    }
    bySign.forEach((sign, names) {
      if (names.length >= 3) {
        final s = signProfiles[sign]!;
        out.add(
          ChartPattern(
            name: 'Stellium in $sign',
            planets: names,
            body:
                '${names.join(', ')} gather in $sign. Its themes, '
                '${s.keywords.map((k) => k.toLowerCase()).join(', ')}, are a major focus of your life.',
          ),
        );
      }
    });
    byHouse.forEach((house, names) {
      if (names.length >= 3) {
        out.add(
          ChartPattern(
            name: 'Stellium in the ${ordinal(house)} house',
            planets: names,
            body:
                '${names.join(', ')} share the ${ordinal(house)} house, putting strong '
                'emphasis on ${houseMeanings[house]!.area}.',
          ),
        );
      }
    });

    bool has(String a, String b, AspectType t) =>
        chart.aspects.any((x) => x.type == t && ((x.a == a && x.b == b) || (x.a == b && x.b == a)));
    final names = planets.map((p) => p.name).toList();

    // Grand trine: three planets all trine each other.
    for (var i = 0; i < names.length; i++) {
      for (var j = i + 1; j < names.length; j++) {
        if (!has(names[i], names[j], AspectType.trine)) continue;
        for (var k = j + 1; k < names.length; k++) {
          if (has(names[i], names[k], AspectType.trine) &&
              has(names[j], names[k], AspectType.trine)) {
            final element = signByName(chart.planet(names[i])!.sign).element.label;
            out.add(
              ChartPattern(
                name: 'Grand trine',
                planets: [names[i], names[j], names[k]],
                body:
                    '${names[i]}, ${names[j]} and ${names[k]} form a triangle of easy flow, '
                    'mostly in $element signs. A natural gift that works best when you use it on purpose.',
              ),
            );
          }
        }
      }
    }

    // T-square: an opposition with a third planet square to both ends.
    for (final opp in chart.aspects.where((x) => x.type == AspectType.opposition)) {
      if (!names.contains(opp.a) || !names.contains(opp.b)) continue;
      for (final apex in names) {
        if (apex == opp.a || apex == opp.b) continue;
        if (has(apex, opp.a, AspectType.square) && has(apex, opp.b, AspectType.square)) {
          out.add(
            ChartPattern(
              name: 'T-square',
              planets: [opp.a, opp.b, apex],
              body:
                  '${opp.a} opposes ${opp.b}, and both square $apex. This tension drives '
                  'ambition: ${planetFunctions[apex]!.short} is where you learn to resolve it.',
            ),
          );
        }
      }
    }
    return out;
  }

  // ------------------------------------------------------------- core cards

  List<InsightCard> _core(AstrologyResultModel chart, Map<String, PlanetReading> planets) {
    final cards = <InsightCard>[
      InsightCard(
        eyebrow: 'Core self',
        title: 'Sun in ${chart.sunSign}',
        body: planets['Sun']!.body,
        tags: signProfiles[chart.sunSign]!.keywords,
      ),
      InsightCard(
        eyebrow: 'Emotional world',
        title: 'Moon in ${chart.moonSign}',
        body: planets['Moon']!.body,
        tags: signProfiles[chart.moonSign]!.keywords,
      ),
    ];
    final asc = chart.ascendant;
    if (asc != null) {
      final s = signProfiles[asc]!;
      cards.add(
        InsightCard(
          eyebrow: 'First impression',
          title: '$asc rising',
          body:
              'With $asc rising you meet the world ${s.style}. People first notice your '
              '${s.keywords.map((k) => k.toLowerCase()).join(', ')} side, and new situations '
              'call out your ${s.gift}.',
          tags: s.keywords,
        ),
      );
      final rulerName = s.ruler;
      final ruler = chart.planet(rulerName);
      if (ruler != null) {
        cards.add(
          InsightCard(
            eyebrow: 'Chart ruler',
            title: '$rulerName in ${ruler.sign}',
            body:
                '$rulerName rules your $asc Ascendant, so it steers the whole chart. Placed in '
                '${ruler.sign}${ruler.house != null ? ' in the ${ordinal(ruler.house!)} house' : ''}, '
                'it points your life energy toward '
                '${ruler.house != null ? houseMeanings[ruler.house]!.area : signProfiles[ruler.sign]!.needs}.',
          ),
        );
      }
    } else {
      cards.add(
        const InsightCard(
          eyebrow: 'First impression',
          title: 'Rising sign unknown',
          body:
              'Your rising sign, houses and chart ruler need an exact birth time. Add it in '
              'your birth details to unlock them.',
        ),
      );
    }
    final phase = chart.moonPhase;
    if (phase != null) {
      cards.add(
        InsightCard(
          eyebrow: 'Moon phase',
          title: phase.name,
          body:
              '${moonPhaseMeanings[phase.name] ?? ''} The Moon was '
              '${(phase.illumination * 100).round()}% lit.',
        ),
      );
    }
    return cards;
  }

  // ------------------------------------------------------------ life areas

  List<InsightCard> _lifeAreas(AstrologyResultModel chart, Map<String, PlanetReading> planets) {
    HouseCusp? cusp(int n) {
      for (final h in chart.houses) {
        if (h.number == n) return h;
      }
      return null;
    }

    final cards = <InsightCard>[];

    // Love: Venus, plus the sign on the 7th house.
    final venus = chart.planet('Venus')!;
    final seventh = cusp(7);
    cards.add(
      InsightCard(
        eyebrow: 'Love & relationships',
        title: 'Venus in ${venus.sign}',
        body: [
          _firstSentences(planets['Venus']!.body, 2),
          if (seventh != null)
            '${seventh.sign} on your 7th house draws you to partners who are '
                '${signProfiles[seventh.sign]!.keywords.map((k) => k.toLowerCase()).join(', ')}.',
        ].join(' '),
      ),
    );

    // Career: the Midheaven sign, plus Saturn.
    final mc = chart.mcLongitude;
    if (mc != null) {
      final sign = signOfLongitude(mc).name;
      final s = signProfiles[sign]!;
      final saturn = chart.planet('Saturn')!;
      cards.add(
        InsightCard(
          eyebrow: 'Career & calling',
          title: '$sign Midheaven',
          body:
              'With $sign at the top of your chart, you thrive in work where you act '
              '${s.style} and find ${s.needs}. Saturn in ${saturn.sign}'
              '${saturn.house != null ? ' (${ordinal(saturn.house!)} house)' : ''} shows where '
              'steady effort pays off over time.',
          tags: s.keywords,
        ),
      );
    }

    // Home: the 4th house sign and the Moon, which links to room planning.
    final fourth = cusp(4);
    final moon = chart.planet('Moon')!;
    final homeSign = fourth?.sign ?? moon.sign;
    cards.add(
      InsightCard(
        eyebrow: 'Home & space',
        title: fourth != null ? '$homeSign on the 4th house' : 'Moon in ${moon.sign}',
        body:
            'At home you need ${signProfiles[homeSign]!.needs}. Decor that suits you: '
            '${signByName(homeSign).decor}. Your Moon in ${moon.sign} adds a wish for '
            '${signProfiles[moon.sign]!.needs}.',
        tags: signProfiles[homeSign]!.keywords,
      ),
    );

    // Mind: Mercury.
    final mercury = chart.planet('Mercury')!;
    cards.add(
      InsightCard(
        eyebrow: 'Mind & communication',
        title: 'Mercury in ${mercury.sign}',
        body: planets['Mercury']!.body,
      ),
    );
    return cards;
  }

  // ----------------------------------------------------------- temperament

  List<InsightCard> _temperament(AstrologyResultModel chart) {
    final cards = <InsightCard>[
      InsightCard(
        eyebrow: 'Element balance',
        title: '${chart.dominantElement.label}-led chart',
        body:
            '${elementTemperaments[chart.dominantElement.label]} ${chart.weakestElement.label} is '
            'your quietest element; bringing it into your space and habits helps you feel balanced.',
      ),
    ];
    if (chart.modalityBalance.isNotEmpty) {
      final top = chart.modalityBalance.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      final label = _cap(top.name);
      cards.add(
        InsightCard(eyebrow: 'Modality', title: '$label emphasis', body: modalityStyles[label]!),
      );
    }
    if (chart.hasHouses) {
      final placed = chart.mainPlanets.where((p) => p.house != null).toList();
      final above = placed.where((p) => p.house! >= 7).length;
      final east = placed.where((p) => p.house! >= 10 || p.house! <= 3).length;
      final vertical = above >= 6
          ? 'Most planets sit above the horizon: you are drawn to public life and the wider world.'
          : (placed.length - above >= 6
                ? 'Most planets sit below the horizon: private life, home and inner growth come first.'
                : 'Your planets are spread above and below the horizon: public and private life are balanced.');
      final horizontal = east >= 6
          ? 'An eastern emphasis makes you self-directed: you like to shape your own path.'
          : (placed.length - east >= 6
                ? 'A western emphasis makes you relationship-oriented: you grow through others.'
                : 'You balance independence with cooperation.');
      cards.add(
        InsightCard(
          eyebrow: 'Hemispheres',
          title: 'Where your planets gather',
          body: '$vertical $horizontal',
        ),
      );
    }
    return cards;
  }
}
