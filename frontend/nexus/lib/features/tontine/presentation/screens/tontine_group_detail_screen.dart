import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/core/formatters/date_formatter.dart';
import 'package:nexus/core/formatters/money_formatter.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/theme/app_spacing.dart';
import 'package:nexus/core/theme/widgets/nexus_button.dart';
import 'package:nexus/core/theme/widgets/nexus_card.dart';
import 'package:nexus/core/theme/widgets/nexus_chip.dart';
import 'package:nexus/features/auth/presentation/providers/auth_provider.dart';
import 'package:nexus/features/tontine/data/models/tontine_models.dart';
import 'package:nexus/features/tontine/presentation/providers/tontine_provider.dart';
import 'package:nexus/shared/models/app_enums.dart';
import 'package:nexus/shared/widgets/nexus_info_row.dart';

class TontineGroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const TontineGroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<TontineGroupDetailScreen> createState() =>
      _TontineGroupDetailScreenState();
}

class _TontineGroupDetailScreenState
    extends ConsumerState<TontineGroupDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tontineProvider.notifier).loadGroupDetail(widget.groupId);
      ref.read(tontineProvider.notifier).loadCycles(widget.groupId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tontineProvider);
    final group = state.selectedGroup;
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.id;

    ref.listen(tontineProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: NexusColors.error,
          ),
        );
        ref.read(tontineProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: NexusColors.background,
      appBar: AppBar(
        title: Text(group?.name ?? 'Groupe'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body:
          state.isDetailLoading
              ? const Center(child: CircularProgressIndicator())
              : group == null
              ? const Center(child: Text('Groupe introuvable'))
              : SingleChildScrollView(
                padding: NexusSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── En-tête ─────────────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        NexusStatusChip.fromTontineStatus(group.status),
                      ],
                    ),
                    const SizedBox(height: NexusSpacing.stackXl),

                    // ── Informations ────────────────────────────────────────
                    NexusCard(
                      child: Column(
                        children: [
                          NexusInfoRow(
                            label: 'Cotisation mensuelle',
                            value: MoneyFormatter.format(
                              group.monthlyContribution,
                            ),
                          ),
                          const Divider(height: 20),
                          NexusInfoRow(
                            label: 'Membres',
                            value: '${group.memberCount}',
                          ),
                          const Divider(height: 20),
                          NexusInfoRow(
                            label: 'Cycles complétés',
                            value: '${group.completedCycles}',
                          ),
                          const Divider(height: 20),
                          NexusInfoRow(
                            label: 'Responsable',
                            value: group.leaderPhone,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: NexusSpacing.stackXl),

                    // ── Cycles ──────────────────────────────────────────────
                    if (state.isCyclesLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (state.cycles.isNotEmpty) ...[
                      Row(
                        children: [
                          Text(
                            'Cycles',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const Spacer(),
                          // ── Bouton Créer un cycle (leader only) ───────────
                          if (currentUserId == group.leaderUserId)
                            TextButton.icon(
                              onPressed:
                                  () => context.push(
                                    '/tontine/groups/${widget.groupId}/cycles/create',
                                  ),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Créer un cycle'),
                              style: TextButton.styleFrom(
                                foregroundColor: NexusColors.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: NexusSpacing.stackMd),
                      ...state.cycles.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _CycleTile(cycle: c, groupId: widget.groupId),
                        ),
                      ),
                      const SizedBox(height: NexusSpacing.stackXl),
                    ],

                    // ── CTA Rejoindre ────────────────────────────────────────
                    if (group.status == TontineStatus.active)
                      NexusButton(
                        label: 'Rejoindre ce groupe',
                        isLoading: state.isSubmitting,
                        onPressed:
                            state.isSubmitting ? null : () => _join(context),
                      ),

                    if (group.status == TontineStatus.suspended)
                      NexusCard(
                        backgroundColor: NexusColors.errorContainer,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.block_rounded,
                              color: NexusColors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ce groupe est actuellement suspendu',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: NexusColors.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: NexusSpacing.stack2xl),
                  ],
                ),
              ),
    );
  }

  Future<void> _join(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(tontineProvider.notifier)
        .joinGroup(widget.groupId);
    if (ok && mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Vous avez rejoint ce groupe'),
          backgroundColor: NexusColors.success,
        ),
      );
    }
  }
}

// ── Widgets locaux ────────────────────────────────────────────────────────────

final _dateShort = DateFormatter.formatShort;

class _CycleTile extends StatelessWidget {
  final TontineCycle cycle;
  final String groupId;

  const _CycleTile({required this.cycle, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg) =
        cycle.isComplete
            ? (NexusColors.successContainer, NexusColors.success)
            : (NexusColors.warningContainer, NexusColors.warning);

    return NexusCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${cycle.cycleNumber}',
                style: theme.textTheme.titleSmall?.copyWith(color: fg),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cycle ${cycle.cycleNumber}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_dateShort(cycle.startDate)} – ${_dateShort(cycle.endDate)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: NexusColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                MoneyFormatter.format(cycle.totalCollected),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                cycle.isComplete ? 'Terminé' : 'En cours',
                style: theme.textTheme.labelSmall?.copyWith(color: fg),
              ),
              const SizedBox(height: 4),
              if (!cycle.isComplete)
                TextButton(
                  onPressed:
                      () => context.push(
                        '/tontine/cycles/${cycle.id}/complete',
                        extra: groupId,
                      ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Clôturer', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
