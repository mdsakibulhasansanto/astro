import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../model/chart_insights_model.dart';

/// One interpretation card: eyebrow, title, body and keyword chips.
class InsightCardView extends StatelessWidget {
  const InsightCardView({super.key, required this.card, this.icon, this.accent});

  final InsightCard card;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = accent ?? c.brass;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 17, color: color),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  card.eyebrow.toUpperCase(),
                  style: AppTextStyles.overline(color).copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(card.title, style: AppTextStyles.display(21, c.ink)),
          const SizedBox(height: 6),
          Text(card.body, style: TextStyle(color: c.ink, fontSize: 14.5, height: 1.5)),
          if (card.tags.isNotEmpty) ...[const SizedBox(height: 12), KeywordChips(words: card.tags)],
        ],
      ),
    );
  }
}

/// Small rounded keyword labels.
class KeywordChips extends StatelessWidget {
  const KeywordChips({super.key, required this.words});

  final List<String> words;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final w in words)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: c.bg,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: c.line),
            ),
            child: Text(
              w,
              style: TextStyle(fontSize: 12, color: c.muted, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

/// Uppercase section heading used between groups of cards.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(text.toUpperCase(), style: AppTextStyles.overline(context.colors.muted)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
