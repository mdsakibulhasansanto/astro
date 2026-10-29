import 'package:flutter/material.dart';

import '../../../../core/constants/feng_shui_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/section_card.dart';

/// Kua number, East/West group and the four supportive directions.
class KuaCard extends StatelessWidget {
  const KuaCard({super.key, required this.kua});

  final int kua;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dirs = kuaBestDirections[kua] ?? const [];
    return SectionCard(
      title: 'Feng shui Kua number',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kua $kua · ${isEastGroup(kua) ? 'East' : 'West'} group',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Your four supportive directions. Face one of these at your desk, '
            'or point your head toward one in bed.',
            style: TextStyle(color: c.muted, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < dirs.length; i++)
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < dirs.length - 1 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: c.line),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(dirs[i].code, style: AppTextStyles.mono(17, c.jade)),
                        Text(
                          kuaDirectionLabels[i],
                          style: TextStyle(fontSize: 11.5, color: c.muted),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
