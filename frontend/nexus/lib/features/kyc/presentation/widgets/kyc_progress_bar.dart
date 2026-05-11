import 'package:flutter/material.dart';
import 'package:nexus/core/theme/app_colors.dart';

/// Barre de progression à 3 étapes utilisée sur tous les écrans KYC.
/// [step] indique combien d'étapes sont complétées (1, 2 ou 3).
class KycProgressBar extends StatelessWidget {
  final int step;

  const KycProgressBar({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final active = i < step;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: active ? NexusColors.primary : NexusColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
