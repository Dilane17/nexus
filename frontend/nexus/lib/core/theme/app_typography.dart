import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typographie Nexus — Manrope (titres) & Inter (labels/data)
class NexusTypography {
  NexusTypography._();

  static TextTheme get textTheme => TextTheme(
    // ── Headlines ──
    displayLarge: GoogleFonts.manrope(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.02 * 32, // -2% en px
      height: 40 / 32,
      color: NexusColors.onSurface,
    ),
    displayMedium: GoogleFonts.manrope(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.02 * 28,
      height: 36 / 28,
      color: NexusColors.onSurface,
    ),
    displaySmall: GoogleFonts.manrope(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.01 * 24,
      height: 32 / 24,
      color: NexusColors.onSurface,
    ),

    // ── Headlines ──
    headlineLarge: GoogleFonts.manrope(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.01 * 22,
      height: 28 / 22,
      color: NexusColors.onSurface,
    ),
    headlineMedium: GoogleFonts.manrope(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 26 / 20,
      color: NexusColors.onSurface,
    ),
    headlineSmall: GoogleFonts.manrope(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      height: 24 / 18,
      color: NexusColors.onSurface,
    ),

    // ── Titles ──
    titleLarge: GoogleFonts.manrope(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 28 / 18,
      color: NexusColors.onSurface,
    ),
    titleMedium: GoogleFonts.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 24 / 16,
      color: NexusColors.onSurface,
    ),
    titleSmall: GoogleFonts.manrope(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 20 / 14,
      color: NexusColors.onSurface,
    ),

    // ── Body (Manrope, 400) ──
    bodyLarge: GoogleFonts.manrope(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      height: 28 / 18,
      color: NexusColors.onSurface,
    ),
    bodyMedium: GoogleFonts.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 24 / 16,
      color: NexusColors.onSurfaceVariant,
    ),
    bodySmall: GoogleFonts.manrope(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 20 / 14,
      color: NexusColors.onSurfaceVariant,
    ),

    // ── Labels (Inter, 500) — micro-copy, data ──
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.05 * 14,
      height: 20 / 14,
      color: NexusColors.onSurfaceVariant,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.05 * 12,
      height: 16 / 12,
      color: NexusColors.onSurfaceVariant,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.05 * 11,
      height: 16 / 11,
      color: NexusColors.onSurfaceVariant,
    ),
  );

  /// Style spécial pour les montants en FCFA
  static TextStyle get amountLarge => GoogleFonts.manrope(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.02 * 32,
    height: 40 / 32,
    color: NexusColors.onSurface,
  );

  static TextStyle get amountMedium => GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    color: NexusColors.onSurface,
  );

  static TextStyle get amountSmall => GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    color: NexusColors.onSurface,
  );
}
