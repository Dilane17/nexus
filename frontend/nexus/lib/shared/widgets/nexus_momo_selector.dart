import 'package:flutter/material.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/shared/models/app_enums.dart';

/// Sélecteur d'opérateur Mobile Money réutilisable.
/// Utilisé pour les dépôts, retraits et remboursements.
class NexusMomoSelector extends StatelessWidget {
  final MomoProvider selected;
  final ValueChanged<MomoProvider> onChanged;

  const NexusMomoSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: MomoProvider.values.map((p) {
        final isSelected = p == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(p),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? NexusColors.primaryFixed
                    : NexusColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? NexusColors.primary
                      : NexusColors.outlineVariant,
                ),
              ),
              child: Text(
                p.displayName,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? NexusColors.primary
                      : NexusColors.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
