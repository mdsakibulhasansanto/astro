import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/section_card.dart';
import '../../model/chart_insights_model.dart';
import 'insight_card.dart';

/// Insights tab: patterns, the core of the chart, life areas and
/// temperament. All text comes from the rule-based insights engine.
class InsightsTab extends StatelessWidget {
  const InsightsTab({super.key, required this.insights});

  final ChartInsights insights;

  static const _coreIcons = <String, IconData>{
    'Core self': Icons.wb_sunny_outlined,
    'Emotional world': Icons.nightlight_outlined,
    'First impression': Icons.visibility_outlined,
    'Chart ruler': Icons.explore_outlined,
    'Moon phase': Icons.brightness_3_outlined,
  };

  static const _areaIcons = <String, IconData>{
    'Love & relationships': Icons.favorite_border,
    'Career & calling': Icons.work_outline,
    'Home & space': Icons.home_outlined,
    'Mind & communication': Icons.chat_bubble_outline,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget gap() => const SizedBox(height: 12);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        if (insights.patterns.isNotEmpty) ...[
          const SectionLabel('Chart patterns'),
          for (final p in insights.patterns) ...[_PatternCard(pattern: p), gap()],
        ],
        const SectionLabel('The core of your chart'),
        for (final card in insights.core) ...[
          InsightCardView(card: card, icon: _coreIcons[card.eyebrow]),
          gap(),
        ],
        const SectionLabel('Life areas'),
        for (final card in insights.lifeAreas) ...[
          InsightCardView(card: card, icon: _areaIcons[card.eyebrow], accent: c.jade),
          gap(),
        ],
        const SectionLabel('Temperament'),
        for (final card in insights.temperament) ...[
          InsightCardView(card: card, icon: Icons.tune, accent: c.water),
          gap(),
        ],
        const SizedBox(height: 4),
        const NoteText(
          'Readings follow traditional Western astrology rules applied to your calculated '
          'chart. They are for reflection and inspiration.',
        ),
      ],
    );
  }
}

class _PatternCard extends StatelessWidget {
  const _PatternCard({required this.pattern});

  final ChartPattern pattern;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.brass.withValues(alpha: 0.14), c.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.brass.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: c.brass),
              const SizedBox(width: 8),
              Expanded(child: Text(pattern.name, style: AppTextStyles.display(20, c.ink))),
            ],
          ),
          const SizedBox(height: 8),
          Text(pattern.body, style: TextStyle(color: c.ink, fontSize: 14.5, height: 1.5)),
          const SizedBox(height: 10),
          KeywordChips(words: pattern.planets),
        ],
      ),
    );
  }
}
