import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../model/legal_documents.dart';

/// Privacy Policy or Terms and Conditions.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isPrivacy = document == LegalDocument.privacy;
    final sections = isPrivacy ? privacySections : termsSections;

    return Scaffold(
      appBar: AppBar(title: Text(isPrivacy ? 'Privacy Policy' : 'Terms & Conditions')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          Text('Last updated $legalUpdated', style: TextStyle(color: c.muted, fontSize: 13)),
          for (final s in sections) ...[
            const SizedBox(height: 22),
            Text(s.heading, style: AppTextStyles.display(20, c.ink)),
            const SizedBox(height: 6),
            Text(s.body, style: const TextStyle(fontSize: 15, height: 1.55)),
          ],
        ],
      ),
    );
  }
}
