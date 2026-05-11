import 'package:flutter/material.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/theme/app_spacing.dart';

/// Ligne d'information réutilisable pour afficher une paire clé-valeur.
/// Utilisé dans les écrans de détail (prêts, investissements, tontine, wallet).
class NexusInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;
  final CrossAxisAlignment crossAxisAlignment;

  const NexusInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NexusSpacing.stackSm),
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: NexusColors.onSurfaceVariant,
              ),
            ),
          ),
          if (trailing != null)
            trailing!
          else
            Text(
              value,
              style: theme.textTheme.labelMedium?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
        ],
      ),
    );
  }
}
