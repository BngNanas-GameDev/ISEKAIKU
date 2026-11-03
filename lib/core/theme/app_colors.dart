// Palet mentah dari Color Hunt: #222831 • #31363F • #76ABAE • #EEEEEE
// Semantik diperluas untuk dark-only theme.
import 'package:flutter/material.dart';

abstract class AppColors {
  // ---------- Dasar ----------
  static const Color background = Color(0xFF222831);
  static const Color surfaceContainerLowest = Color(0xFF1B1F26);
  static const Color surfaceContainerLow = Color(0xFF292E37);
  static const Color surfaceContainer = Color(0xFF31363F);
  static const Color surfaceContainerHigh = Color(0xFF3A4049);
  static const Color surfaceContainerHighest = Color(0xFF444B55);

  // ---------- Aksen ----------
  static const Color primary = Color(0xFF76ABAE);
  static const Color onPrimary = Color(0xFF222831);
  static const Color primaryContainer = Color(0xFF2F5356);
  static const Color onPrimaryContainer = Color(0xFFC9E9EA);

  // ---------- Teks ----------
  static const Color onSurface = Color(0xFFEEEEEE);
  static const Color onSurfaceVariant = Color(0xFFB4B9BE);

  // ---------- Border / divider ----------
  static const Color outline = Color(0xFF5B626C);
  static const Color outlineVariant = Color(0xFF3D434C);

  // ---------- Status ----------
  static const Color error = Color(0xFFF2B8B5);
  static const Color success = Color(0xFF8FC9A0);
  static const Color warning = Color(0xFFE3C08A);

  // ---------- Khusus area ----------
  static const Color readerBg = Color(0xFF1B1F26);
  static const Color playerBg = Color(0xFF0E1114);
}

extension AppColorScheme on ColorScheme {
  Color get readerBg => AppColors.readerBg;
  Color get playerBg => AppColors.playerBg;
}
