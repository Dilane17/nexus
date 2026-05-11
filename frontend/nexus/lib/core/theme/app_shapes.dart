import 'package:flutter/material.dart';

/// Formes Nexus — signature à 16px de radius.
class NexusShapes {
  NexusShapes._();

  // Radius constants
  static const double radiusSm = 4.0; // 0.25rem — checkboxes, small tags
  static const double radiusDefault = 8.0; // 0.5rem
  static const double radiusMd = 12.0; // 0.75rem
  static const double radiusLg =
      16.0; // 1rem — SIGNATURE (cards, buttons, inputs)
  static const double radiusXl = 24.0; // 1.5rem — bottom sheets top corners
  static const double radiusFull = 9999; // Pills, chips

  // BorderRadius presets
  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(radiusLg),
  );
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(radiusLg),
  );
  static const BorderRadius inputRadius = BorderRadius.all(
    Radius.circular(radiusLg),
  );
  static const BorderRadius chipRadius = BorderRadius.all(
    Radius.circular(radiusFull),
  );

  static const BorderRadius bottomSheetTopRadius = BorderRadius.vertical(
    top: Radius.circular(radiusXl),
  );

  // RoundedRectangleBorder presets
  static const RoundedRectangleBorder buttonShape = RoundedRectangleBorder(
    borderRadius: buttonRadius,
  );

  static const RoundedRectangleBorder cardShape = RoundedRectangleBorder(
    borderRadius: cardRadius,
  );

  static const RoundedRectangleBorder bottomSheetShape = RoundedRectangleBorder(
    borderRadius: bottomSheetTopRadius,
  );
}
