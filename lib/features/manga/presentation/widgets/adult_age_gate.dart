import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/adult_policy.dart';

/// Gerbang usia untuk konten Erotika.
///
/// Memakai input tanggal lahir bebas (tidak diisi otomatis), sesuai panduan
/// *neutral age screen* Google Play. Tanggal lahir tidak disimpan; hanya
/// status verifikasi yang disimpan (lihat `AdultContentNotifier`).
Future<bool> showAdultAgeGate(BuildContext context) async {
  final bool? result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AdultAgeGateDialog(),
  );
  return result == true;
}

class AdultAgeGateDialog extends StatefulWidget {
  const AdultAgeGateDialog({super.key});

  @override
  State<AdultAgeGateDialog> createState() => _AdultAgeGateDialogState();
}

class _AdultAgeGateDialogState extends State<AdultAgeGateDialog> {
  final TextEditingController _day = TextEditingController();
  final TextEditingController _month = TextEditingController();
  final TextEditingController _year = TextEditingController();

  String? _error;

  @override
  void dispose() {
    _day.dispose();
    _month.dispose();
    _year.dispose();
    super.dispose();
  }

  void _verify() {
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

    if (!AdultPolicy.isAdult(birth)) {
      setState(
        () => _error =
            'Usia belum ${AdultPolicy.minimumAge} tahun. '
            'Konten ini tidak dapat diaktifkan.',
      );
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceContainer,
      title: const Text('Verifikasi usia', style: AppTypography.titleMedium),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(28),
                borderRadius: BorderRadius.circular(AppRadius.s),
                border: Border.all(color: AppColors.error.withAlpha(90)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      'Konten Erotika hanya untuk usia '
                      '${AdultPolicy.minimumAge} tahun ke atas. '
                      'Judul dengan rating pornografi tetap tidak disediakan.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Text('Tanggal lahir', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.s),
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
            const SizedBox(height: AppSpacing.s),
            Text(
              'Tanggal lahir tidak disimpan. Hanya status verifikasi yang '
              'tersimpan di perangkat dan berlaku 30 hari.',
              style: AppTypography.labelSmall,
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: AppSpacing.m),
              Text(
                _error!,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _verify, child: const Text('Verifikasi')),
      ],
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
