import 'package:flutter/material.dart';

import 'maktab_colors.dart';
import 'maktab_spacing.dart';

/// The Maktab design system on top of Material 3. Every screen uses this theme; widgets should read colours and
/// text styles from [Theme.of] rather than hard-coding them.
abstract final class MaktabTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: MaktabColors.primary,
      primary: MaktabColors.primary,
      primaryContainer: MaktabColors.primaryContainer,
      onPrimaryContainer: MaktabColors.primaryDark,
      secondaryContainer: MaktabColors.primaryContainer,
      onSecondaryContainer: MaktabColors.primaryDark,
      tertiary: MaktabColors.gold,
      tertiaryContainer: MaktabColors.warningContainer,
      onTertiaryContainer: const Color(0xFF8A4600),
      surface: MaktabColors.surface,
      outlineVariant: MaktabColors.outline,
      error: MaktabColors.danger,
      errorContainer: MaktabColors.dangerContainer,
    );
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final radius = BorderRadius.circular(10);
    final text = base.textTheme.copyWith(
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: MaktabColors.primaryDark,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: MaktabColors.background,
      dividerTheme: const DividerThemeData(color: MaktabColors.outline, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: MaktabColors.background,
        foregroundColor: MaktabColors.primaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(color: MaktabColors.primaryDark, fontSize: 22),
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
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: MaktabColors.primary, width: 1.5),
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
          side: const BorderSide(color: MaktabColors.outline),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: MaktabColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: MaktabColors.outline),
        selectedColor: MaktabColors.primaryContainer,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: MaktabColors.primaryContainer,
          selectedForegroundColor: MaktabColors.primaryDark,
          side: const BorderSide(color: MaktabColors.outline),
        ),
      ),
      listTileTheme: const ListTileThemeData(iconColor: MaktabColors.primary),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: MaktabColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: MaktabColors.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
