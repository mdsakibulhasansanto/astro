import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../room_planner/views/widgets/furniture_images.dart';
import '../../model/recommendation_model.dart';

/// One furniture rule result: current zone, verdict and suggested zone.
class PlacementTile extends StatelessWidget {
  const PlacementTile({super.key, required this.advice});

  final PlacementAdvice advice;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (color, icon, label) = switch (advice.verdict) {
      PlacementVerdict.good => (c.jade, Icons.check_circle_outline, 'Good spot'),
      PlacementVerdict.improve => (c.brass, Icons.swap_horiz, 'Could improve'),
      PlacementVerdict.info => (c.muted, Icons.info_outline, 'Note'),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: advice.verdict == PlacementVerdict.improve ? c.brass : c.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FurnitureThumb(type: advice.type, size: 30),
              const SizedBox(width: 8),
              Expanded(
                child: Text(advice.label, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Pill(title: 'Current', value: advice.currentLabel, color: c.muted),
              if (advice.suggestedDirection != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward, size: 16, color: c.muted),
                ),
                _Pill(title: 'Suggested', value: advice.suggestedDirection!.label, color: c.jade),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(advice.message, style: const TextStyle(fontSize: 13.5)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.title, required this.value, required this.color});

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTextStyles.overline(context.colors.muted).copyWith(fontSize: 10),
        ),
        Text(value, style: AppTextStyles.mono(13, color)),
      ],
    );
  }
}
