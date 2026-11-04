import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../manga/data/adult_policy.dart';
import '../../manga/manga_providers.dart';
import '../account_providers.dart';

/// Formulir tanggal lahir: diisi sekali setelah login, tidak bisa diubah.
///
/// Teks sengaja netral: hanya menjelaskan penyesuaian pengalaman sesuai
/// usia, tanpa menyebut jenis konten apa pun.
class BirthDatePage extends ConsumerStatefulWidget {
  const BirthDatePage({super.key});

  @override
  ConsumerState<BirthDatePage> createState() => _BirthDatePageState();
}

class _BirthDatePageState extends ConsumerState<BirthDatePage> {
  final TextEditingController _day = TextEditingController();
  final TextEditingController _month = TextEditingController();
  final TextEditingController _year = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _day.dispose();
    _month.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final int? day = int.tryParse(_day.text.trim());
    final int? month = int.tryParse(_month.text.trim());
    final int? year = int.tryParse(_year.text.trim());

    if (day == null || month == null || year == null) {
      setState(() => _error = 'Isi tanggal, bulan, dan tahun lahir.');
      return;
    }

    final DateTime? birth = AdultPolicy.birthDate(day, month, year);
    if (birth == null) {
      setState(() => _error = 'Tanggal lahir tidak valid.');
      return;
    }

    if (!AdultPolicy.canUseApp(birth)) {
      setState(
        () => _error =
            'Aplikasi ini untuk usia ${AdultPolicy.appMinimumAge} tahun ke atas.',
      );
      return;
    }

    final String? userId = ref.read(currentUserProvider)?.id;
    if (userId == null) {
      setState(() => _error = 'Sesi login berakhir.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(accountRepositoryProvider).updateBirthDate(userId, birth);

      // Usia di bawah 18: pastikan akses 18+ tidak tertinggal aktif.
      if (!AdultPolicy.isAdult(birth)) {
        ref.read(showAdultContentProvider.notifier).disable();
      }

      ref.invalidate(currentProfileProvider);
    } on PostgrestException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Tidak bisa menyimpan. Periksa koneksi.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Tanggal lahir', style: AppTypography.titleLarge),
        actions: <Widget>[
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: _saving ? null : _signOut,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        children: <Widget>[
          const Icon(Icons.cake_outlined, size: 48, color: AppColors.primary),
          const SizedBox(height: AppSpacing.l),
          Text('Lengkapi profil', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Masukkan tanggal lahir untuk menyesuaikan pengalaman aplikasi '
            'dengan usiamu.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.l),
          Row(
            children: <Widget>[
              Expanded(
                child: _NumberField(
                  controller: _day,
                  label: 'Tgl',
                  maxLength: 2,
                  autofocus: true,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: _NumberField(
                  controller: _month,
                  label: 'Bln',
                  maxLength: 2,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                flex: 2,
                child: _NumberField(
                  controller: _year,
                  label: 'Tahun',
                  maxLength: 4,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.s),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    'Tanggal lahir hanya bisa diisi sekali dan tidak dapat '
                    'diubah setelah disimpan.',
                    style: AppTypography.labelSmall,
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: AppSpacing.m),
            Text(
              _error!,
              style: AppTypography.labelSmall.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.l),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.maxLength,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final int maxLength;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLength),
      ],
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        isDense: true,
      ),
    );
  }
}
