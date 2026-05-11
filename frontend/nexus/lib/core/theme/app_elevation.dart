
import 'package:flutter/material.dart';

/// Élévation Nexus — ombres douces teintées bleu primaire.
class NexusElevation {
  NexusElevation._();

  /// Level 0 : fond de base, pas d'ombre.
  static const double level0 = 0.0;

  /// Level 1 : Cartes — ombre légère + bordure 1px.
  static List<BoxShadow> get level1 => [
    BoxShadow(
      color: Color(0x141A237E), // rgba(26, 35, 126, 0.08)
      blurRadius: 4,
      offset: const Offset(0, 1),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0A1A237E), // rgba(26, 35, 126, 0.04)
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  /// Level 2 : Modales, bottom sheets — ombre plus marquée.
  static List<BoxShadow> get level2 => [
    BoxShadow(
      color: Color(0x1A1A237E), // rgba(26, 35, 126, 0.10)
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0F1A237E), // rgba(26, 35, 126, 0.06)
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  /// Bordure subtile pour les cartes (Level 1)
  static BoxBorder get cardBorder =>
      Border.all(color: const Color(0xFFE0E0E0), width: 1.0);
}
