import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../legal_content.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalDocumentPage(document: LegalContent.terms);
  }
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalDocumentPage(document: LegalContent.privacy);
  }
}

/// Halaman dokumen legal (syarat atau kebijakan privasi).
class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(document.title, style: AppTypography.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: <Widget>[
          Text(
            'Terakhir diperbarui: ${document.updated}',
            style: AppTypography.labelSmall,
          ),
          const SizedBox(height: AppSpacing.l),
          for (final LegalSection section in document.sections) ...<Widget>[
            Text(section.title, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            SelectableText(
              section.body,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
          ],
          const SizedBox(height: AppSpacing.l),
          Text(
            '${LegalContent.appName} • Versi dokumen ${LegalContent.version}',
            style: AppTypography.labelSmall,
          ),
        ],
      ),
    );
  }
}
