import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_spacing.dart';

/// Bouton Nexus — primaire, secondaire, tertiaire, accent
class NexusButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final NexusButtonStyle style;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? width;

  const NexusButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = NexusButtonStyle.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final child = _buildChild(context);
    final styleFrom = _getStyle(context);

    Widget button;
    switch (style) {
      case NexusButtonStyle.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
        break;
      case NexusButtonStyle.secondary:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
        break;
      case NexusButtonStyle.accent:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: NexusColors.secondaryContainer,
            foregroundColor: NexusColors.onSecondary,
          ).merge(styleFrom),
          child: child,
        );
        break;
      case NexusButtonStyle.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
        break;
    }

    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      child: button,
    );
  }

  ButtonStyle _getStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      minimumSize: Size(width ?? 64, NexusSpacing.minTapTarget),
    );
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color:
              style == NexusButtonStyle.primary
                  ? Colors.white
                  : NexusColors.primary,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(label)],
      );
    }

    return Text(label);
  }
}

enum NexusButtonStyle { primary, secondary, accent, text }
