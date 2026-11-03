import 'app_colors.dart';
import 'app_fonts.dart';
import 'package:flutter/material.dart';

abstract class AppTypography {
  // Display — Asimov Extra Wide
  static const TextStyle displaySmall = TextStyle(
    fontFamily: AppFonts.asimovExtraWide,
    fontSize: 36.0,
    height: 1.22,
    letterSpacing: 0.02,
    color: AppColors.onSurface,
  );

  // Headline — Asimov Wide
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: AppFonts.asimovWide,
    fontSize: 28.0,
    height: 1.21,
    color: AppColors.onSurface,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: AppFonts.asimovWide,
    fontSize: 24.0,
    height: 1.25,
    color: AppColors.onSurface,
  );

  // Title — Asimov Wide / Asimov
  static const TextStyle titleLarge = TextStyle(
    fontFamily: AppFonts.asimovWide,
    fontSize: 20.0,
    height: 1.30,
    color: AppColors.onSurface,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: AppFonts.asimov,
    fontSize: 16.0,
    height: 1.38,
    color: AppColors.onSurface,
  );

  // Body — Asimov
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: AppFonts.asimov,
    fontSize: 16.0,
    height: 1.62,
    color: AppColors.onSurface,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: AppFonts.asimov,
    fontSize: 14.0,
    height: 1.57,
    color: AppColors.onSurface,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: AppFonts.asimov,
    fontSize: 12.0,
    height: 1.50,
    color: AppColors.onSurfaceVariant,
  );

  // Label — AsimovWide / AsimovNarrow (no synthetic bold)
  static const TextStyle labelLarge = TextStyle(
    fontFamily: AppFonts.asimovWide,
    fontSize: 14.0,
    height: 1.29,
    letterSpacing: 0.4,
    color: AppColors.onSurface,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: AppFonts.asimovNarrow,
    fontSize: 12.0,
    height: 1.33,
    color: AppColors.onSurfaceVariant,
  );
}

extension AppThemeText on TextTheme {
  TextStyle get displaySmall => AppTypography.displaySmall;
  TextStyle get headlineMedium => AppTypography.headlineMedium;
  TextStyle get headlineSmall => AppTypography.headlineSmall;
  TextStyle get titleLarge => AppTypography.titleLarge;
  TextStyle get titleMedium => AppTypography.titleMedium;
  TextStyle get bodyLarge => AppTypography.bodyLarge;
  TextStyle get bodyMedium => AppTypography.bodyMedium;
  TextStyle get bodySmall => AppTypography.bodySmall;
  TextStyle get labelLarge => AppTypography.labelLarge;
  TextStyle get labelSmall => AppTypography.labelSmall;
}
