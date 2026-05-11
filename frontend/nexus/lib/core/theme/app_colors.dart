import 'package:flutter/material.dart';

/// Design System — Pan-African Financial Core
/// Palette institutionnelle ancrée sur la confiance et l'accessibilité.
class NexusColors {
  NexusColors._();

  // ───────────────────────────────────────
  // Primary (Bleu institutionnel profond)
  // ───────────────────────────────────────
  static const Color primary = Color(0xFF000666);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF1A237E);
  static const Color onPrimaryContainer = Color(0xFF8690EE);
  static const Color inversePrimary = Color(0xFFBDC2FF);

  // Fixed tones
  static const Color primaryFixed = Color(0xFFE0E0FF);
  static const Color primaryFixedDim = Color(0xFFBDC2FF);
  static const Color onPrimaryFixed = Color(0xFF000767);
  static const Color onPrimaryFixedVariant = Color(0xFF343D96);

  // ───────────────────────────────────────
  // Secondary (Orange accent chaud)
  // ───────────────────────────────────────
  static const Color secondary = Color(0xFF9F4200);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFD6C00);
  static const Color onSecondaryContainer = Color(0xFF562000);

  // Fixed tones
  static const Color secondaryFixed = Color(0xFFFFDBCB);
  static const Color secondaryFixedDim = Color(0xFFFFB692);
  static const Color onSecondaryFixed = Color(0xFF341100);
  static const Color onSecondaryFixedVariant = Color(0xFF7A3000);

  // ───────────────────────────────────────
  // Tertiary (Terre cuite chaude)
  // ───────────────────────────────────────
  static const Color tertiary = Color(0xFF380B00);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF5C1800);
  static const Color onTertiaryContainer = Color(0xFFE17C5A);

  // ───────────────────────────────────────
  // Error
  // ───────────────────────────────────────
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ───────────────────────────────────────
  // Surfaces (Light cool gray)
  // ───────────────────────────────────────
  static const Color surface = Color(0xFFF7F9FC);
  static const Color surfaceDim = Color(0xFFD8DADD);
  static const Color surfaceBright = Color(0xFFF7F9FC);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F7);
  static const Color surfaceContainer = Color(0xFFECEEF1);
  static const Color surfaceContainerHigh = Color(0xFFE6E8EB);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E6);

  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color(0xFF454652);

  static const Color inverseSurface = Color(0xFF2D3133);
  static const Color inverseOnSurface = Color(0xFFEFF1F4);

  // ───────────────────────────────────────
  // Outline
  // ───────────────────────────────────────
  static const Color outline = Color(0xFF767683);
  static const Color outlineVariant = Color(0xFFC6C5D4);

  // ───────────────────────────────────────
  // Background / Root
  // ───────────────────────────────────────
  static const Color background = Color(0xFFF7F9FC);
  static const Color onBackground = Color(0xFF191C1E); // alias onSurface

  // ───────────────────────────────────────
  // Surface Tint
  // ───────────────────────────────────────
  static const Color surfaceTint = Color(0xFF4C56AF);

  // ───────────────────────────────────────
  // Fonctionnels (hors Design Token stricts)
  // ───────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFF57F17);
  static const Color warningContainer = Color(0xFFFFF8E1);
  static const Color info = Color(0xFF1565C0);
  static const Color infoContainer = Color(0xFFE3F2FD);

  /// Couleurs de confiance (ancrage Bénin) pour usages spécifiques
  static const Color trustGreen = Color(0xFF1B5E20);
  static const Color trustOrange = Color(0xFFE65100);
}
