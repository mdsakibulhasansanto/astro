import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Bordered surface panel with an optional uppercase heading.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    required this.child,
    this.highlight = false,
    this.padding = const EdgeInsets.all(16),
  });

  final String? title;
  final Widget child;

  /// Draws a brass border to call attention to this card.
  final bool highlight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: highlight ? c.brass : c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!.toUpperCase(), style: AppTextStyles.overline(c.muted)),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }
}

/// Muted note with a brass rule on the left.
class NoteText extends StatelessWidget {
  const NoteText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.only(left: 10, top: 2, bottom: 2),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: c.brass, width: 2)),
      ),
      child: Text(text, style: TextStyle(color: c.muted, fontSize: 13.5)),
    );
  }
}
