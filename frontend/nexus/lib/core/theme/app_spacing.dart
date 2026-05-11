import 'package:flutter/material.dart';

/// Système d'espacement basé sur une grille de 8px.
/// Stack philosophy : petits gaps (4-12px) pour éléments liés,
/// grands gaps (24px+) pour sections distinctes.
class NexusSpacing {
  NexusSpacing._();

  // Base unit
  static const double base = 8.0;

  // Stack spacing
  static const double stackXs = 4.0; // 4px
  static const double stackSm = 8.0; // 8px
  static const double stackMd = 12.0; // 12px
  static const double stackLg = 24.0; // 24px
  static const double stackXl = 32.0; // 32px
  static const double stack2xl = 48.0; // 48px

  // Container padding (marges extérieures mobiles)
  static const double containerPadding = 24.0;

  // Gutter (espacement entre colonnes)
  static const double gutter = 16.0;

  // Hit targets minimum
  static const double minTapTarget = 48.0;
  static const double largeTapTarget = 56.0;

  // Utilitaires
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: containerPadding,
    vertical: stackMd,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 12.0,
  );

  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 14.0,
  );
}
