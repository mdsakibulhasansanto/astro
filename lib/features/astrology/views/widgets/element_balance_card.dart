import 'package:flutter/material.dart';

import '../../../../core/constants/astro_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/section_card.dart';
import '../../model/astrology_result_model.dart';

/// Element (Fire, Earth, Air, Water) and modality (Cardinal, Fixed,
/// Mutable) balance as bars.
class ElementBalanceCard extends StatelessWidget {
  const ElementBalanceCard({super.key, required this.result});

  final AstrologyResultModel result;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SectionCard(
      title: 'Balance',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in AstroElement.values)
            _Bar(
              label: e.displayLabel,
              value: result.elementBalance[e] ?? 0,
              color: c.forAstroElement(e),
            ),
          if (result.modalityBalance.isNotEmpty) ...[
            const SizedBox(height: 8),
            Divider(color: c.line),
            const SizedBox(height: 8),
            for (final m in Modality.values)
              _Bar(
                label: m.name[0].toUpperCase() + m.name.substring(1),
                value: result.modalityBalance[m] ?? 0,
                color: c.ink.withValues(alpha: 0.7),
              ),
          ],
          const SizedBox(height: 4),
          Text(
            'Weighted toward Sun, Moon and Rising. Your chart leans '
            '${result.dominantElement.label}; ${result.weakestElement.label} is quietest, '
            'so your home can supply it.',
            style: TextStyle(color: c.muted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: '$label $value percent',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(width: 96, child: Text(label, style: const TextStyle(fontSize: 13.5))),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value / 100,
                  minHeight: 8,
                  backgroundColor: c.bg,
                  color: color,
                ),
              ),
            ),
            SizedBox(
              width: 42,
              child: Text(
                '$value%',
                textAlign: TextAlign.right,
                style: AppTextStyles.mono(12, c.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
