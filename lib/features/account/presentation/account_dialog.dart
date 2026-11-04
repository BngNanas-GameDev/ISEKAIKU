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

/// Dialog akun: masuk/daftar, atau status akun + keluar.
class AccountDialog extends ConsumerStatefulWidget {
  const AccountDialog({super.key});

  @override
  ConsumerState<AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends ConsumerState<AccountDialog> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _loading = false;
  bool _signUp = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.length < 6) {
      setState(() => _error = 'Email wajib diisi dan password minimal 6 karakter.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = ref.read(authServiceProvider);
    try {
      if (_signUp) {
        await auth.signUp(email: email, password: password);
      } else {
        await auth.signIn(email: email, password: password);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_signUp ? 'Akun dibuat.' : 'Berhasil masuk.'),
          ),
        );
    } on AuthException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Tidak bisa terhubung ke server.');
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
        child: user == null ? _buildForm() : _buildSignedIn(user),
      ),
      actions: user == null ? _buildFormActions() : _buildSignedInActions(),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Akun dipakai untuk menyinkronkan Pustaka antar perangkat. '
          'Tanpa akun, semua fitur baca tetap berjalan.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const <String>[AutofillHints.email],
          style: AppTypography.bodyMedium,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.alternate_email, size: 18),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        TextField(
          controller: _password,
          obscureText: true,
          autofillHints: const <String>[AutofillHints.password],
          style: AppTypography.bodyMedium,
          onSubmitted: (_) => _loading ? null : _submit(),
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline, size: 18),
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
          'Sinkronisasi akan tersedia pada langkah berikutnya.',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFormActions() {
    return <Widget>[
      TextButton(
        onPressed: _loading
            ? null
            : () => setState(() {
                  _signUp = !_signUp;
                  _error = null;
                }),
        child: Text(_signUp ? 'Sudah punya akun?' : 'Buat akun baru'),
      ),
      FilledButton(
        onPressed: _loading ? null : _submit,
        child: _loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(_signUp ? 'Daftar' : 'Masuk'),
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
