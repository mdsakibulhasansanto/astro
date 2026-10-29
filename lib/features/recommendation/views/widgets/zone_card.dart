import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../model/recommendation_model.dart';

/// One bagua zone: what's in it, what the chart says, and the feng shui tip.
class ZoneCard extends StatelessWidget {
  const ZoneCard({super.key, required this.reading});

  final ZoneReading reading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final z = reading.zone;
    final color = c.forFengShuiElement(z.element);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: reading.hasKeyPiece ? c.brass : c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(z.label, style: AppTextStyles.display(20, c.ink))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: color),
                ),
                child: Text(
                  z.element.name.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .5,
                  ),
                ),
              ),
            ],
          ),
          Text(z.lifeArea, style: TextStyle(color: c.muted, fontSize: 12.5)),
          const SizedBox(height: 8),
          _Field(
            'In your room',
            reading.items.isEmpty ? 'Nothing placed here yet' : reading.items.join(', '),
          ),
          if (reading.chartNote != null) _Field('From your chart', reading.chartNote!),
          _Field('Feng shui', z.tip),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.text);

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.overline(context.colors.muted).copyWith(fontSize: 10.5),
        ),
        const SizedBox(height: 2),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    ),
  );
}
