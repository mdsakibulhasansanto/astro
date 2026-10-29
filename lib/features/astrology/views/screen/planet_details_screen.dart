import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/astro_constants.dart';
import '../../../../core/constants/astro_interpretations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../repository/chart_insights_engine.dart';
import '../../riverpod/astrology_provider.dart';
import '../widgets/aspects_tab.dart';
import '../widgets/insight_card.dart';

/// One planet in depth: placement, dignity, house, aspects and decor.
class PlanetDetailsScreen extends ConsumerWidget {
  const PlanetDetailsScreen({super.key, required this.planetName});

  final String planetName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reading = ref.watch(chartInsightsProvider)?.planets[planetName];
    final c = context.colors;

    if (reading == null) {
      return Scaffold(
        appBar: AppBar(title: Text(planetName)),
        body: const ErrorView(message: 'This planet is not in your chart yet.'),
      );
    }

    final planet = reading.planet;
    final sign = signByName(planet.sign);
    final elementColor = c.forAstroElement(sign.element);
    final house = planet.house == null ? null : houseMeanings[planet.house];

    return Scaffold(
      appBar: AppBar(title: Text(planet.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          SectionCard(
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: elementColor.withValues(alpha: 0.12),
                    border: Border.all(color: elementColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    planet.symbol + AppTextStyles.textVariation,
                    style: AppTextStyles.symbol(34, c.ink),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reading.title, style: AppTextStyles.display(22, c.ink)),
                      const SizedBox(height: 6),
                      Text(
                        '${formatSignDegree(planet.longitude)} ${sign.name}'
                        '${planet.retrograde && !planet.isNode ? ' · Retrograde' : ''}'
                        '${planet.speed != null && !planet.isNode ? ' · ${planet.speed!.abs().toStringAsFixed(2)}°/day' : ''}',
                        style: AppTextStyles.mono(12.5, c.muted),
                      ),
                      const SizedBox(height: 8),
                      KeywordChips(words: reading.keywords),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Reading',
            child: Text(reading.body, style: const TextStyle(fontSize: 15, height: 1.55)),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'What ${planet.name} governs',
            child: Text(planetMeanings[planet.name] ?? ''),
          ),
          if (!planet.isNode) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: 'Dignity · ${reading.dignity.label}',
              highlight: reading.dignity != Dignity.peregrine,
              child: Text(reading.dignity.meaning),
            ),
          ],
          if (house != null) ...[
            const SizedBox(height: 16),
            SectionCard(
              title: '${ordinal(planet.house!)} house · ${house.title}',
              child: Text('This house covers ${house.area}.'),
            ),
          ],
          SectionLabel('Aspects · ${reading.aspects.length}'),
          if (reading.aspects.isEmpty)
            Text('No major aspects to ${planet.name}.', style: TextStyle(color: c.muted))
          else
            for (final a in reading.aspects) AspectTile(reading: a),
          const SizedBox(height: 6),
          SectionCard(
            title: '${sign.name} at home',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Decor that suits ${sign.name}: ${sign.decor}.'),
                const SizedBox(height: 8),
                Text(
                  'To bring in ${sign.element.label}: ${sign.element.remedy}.',
                  style: TextStyle(color: c.muted, fontSize: 13.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
