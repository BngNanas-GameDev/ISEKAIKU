// Wordmark brand "ISEKAIKU" dengan Asimov Extra Wide.
//
// Desain:
// - ISEKAI = onSurface (#EEEEEE)
// - KU     = primary (#76ABAE)
// Font family AsimovExtraWide, UPPERCASE, letterSpacing ±0.03 em.
//
// Tidak memerlukan file gambar — render murni via Text, tajam di semua DPI.
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'package:flutter/material.dart';

class IsekaikuWordmark extends StatelessWidget {
  final double size;
  final Color? isekaiColor;
  final Color? kuColor;
  final TextAlign textAlign;

  const IsekaikuWordmark({
    super.key,
    this.size = 28.0,
    this.isekaiColor,
    this.kuColor,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final isekai = isekaiColor ?? AppColors.onSurface;
    final ku = kuColor ?? AppColors.primary;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'ISEKAI',
              style: TextStyle(
                fontFamily: AppFonts.asimovExtraWide,
                fontSize: size,
                height: 1.0,
                letterSpacing: size * 0.03,
                color: isekai,
              ),
            ),
            TextSpan(
              text: 'KU',
              style: TextStyle(
                fontFamily: AppFonts.asimovExtraWide,
                fontSize: size,
                height: 1.0,
                letterSpacing: size * 0.03,
                color: ku,
              ),
            ),
          ],
        ),
        textAlign: textAlign,
        softWrap: false,
        overflow: TextOverflow.visible,
      ),
    );
  }

  /// Varian terbalik untuk latar teal (#76ABAE) — teks gelap.
  factory IsekaikuWordmark.inverted({double size = 28.0}) =>
      IsekaikuWordmark(
        size: size,
        isekaiColor: AppColors.onPrimary,
        kuColor: AppColors.onPrimary.withAlpha((0.70 * 255).round()),
      );

  /// Monogram "IK" untuk ikon launcher / favicon.
  static Widget monogram({
    double size = 48.0,
    Color? color,
  }) {
    return Text(
      'IK',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: AppFonts.asimovExtraWide,
        fontSize: size,
        height: 1.0,
        letterSpacing: size * 0.03,
        color: color ?? AppColors.primary,
      ),
    );
  }
}

/// Halaman dev untuk review semua token design system.
class IsekaikuDesignSystemPreview extends StatelessWidget {
  const IsekaikuDesignSystemPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design System'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        bottom: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.l,
            AppSpacing.l,
            AppSpacing.xxxl,
          ),
          children: [
          const Text('Wordmark', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSpacing.m),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Expanded(child: IsekaikuWordmark(size: 40)),
              const SizedBox(width: AppSpacing.l),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.s,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.s),
                  ),
                  child: IsekaikuWordmark.inverted(size: 40),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          const Divider(),
          const Text('Color tokens', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSpacing.m),
          _ColorRow(
            label: 'background',
            color: AppColors.background,
          ),
          _ColorRow(
            label: 'surfaceContainer',
            color: AppColors.surfaceContainer,
          ),
          _ColorRow(
            label: 'primary',
            color: AppColors.primary,
          ),
          _ColorRow(
            label: 'onSurface',
            color: AppColors.onSurface,
          ),
          _ColorRow(
            label: 'onSurfaceVariant',
            color: AppColors.onSurfaceVariant,
          ),
          _ColorRow(
            label: 'primaryContainer',
            color: AppColors.primaryContainer,
          ),
          _ColorRow(
            label: 'error',
            color: AppColors.error,
          ),
          _ColorRow(
            label: 'success',
            color: AppColors.success,
          ),
          _ColorRow(
            label: 'warning',
            color: AppColors.warning,
          ),
          const SizedBox(height: AppSpacing.xxl),
          const Divider(),
          const Text('Typography', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSpacing.m),
          ...[
            ('displaySmall', AppTypography.displaySmall),
            ('headlineMedium', AppTypography.headlineMedium),
            ('headlineSmall', AppTypography.headlineSmall),
            ('titleLarge', AppTypography.titleLarge),
            ('titleMedium', AppTypography.titleMedium),
            ('bodyLarge', AppTypography.bodyLarge),
            ('bodyMedium', AppTypography.bodyMedium),
            ('labelLarge', AppTypography.labelLarge),
            ('labelSmall', AppTypography.labelSmall),
          ].map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.$1,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Text(
                        entry.$2.fontFamily ?? '',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Isekai ku baca manga 147',
                    style: entry.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const Divider(),
          const Text('Buttons', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSpacing.m),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {},
                child: const Text('Elevated'),
              ),
              const SizedBox(height: AppSpacing.m),
              OutlinedButton(
                onPressed: () {},
                child: const Text('Outlined'),
              ),
              const SizedBox(height: AppSpacing.m),
              FilledButton(
                onPressed: () {},
                child: const Text('Filled'),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final String label;
  final Color color;

  const _ColorRow({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.s),
              border: Border.all(color: AppColors.outlineVariant),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Text(label, style: AppTypography.bodyMedium),
          const Spacer(),
          Text(
            '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
