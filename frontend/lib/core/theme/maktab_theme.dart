import 'package:flutter/material.dart';

import 'maktab_colors.dart';
import 'maktab_spacing.dart';

/// The Maktab design system on top of Material 3. Every screen uses this theme; widgets should read colours and
/// text styles from [Theme.of] rather than hard-coding them.
abstract final class MaktabTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: MaktabColors.teal,
      primary: MaktabColors.teal,
      primaryContainer: const Color(0xFFD7E9E7),
      onPrimaryContainer: MaktabColors.tealDark,
      tertiary: MaktabColors.gold,
      surface: MaktabColors.surface,
      error: MaktabColors.danger,
    );
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final radius = BorderRadius.circular(12);

    return base.copyWith(
      scaffoldBackgroundColor: MaktabColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: MaktabColors.background,
        foregroundColor: MaktabColors.tealDark,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: MaktabColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: MaktabColors.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MaktabColors.surface,
        border: OutlineInputBorder(borderRadius: radius),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: MaktabColors.outline),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: MaktabSpacing.md, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, MaktabSpacing.touchTarget),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, MaktabSpacing.touchTarget),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: MaktabColors.surface,
        indicatorColor: MaktabColors.teal.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: MaktabColors.surface,
        indicatorColor: MaktabColors.teal.withValues(alpha: 0.12),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
