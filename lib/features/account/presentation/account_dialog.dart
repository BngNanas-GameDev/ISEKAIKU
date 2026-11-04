import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

Future<void> showAccountDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const AccountDialog(),
  );
}

/// Dialog akun: masuk dengan Google, atau status akun + keluar.
class AccountDialog extends ConsumerStatefulWidget {
  const AccountDialog({super.key});

  @override
  ConsumerState<AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends ConsumerState<AccountDialog> {
  bool _loading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final launched = await ref.read(authServiceProvider).signInWithGoogle();
      if (!launched && mounted) {
        setState(() => _error = 'Tidak bisa membuka halaman login Google.');
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Tidak bisa terhubung ke server.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _loading = true);
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return AlertDialog(
      backgroundColor: AppColors.surfaceContainer,
      title: Text(
        user == null ? 'Akun Isekaiku' : 'Akun',
        style: AppTypography.titleMedium,
      ),
      content: SizedBox(
        width: 380,
        child: user == null ? _buildSignedOut() : _buildSignedIn(user),
      ),
      actions: user == null ? _buildSignedOutActions() : _buildSignedInActions(),
    );
  }

  Widget _buildSignedOut() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Masuk dengan Google untuk menyinkronkan Pustaka dan riwayat baca '
          'antar perangkat. Tanpa akun, semua fitur baca tetap berjalan.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _loading ? null : _signInWithGoogle,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.account_circle_outlined, size: 18),
            label: Text(_loading ? 'Membuka…' : 'Masuk dengan Google'),
          ),
        ),
        if (_error != null) ...<Widget>[
          const SizedBox(height: AppSpacing.m),
          Text(
            _error!,
            style: AppTypography.labelSmall.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }

  Widget _buildSignedIn(User user) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          user.email ?? 'Tanpa email',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          'Pustaka akan disinkronkan otomatis setiap kali kamu masuk.',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSignedOutActions() {
    return <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Tutup'),
      ),
    ];
  }

  List<Widget> _buildSignedInActions() {
    return <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Tutup'),
      ),
      FilledButton(
        onPressed: _loading ? null : _signOut,
        child: const Text('Keluar'),
      ),
    ];
  }
}
