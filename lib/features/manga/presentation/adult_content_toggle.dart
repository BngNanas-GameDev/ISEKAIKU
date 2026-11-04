import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../account/account_providers.dart';
import '../../account/presentation/account_dialog.dart';
import '../data/adult_policy.dart';
import '../manga_providers.dart';

/// Alur bersama untuk menyalakan/mematikan konten 18+.
///
/// Dipakai dari menu Pustaka maupun menu titik tiga di Beranda:
/// 1. wajib login,
/// 2. tanggal lahir (sekali isi) harus 18+,
/// 3. konfirmasi terakhir sebelum diaktifkan.
Future<void> toggleAdultContent(BuildContext context, WidgetRef ref) async {
  final bool active = ref.read(showAdultContentProvider);

  if (active) {
    ref.read(showAdultContentProvider.notifier).disable();
    _invalidateCatalog(ref);
    _snack(context, 'Konten 18+ dimatikan.');
    return;
  }

  if (ref.read(currentUserProvider) == null) {
    final bool signedIn = await _promptLogin(context, ref);
    if (!signedIn || !context.mounted) return;
  }

  final profile = await ref.read(currentProfileProvider.future);
  if (!context.mounted) return;

  final DateTime? birthDate = profile?.birthDate;
  if (birthDate == null) {
    _snack(context, 'Lengkapi tanggal lahir di Profil terlebih dahulu.');
    return;
  }

  if (!AdultPolicy.isAdult(birthDate)) {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: const Text('Belum tersedia', style: AppTypography.titleMedium),
        content: const Text(
          'Fitur ini belum tersedia untuk usia kamu.',
          style: AppTypography.bodySmall,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
    return;
  }

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surfaceContainer,
      title: const Text(
        'Aktifkan konten 18+?',
        style: AppTypography.titleMedium,
      ),
      content: const Text(
        'Judul dengan rating Erotika akan muncul di Beranda, Jelajah, dan '
        'Pencarian. Rating pornografi tetap tidak disediakan.',
        style: AppTypography.bodySmall,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Aktifkan'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  ref.read(showAdultContentProvider.notifier).enable();
  _invalidateCatalog(ref);
  _snack(context, 'Konten 18+ diaktifkan.');
}

Future<bool> _promptLogin(BuildContext context, WidgetRef ref) async {
  final bool? proceed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surfaceContainer,
      title: const Text(
        'Masuk untuk konten 18+',
        style: AppTypography.titleMedium,
      ),
      content: const Text(
        'Konten Erotika hanya tersedia untuk pengguna yang masuk dengan '
        'Google dan sudah mengisi tanggal lahir. '
        'Kamu akan diarahkan untuk mengisi tanggal lahir jika belum ada.',
        style: AppTypography.bodySmall,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Masuk'),
        ),
      ],
    ),
  );

  if (proceed != true || !context.mounted) return false;

  await showAccountDialog(context);
  if (!context.mounted) return false;
  return ref.read(currentUserProvider) != null;
}

void _invalidateCatalog(WidgetRef ref) {
  ref.invalidate(popularMangaProvider);
  ref.invalidate(latestMangaProvider);
  ref.invalidate(browseResultsProvider);
}

void _snack(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
