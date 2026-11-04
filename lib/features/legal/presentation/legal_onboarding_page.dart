import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../legal_content.dart';
import '../legal_providers.dart';
import 'legal_pages.dart';

/// Gerbang persetujuan syarat & kebijakan privasi saat pertama membuka app.
class LegalOnboardingPage extends ConsumerStatefulWidget {
  const LegalOnboardingPage({super.key});

  @override
  ConsumerState<LegalOnboardingPage> createState() =>
      _LegalOnboardingPageState();
}

class _LegalOnboardingPageState extends ConsumerState<LegalOnboardingPage> {
  bool _agreed = false;

  void _open(LegalDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => LegalDocumentPage(document: document),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          children: <Widget>[
            const SizedBox(height: AppSpacing.l),
            Text(
              'ISEKAIKU',
              style: AppTypography.displaySmall.copyWith(
                color: AppColors.primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text('Sebelum mulai', style: AppTypography.headlineSmall),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Baca ringkasannya dulu. Kamu bisa membuka dokumen lengkap '
              'kapan saja dari tab Akun.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.l),
            _LegalTile(
              icon: Icons.description_outlined,
              title: LegalContent.terms.title,
              subtitle: 'Aturan penggunaan, forum, dan konten 18+',
              onTap: () => _open(LegalContent.terms),
            ),
            _LegalTile(
              icon: Icons.privacy_tip_outlined,
              title: LegalContent.privacy.title,
              subtitle: 'Data apa yang diproses dan hak kamu',
              onTap: () => _open(LegalContent.privacy),
            ),
            const SizedBox(height: AppSpacing.l),
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadius.m),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Ringkasan', style: AppTypography.labelLarge),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    '• Aplikasi untuk usia 13 tahun ke atas.\n'
                    '• Tanggal lahir diisi sekali setelah login dan tidak '
                    'bisa diubah.\n'
                    '• Sebagian fitur dibatasi berdasarkan usia.\n'
                    '• Forum dimoderasi: tanpa konten seksual eksplisit, '
                    'judi, narkoba, atau tautan spam.\n'
                    '• Pustaka bisa dipakai tanpa akun; sinkronisasi opsional.',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            CheckboxListTile(
              value: _agreed,
              onChanged: (value) => setState(() => _agreed = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primary,
              title: Text(
                'Saya sudah membaca dan menyetujui Syarat Layanan serta '
                'Kebijakan Privasi.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            FilledButton(
              onPressed: _agreed
                  ? () => ref.read(legalAcceptedProvider.notifier).accept()
                  : null,
              child: const Text('Setuju & Lanjut'),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Kamu bisa berhenti memakai aplikasi kapan saja. Penolakan '
              'berarti aplikasi tidak dapat digunakan.',
              textAlign: TextAlign.center,
              style: AppTypography.labelSmall,
            ),
            const SizedBox(height: AppSpacing.l),
          ],
        ),
      ),
    );
  }
}

class _LegalTile extends StatelessWidget {
  const _LegalTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceContainer,
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: AppTypography.bodyMedium),
        subtitle: Text(subtitle, style: AppTypography.labelSmall),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
