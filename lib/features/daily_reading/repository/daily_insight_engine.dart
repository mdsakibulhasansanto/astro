import '../../../core/constants/astro_constants.dart';
import '../../../core/constants/astro_interpretations.dart';
import '../../astrology/model/aspect_model.dart';
import '../../astrology/model/astrology_result_model.dart';
import '../model/daily_reading_model.dart';

/// Readable text for a daily reading. Rule-based and deterministic.
class DailyInsight {
  const DailyInsight({
    required this.headline,
    required this.moonText,
    required this.transitTexts,
    required this.retrogradeText,
    required this.designTip,
    required this.focusWords,
  });

  final String headline;
  final String moonText;

  /// (title, body) for the strongest transits.
  final List<(String, String)> transitTexts;
  final String? retrogradeText;
  final String designTip;
  final List<String> focusWords;
}

/// Mood of the Moon's element for the day.
const _moonMoods = <AstroElement, String>{
  AstroElement.fire: 'energy runs high: a good day to start things and move your body',
  AstroElement.earth: 'a grounded, practical mood favours finishing tasks and tidying up',
  AstroElement.air: 'ideas and conversation flow: share plans and connect with people',
  AstroElement.water: 'feelings run deep: rest, cook something warm and stay close to home',
};

/// Space tips for the Moon's element.
const _spaceTips = <AstroElement, String>{
  AstroElement.fire: 'Open the curtains early and add a warm lamp or candle to your main room.',
  AstroElement.earth: 'Clear one surface completely and add a plant or a stone object to it.',
  AstroElement.air: 'Air the room for ten minutes and rearrange a shelf so it can breathe.',
  AstroElement.water: 'Soften the room: a throw, a bowl of water or a mirror catching light.',
};

class DailyInsightEngine {
  const DailyInsightEngine();

  DailyInsight build(DailyReadingModel day, {AstrologyResultModel? natal}) {
    final moon = signByName(day.moonSign);
    final moonProfile = signProfiles[day.moonSign]!;

    final transits = <(String, String)>[];
    for (final t in day.transits.take(4)) {
      final fa = (planetFunctions[t.transit]?.short ?? t.transit).replaceFirst('your ', '');
      final fb = planetFunctions[t.natal]?.short ?? 'your ${t.natal}';
      transits.add((
        '${t.transit} ${t.type.label.toLowerCase()} your ${t.natal}',
        "Today's ${t.transit} ($fa) and $fb ${aspectMeanings[t.type.name]}. ${_advice(t)}",
      ));
    }

    final retro = day.retrogrades.where((r) => const ['Mercury', 'Venus', 'Mars'].contains(r));
    final retroText = retro.isEmpty
        ? null
        : '${retro.join(' and ')} ${retro.length == 1 ? 'is' : 'are'} retrograde: a time to review '
                  'rather than launch. ${retro.contains('Mercury') ? 'Double-check messages, plans and purchases.' : ''}'
              .trim();

    final weakest = natal?.weakestElement;
    final tip = [
      _spaceTips[moon.element]!,
      if (weakest != null && weakest != moon.element)
        'Your chart is low in ${weakest.label}; ${weakest.remedy.split(',').first} helps too.',
    ].join(' ');

    final strongest = day.transits.isEmpty ? null : day.transits.first;
    final headline = strongest == null
        ? 'Moon in ${day.moonSign}: ${moonProfile.keywords.first.toLowerCase()} day'
        : '${strongest.transit} ${_verb(strongest.type)} your ${strongest.natal}';

    return DailyInsight(
      headline: headline,
      moonText:
          'The Moon is in ${day.moonSign} (${day.moonPhase.toLowerCase()}, '
          '${(day.illumination * 100).round()}% lit): ${_moonMoods[moon.element]}.',
      transitTexts: transits,
      retrogradeText: retroText,
      designTip: tip,
      focusWords: moonProfile.keywords,
    );
  }

  String _verb(AspectType t) => switch (t) {
    AspectType.conjunction => 'meets',
    AspectType.sextile => 'supports',
    AspectType.square => 'challenges',
    AspectType.trine => 'flows with',
    AspectType.opposition => 'faces',
  };

  String _advice(TransitModel t) => switch (t.type.harmonious) {
    true => 'Use the easy flow: it is a good moment to act on this.',
    false => 'Expect some friction; go slowly and it turns into progress.',
    null => 'This theme is front and centre today.',
  };
}
