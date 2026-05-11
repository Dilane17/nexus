import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'app_shapes.dart';

/// ThemeData final de l'application Nexus.
/// Combine la palette, la typographie, et les formes dans un MaterialTheme 3.
class NexusTheme {
  NexusTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    // Bien que colorSchemeSeed soit pratique, on surcharge avec nos couleurs exactes :
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: NexusColors.primary,
      onPrimary: NexusColors.onPrimary,
      primaryContainer: NexusColors.primaryContainer,
      onPrimaryContainer: NexusColors.onPrimaryContainer,
      secondary: NexusColors.secondary,
      onSecondary: NexusColors.onSecondary,
      secondaryContainer: NexusColors.secondaryContainer,
      onSecondaryContainer: NexusColors.onSecondaryContainer,
      tertiary: NexusColors.tertiary,
      onTertiary: NexusColors.onTertiary,
      tertiaryContainer: NexusColors.tertiaryContainer,
      onTertiaryContainer: NexusColors.onTertiaryContainer,
      error: NexusColors.error,
      onError: NexusColors.onError,
      errorContainer: NexusColors.errorContainer,
      onErrorContainer: NexusColors.onErrorContainer,
      surface: NexusColors.surface,
      onSurface: NexusColors.onSurface,
      surfaceContainerLowest: NexusColors.surfaceContainerLowest,
      surfaceContainerLow: NexusColors.surfaceContainerLow,
      surfaceContainer: NexusColors.surfaceContainer,
      surfaceContainerHigh: NexusColors.surfaceContainerHigh,
      surfaceContainerHighest: NexusColors.surfaceContainerHighest,
      onSurfaceVariant: NexusColors.onSurfaceVariant,
      outline: NexusColors.outline,
      outlineVariant: NexusColors.outlineVariant,
      inverseSurface: NexusColors.inverseSurface,
      inversePrimary: NexusColors.inversePrimary,
      onInverseSurface: NexusColors.inverseOnSurface,
    ),
    textTheme: NexusTypography.textTheme,
    scaffoldBackgroundColor: NexusColors.background,
    cardTheme: CardThemeData(
      color: NexusColors.surfaceContainerLowest,
      elevation: 1,
      shadowColor: const Color(0x141A237E),
      shape: NexusShapes.cardShape,
      margin: const EdgeInsets.symmetric(
        horizontal: NexusSpacing.containerPadding,
        vertical: NexusSpacing.stackSm,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: NexusColors.background,
      foregroundColor: NexusColors.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: NexusTypography.textTheme.titleLarge,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: NexusColors.primary,
        foregroundColor: NexusColors.onPrimary,
        disabledBackgroundColor: NexusColors.surfaceContainerHigh,
        disabledForegroundColor: NexusColors.onSurfaceVariant,
        elevation: 0,
        padding: NexusSpacing.buttonPadding,
        shape: NexusShapes.buttonShape,
        minimumSize: const Size(64, NexusSpacing.minTapTarget),
        textStyle: NexusTypography.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: NexusColors.primary,
        side: const BorderSide(color: NexusColors.outlineVariant),
        padding: NexusSpacing.buttonPadding,
        shape: NexusShapes.buttonShape,
        minimumSize: const Size(64, NexusSpacing.minTapTarget),
        textStyle: NexusTypography.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: NexusColors.primary,
        padding: NexusSpacing.buttonPadding,
        minimumSize: const Size(64, NexusSpacing.minTapTarget),
        textStyle: NexusTypography.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NexusColors.surfaceContainerLowest,
      contentPadding: NexusSpacing.inputPadding,
      border: OutlineInputBorder(
        borderRadius: NexusShapes.inputRadius,
        borderSide: const BorderSide(color: NexusColors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: NexusShapes.inputRadius,
        borderSide: const BorderSide(color: NexusColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: NexusShapes.inputRadius,
        borderSide: const BorderSide(color: NexusColors.primary, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: NexusShapes.inputRadius,
        borderSide: const BorderSide(color: NexusColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: NexusShapes.inputRadius,
        borderSide: const BorderSide(color: NexusColors.error, width: 2.0),
      ),
      labelStyle: NexusTypography.textTheme.labelMedium,
      hintStyle: NexusTypography.textTheme.bodyMedium?.copyWith(
        color: NexusColors.onSurfaceVariant,
      ),
      errorStyle: NexusTypography.textTheme.labelSmall?.copyWith(
        color: NexusColors.error,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: NexusColors.surfaceContainerHigh,
      labelStyle: NexusTypography.textTheme.labelMedium,
      shape:
          const StadiumBorder(), // Correction : Utilise une forme (StadiumBorder) au lieu d'un radius
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      side: BorderSide.none,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: NexusColors.surfaceContainerLowest,
      selectedItemColor: NexusColors.primary,
      unselectedItemColor: NexusColors.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 2,
      selectedLabelStyle: NexusTypography.textTheme.labelSmall,
      unselectedLabelStyle: NexusTypography.textTheme.labelSmall,
    ),
    dividerTheme: const DividerThemeData(
      color: NexusColors.outlineVariant,
      thickness: 1,
      space: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NexusShapes.radiusMd),
      ),
      contentTextStyle: NexusTypography.textTheme.bodyMedium?.copyWith(
        color: Colors.white,
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: NexusShapes.cardShape,
      elevation: 8,
      titleTextStyle: NexusTypography.textTheme.headlineSmall,
      contentTextStyle: NexusTypography.textTheme.bodyMedium,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      shape: NexusShapes.bottomSheetShape,
      backgroundColor: NexusColors.surfaceContainerLowest,
      elevation: 8,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: NexusColors.secondaryContainer,
      linearTrackColor: NexusColors.surfaceContainerHighest,
      circularTrackColor: NexusColors.surfaceContainerHighest,
    ),
  );
}
