import 'package:flutter/material.dart';
import 'package:nexus/core/theme/app_spacing.dart';
import 'package:nexus/core/theme/widgets/nexus_card.dart';
import 'package:nexus/core/theme/widgets/nexus_skeleton.dart';

/// Pattern de skeleton pour une tuile de liste avec icône et texte.
/// Utilisé pour les listes de transactions, prêts, investissements, etc.
class NexusListTileSkeleton extends StatelessWidget {
  const NexusListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return NexusCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          NexusSkeleton(
            height: 44,
            width: 44,
            borderRadius: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NexusSkeleton(height: 14, width: 120),
                const SizedBox(height: 6),
                NexusSkeleton(height: 10, width: 80),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              NexusSkeleton(height: 14, width: 80),
              const SizedBox(height: 6),
              NexusSkeleton(height: 10, width: 40),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pattern de skeleton pour une liste complète avec padding.
class NexusListSkeleton extends StatelessWidget {
  final int itemCount;

  const NexusListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (_) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: NexusSpacing.containerPadding,
            vertical: 4,
          ),
          child: const NexusListTileSkeleton(),
        ),
      ),
    );
  }
}
