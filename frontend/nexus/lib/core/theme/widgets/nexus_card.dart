import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_elevation.dart';
import '../app_shapes.dart';
import '../app_spacing.dart';

/// Carte standard Nexus — signature à 16px radius avec ombre Level 1.
class NexusCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool useGradient;

  const NexusCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.useGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: NexusShapes.cardRadius,
        child: Ink(
          padding: padding ?? NexusSpacing.cardPadding,
          decoration: BoxDecoration(
            color: backgroundColor ?? NexusColors.surfaceContainerLowest,
            borderRadius: NexusShapes.cardRadius,
            border: NexusElevation.cardBorder,
            boxShadow: useGradient ? null : NexusElevation.level1,
            gradient: useGradient
                ? const LinearGradient(
                    colors: [
                      NexusColors.surfaceContainerLowest,
                      Color(0xFFF5F7FF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
