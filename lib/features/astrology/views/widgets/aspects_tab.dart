import 'package:flutter/material.dart';

import '../../../../core/constants/astro_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../model/aspect_model.dart';
import '../../model/astrology_result_model.dart';
import '../../model/chart_insights_model.dart';
import 'insight_card.dart';

/// Aspects tab: the aspect grid and a reading for each aspect.
class AspectsTab extends StatefulWidget {
  const AspectsTab({super.key, required this.result, required this.insights});

  final AstrologyResultModel result;
  final ChartInsights insights;

  @override
  State<AspectsTab> createState() => _AspectsTabState();
}

enum _Filter { all, harmonious, challenging }

class _AspectsTabState extends State<AspectsTab> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final readings = widget.insights.aspects.where((r) {
      final h = r.aspect.type.harmonious;
      return switch (_filter) {
        _Filter.all => true,
        _Filter.harmonious => h == true,
        _Filter.challenging => h == false,
      };
    }).toList();

    if (widget.result.aspects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No major aspects found.', style: TextStyle(color: c.muted)),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        const SectionLabel('Aspect grid'),
        _AspectGrid(result: widget.result),
        SectionLabel('Aspects · ${readings.length}'),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<_Filter>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: const [
              ButtonSegment(value: _Filter.all, label: Text('All')),
              ButtonSegment(value: _Filter.harmonious, label: Text('Easy')),
              ButtonSegment(value: _Filter.challenging, label: Text('Tense')),
            ],
            selected: {_filter},
            onSelectionChanged: (s) => setState(() => _filter = s.first),
          ),
        ),
        const SizedBox(height: 12),
        for (final r in readings) AspectTile(reading: r),
      ],
    );
  }
}

Color aspectColor(AppColors c, AspectType t) => switch (t.harmonious) {
  true => c.water,
  false => c.fire,
  null => c.brass,
};

/// One aspect: symbol, the two points, orb strength and its reading.
class AspectTile extends StatelessWidget {
  const AspectTile({super.key, required this.reading});

  final AspectReading reading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final a = reading.aspect;
    final color = aspectColor(c, a.type);
    String glyph(String name) => switch (name) {
      'Ascendant' => 'AC',
      'Midheaven' => 'MC',
      _ => (planetSymbols[name] ?? name) + AppTextStyles.textVariation,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line),
      ),
      // The coloured stripe marks the aspect's nature (easy, tense, neutral).
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(glyph(a.a), style: AppTextStyles.symbol(17, c.ink)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            a.type.symbol + AppTextStyles.textVariation,
                            style: AppTextStyles.symbol(17, color),
                          ),
                        ),
                        Text(glyph(a.b), style: AppTextStyles.symbol(17, c.ink)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            reading.title,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                          ),
                        ),
                        _StrengthDots(strength: a.strength, color: color),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reading.body,
                      style: TextStyle(color: c.ink, fontSize: 13.5, height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StrengthDots extends StatelessWidget {
  const _StrengthDots({required this.strength, required this.color});

  final int strength;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Strength $strength of 3',
    child: Row(
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(left: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < strength ? color : context.colors.line,
            ),
          ),
      ],
    ),
  );
}

/// Triangular grid: one cell per pair of points, showing the aspect glyph.
class _AspectGrid extends StatelessWidget {
  const _AspectGrid({required this.result});

  final AstrologyResultModel result;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final names = [
      ...result.mainPlanets.map((p) => p.name),
      if (result.ascendantLongitude != null) 'Ascendant',
      if (result.mcLongitude != null) 'Midheaven',
    ];
    AspectModel? find(String a, String b) {
      for (final x in result.aspects) {
        if ((x.a == a && x.b == b) || (x.a == b && x.b == a)) return x;
      }
      return null;
    }

    String label(String n) => switch (n) {
      'Ascendant' => 'AC',
      'Midheaven' => 'MC',
      _ => (planetSymbols[n] ?? n) + AppTextStyles.textVariation,
    };

    return LayoutBuilder(
      builder: (context, cons) {
        final cell = ((cons.maxWidth - 2) / (names.length + 1)).clamp(20.0, 34.0);
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.line),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var row = 1; row < names.length; row++)
                  Row(
                    children: [
                      for (var col = 0; col < row; col++)
                        _GridCell(size: cell, aspect: find(names[row], names[col])),
                      SizedBox(
                        width: cell,
                        height: cell,
                        child: Center(
                          child: Text(label(names[row]), style: AppTextStyles.symbol(13, c.ink)),
                        ),
                      ),
                    ],
                  ),
                Row(
                  children: [
                    for (var col = 0; col < names.length - 1; col++)
                      SizedBox(
                        width: cell,
                        height: cell,
                        child: Center(
                          child: Text(label(names[col]), style: AppTextStyles.symbol(13, c.muted)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({required this.size, required this.aspect});

  final double size;
  final AspectModel? aspect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final a = aspect;
    final color = a == null ? c.line : aspectColor(c, a.type);
    return Tooltip(
      message: a == null
          ? ''
          : '${a.a} ${a.type.label.toLowerCase()} ${a.b} · orb ${a.orb.toStringAsFixed(1)}°',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: a == null ? null : color.withValues(alpha: 0.12),
          border: Border.all(color: c.line, width: 0.5),
        ),
        alignment: Alignment.center,
        child: a == null
            ? null
            : Text(
                a.type.symbol + AppTextStyles.textVariation,
                style: AppTextStyles.symbol(size * 0.5, color),
              ),
      ),
    );
  }
}
