import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../legal_content.dart';

Future<void> showAboutAppDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const AboutAppDialog(),
  );
}

/// Info aplikasi: versi, sumber data, lisensi, dan kontak.
class AboutAppDialog extends StatelessWidget {
  const AboutAppDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceContainer,
      title: const Text('Info aplikasi', style: AppTypography.titleMedium),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Isekaiku', style: AppTypography.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Versi ${AppConfig.appVersion}',
                style: AppTypography.labelSmall,
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                'Pembaca manga lokal-first. Katalog dan gambar berasal dari '
                'MangaDex melalui API resmi; Isekaiku tidak meng-host konten.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.l),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.public,
                  color: AppColors.onSurfaceVariant,
                ),
                title: Text(
                  'Sumber data: MangaDex',
                  style: AppTypography.bodyMedium,
                ),
                subtitle: Text(
                  'mangadex.org • penggunaan non-komersial',
                  style: AppTypography.labelSmall,
                ),
                trailing: const Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: AppColors.onSurfaceVariant,
                ),
                onTap: () => _open(context, 'https://mangadex.org'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.code,
                  color: AppColors.onSurfaceVariant,
                ),
                title: Text(
                  'Lisensi open source',
                  style: AppTypography.bodyMedium,
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.onSurfaceVariant,
                ),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Isekaiku',
                  applicationVersion: AppConfig.appVersion,
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.bug_report_outlined,
                  color: AppColors.onSurfaceVariant,
                ),
                title: Text(
                  'Laporkan masalah / kontak',
                  style: AppTypography.bodyMedium,
                ),
                trailing: const Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: AppColors.onSurfaceVariant,
                ),
                onTap: () => _open(context, LegalContent.contactUrl),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Tidak bisa membuka tautan.')),
        );
    }
  }
}
