import 'app_colors.dart';
import 'app_fonts.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'package:flutter/material.dart';

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color readerBg;
  final Color playerBg;
  final Color success;
  final Color warning;

  const AppThemeExtension({
    required this.readerBg,
    required this.playerBg,
    required this.success,
    required this.warning,
  });

  @override
  AppThemeExtension copyWith({
    Color? readerBg,
    Color? playerBg,
    Color? success,
    Color? warning,
  }) {
    return AppThemeExtension(
      readerBg: readerBg ?? this.readerBg,
      playerBg: playerBg ?? this.playerBg,
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      readerBg: Color.lerp(readerBg, other.readerBg, t) ?? readerBg,
      playerBg: Color.lerp(playerBg, other.playerBg, t) ?? playerBg,
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
    );
  }
}

ThemeData appDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
  ).copyWith(
    surface: AppColors.background,
    onSurface: AppColors.onSurface,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    outlineVariant: AppColors.outlineVariant,
    error: AppColors.error,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    dividerColor: AppColors.outlineVariant,

    textTheme: const TextTheme(
      displaySmall: AppTypography.displaySmall,
      headlineMedium: AppTypography.headlineMedium,
      headlineSmall: AppTypography.headlineSmall,
      titleLarge: AppTypography.titleLarge,
      titleMedium: AppTypography.titleMedium,
      bodyLarge: AppTypography.bodyLarge,
      bodyMedium: AppTypography.bodyMedium,
      bodySmall: AppTypography.bodySmall,
      labelLarge: AppTypography.labelLarge,
      labelSmall: AppTypography.labelSmall,
    ).apply(
      bodyColor: AppColors.onSurface,
      displayColor: AppColors.onSurface,
    ),

    primaryTextTheme: const TextTheme(
      bodyLarge: AppTypography.bodyLarge,
      bodyMedium: AppTypography.bodyMedium,
      labelLarge: AppTypography.labelLarge,
      labelSmall: AppTypography.labelSmall,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        textStyle: AppTypography.labelLarge.copyWith(
          fontFamily: AppFonts.asimovWide,
        ),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.l),
        ),
        elevation: 0,
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        textStyle: AppTypography.labelLarge.copyWith(
          fontFamily: AppFonts.asimovWide,
        ),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.l),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.onSurface,
        side: const BorderSide(color: AppColors.outline),
        textStyle: AppTypography.labelLarge.copyWith(
          fontFamily: AppFonts.asimovWide,
        ),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.l),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceContainerHigh,
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.onSurfaceVariant,
      ),
      labelStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.onSurfaceVariant,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceContainerHigh,
      selectedColor: AppColors.primary.withAlpha((0.24 * 255).round()),
      disabledColor: AppColors.surfaceContainerHigh,
      labelStyle: AppTypography.labelSmall.copyWith(
        color: AppColors.onSurfaceVariant,
      ),
      secondaryLabelStyle: AppTypography.labelSmall.copyWith(
        color: AppColors.onSurface,
      ),
      brightness: Brightness.dark,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceContainerLow,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.l),
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.l),
      ),
      margin: const EdgeInsets.all(0),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.outlineVariant,
      space: 1,
      thickness: 1,
    ),

    extensions: [
      AppThemeExtension(
        readerBg: AppColors.readerBg,
        playerBg: AppColors.playerBg,
        success: AppColors.success,
        warning: AppColors.warning,
      ),
    ],
  );
}
