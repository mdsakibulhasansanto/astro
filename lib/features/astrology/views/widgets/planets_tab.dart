import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/astro_constants.dart';
import '../../../../core/constants/astro_interpretations.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../model/astrology_result_model.dart';
import '../../model/chart_insights_model.dart';
import '../../repository/chart_insights_engine.dart';
import 'insight_card.dart';

/// Planets tab: every planet with sign, degree, house, motion and dignity.
class PlanetsTab extends StatelessWidget {
  const PlanetsTab({super.key, required this.result, required this.insights});

  final AstrologyResultModel result;
  final ChartInsights insights;

  @override
  Widget build(BuildContext context) {
    final personal = ['Sun', 'Moon', 'Mercury', 'Venus', 'Mars'];
    final social = ['Jupiter', 'Saturn'];
    final outer = ['Uranus', 'Neptune', 'Pluto', 'North Node'];
    List<PlanetReading> pick(List<String> names) => [for (final n in names) ?insights.planets[n]];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        const SectionLabel('Personal planets'),
        for (final r in pick(personal)) _PlanetTile(reading: r),
        const SectionLabel('Social planets'),
        for (final r in pick(social)) _PlanetTile(reading: r),
        const SectionLabel('Generational & node'),
        for (final r in pick(outer)) _PlanetTile(reading: r),
      ],
    );
  }
}

class _PlanetTile extends StatelessWidget {
  const _PlanetTile({required this.reading});

  final PlanetReading reading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = reading.planet;
    final sign = signByName(p.sign);
    final elementColor = c.forAstroElement(sign.element);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.goNamed(RouteNames.planetDetails, pathParameters: {'name': p.name}),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: elementColor.withValues(alpha: 0.12),
                    border: Border.all(color: elementColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    p.symbol + AppTextStyles.textVariation,
                    style: AppTextStyles.symbol(21, c.ink),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(p.name, style: AppTextStyles.display(19, c.ink))),
                          Text(
                            sign.symbol + AppTextStyles.textVariation,
                            style: AppTextStyles.symbol(15, elementColor),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${formatSignDegree(p.longitude)} ${sign.short}',
                            style: AppTextStyles.mono(12.5, c.muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _Badge(p.sign, color: elementColor),
                          if (p.house != null) _Badge('${ordinal(p.house!)} house'),
                          if (p.retrograde && !p.isNode) _Badge('Retrograde ℞', color: c.fire),
                          if (reading.dignity != Dignity.peregrine)
                            _Badge(
                              reading.dignity.label,
                              color: switch (reading.dignity) {
                                Dignity.domicile || Dignity.exaltation => c.jade,
                                _ => c.fire,
                              },
                            ),
                          if (reading.aspects.isNotEmpty)
                            _Badge('${reading.aspects.length} aspects'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reading.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.muted, fontSize: 13.5, height: 1.45),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: c.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, {this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final col = color ?? c.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: col.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color ?? c.ink),
      ),
    );
  }
}
