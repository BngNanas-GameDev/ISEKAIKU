import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Halaman dukungan: gambar donasi + QR Trakteer.
class DonatePage extends StatelessWidget {
  const DonatePage({super.key});

  static const String imagePath = 'assets/donate/DOnate.webp';
  static const String qrPath = 'assets/QRCode/qr-code.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Dukung Isekaiku', style: AppTypography.titleLarge),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Isekaiku gratis dan tanpa iklan. Kalau kamu merasa terbantu, '
                'dukunganmu dipakai untuk biaya server dan pengembangan.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.m),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) => const Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.onSurfaceVariant,
                          ),
                          SizedBox(height: AppSpacing.m),
                          Text(
                            'Gambar donasi belum tersedia.',
                            style: AppTypography.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                'Cubit dua jari untuk memperbesar.',
                textAlign: TextAlign.center,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Donasi QRIS',
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: AppSpacing.s),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(AppRadius.l),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Image.asset(
                    qrPath,
                    width: 260,
                    height: 260,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (context, error, stack) => const SizedBox(
                      width: 260,
                      height: 260,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.qr_code_2,
                            size: 56,
                            color: AppColors.outline,
                          ),
                          SizedBox(height: AppSpacing.s),
                          Text(
                            'QR belum tersedia.',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                'Scan QR dengan aplikasi bank atau e-wallet. '
                'Dukungan diproses oleh Trakteer.',
                textAlign: TextAlign.center,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              const SizedBox(height: AppSpacing.m),
              Text(
                'Terima kasih sudah membaca di Isekaiku.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
