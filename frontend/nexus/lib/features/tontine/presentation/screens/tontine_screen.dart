import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/core/formatters/money_formatter.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/theme/app_spacing.dart';
import 'package:nexus/core/theme/widgets/nexus_card.dart';
import 'package:nexus/features/tontine/data/models/tontine_models.dart';
import 'package:nexus/features/tontine/presentation/providers/tontine_provider.dart';
import 'package:nexus/shared/models/app_enums.dart';

class TontineScreen extends ConsumerStatefulWidget {
  const TontineScreen({super.key});

  @override
  ConsumerState<TontineScreen> createState() => _TontineScreenState();
}

class _TontineScreenState extends ConsumerState<TontineScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tontineProvider.notifier).loadScore();
      ref.read(tontineProvider.notifier).loadGroups();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(tontineProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tontineProvider);

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
      appBar: AppBar(title: const Text('Tontine')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tontine/groups/create'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Créer un groupe'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(tontineProvider.notifier).loadScore();
          await ref.read(tontineProvider.notifier).loadGroups();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: NexusSpacing.screenPadding,
                child: Column(
                  children: [
                    if (state.isScoreLoading)
                      const _SkeletonScore()
                    else if (state.myScore != null)
                      _ScoreCard(score: state.myScore!),
                    const SizedBox(height: NexusSpacing.stackXl),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Groupes tontine',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(height: NexusSpacing.stackMd),
                  ],
                ),
              ),
            ),
            if (state.isLoading && state.groups.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              )
            else if (state.groups.isEmpty)
              const SliverToBoxAdapter(child: _EmptyGroups())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index == state.groups.length) {
                    return state.isLoading
                        ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                        : const SizedBox(height: 80);
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: NexusSpacing.containerPadding,
                      vertical: 4,
                    ),
                    child: _GroupCard(group: state.groups[index]),
                  );
                }, childCount: state.groups.length + 1),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Score Card ────────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final TontineScore score;

  const _ScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (score.score * 100).toStringAsFixed(0);

    return NexusCard(
      useGradient: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Indicateur circulaire score
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: score.score.toDouble().clamp(0.0, 1.0),
                      strokeWidth: 6,
                      backgroundColor: NexusColors.surfaceContainerHigh,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        NexusColors.primary,
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: NexusColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: NexusSpacing.stackLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Score Tontine', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      '${score.completedCycles} cycles complétés',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: NexusColors.onSurfaceVariant,
                      ),
                    ),
                    if (score.defaultedCycles > 0)
                      Text(
                        '${score.defaultedCycles} défauts',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: NexusColors.error,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: NexusSpacing.stackMd),
          Row(
            children: [
              const Icon(
                Icons.savings_outlined,
                size: 14,
                color: NexusColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Total cotisé : ${MoneyFormatter.format(score.totalContributed)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: NexusColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Group Card ────────────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final TontineGroup group;

  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg) = _statusColors(group.status);

    return NexusCard(
      onTap: () => context.push('/tontine/groups/${group.id}'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.name,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        group.status.displayName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: NexusSpacing.stackMd),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.people_outline_rounded,
                      label: '${group.memberCount} membres',
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      icon: Icons.payments_outlined,
                      label: MoneyFormatter.format(group.monthlyContribution),
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      icon: Icons.loop_rounded,
                      label: '${group.completedCycles} cycles',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: NexusColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  (Color bg, Color fg) _statusColors(TontineStatus s) {
    return switch (s) {
      TontineStatus.active => (
        NexusColors.successContainer,
        NexusColors.success,
      ),
      TontineStatus.pending => (
        NexusColors.warningContainer,
        NexusColors.warning,
      ),
      TontineStatus.completed => (NexusColors.infoContainer, NexusColors.info),
      TontineStatus.suspended => (
        NexusColors.errorContainer,
        NexusColors.error,
      ),
    };
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: NexusColors.onSurfaceVariant),
        const SizedBox(width: 2),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: NexusColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ── Skeleton Score ────────────────────────────────────────────────────────────

class _SkeletonScore extends StatelessWidget {
  const _SkeletonScore();

  @override
  Widget build(BuildContext context) {
    return NexusCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: NexusColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: NexusSpacing.stackLg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100,
                height: 14,
                decoration: BoxDecoration(
                  color: NexusColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 140,
                height: 10,
                decoration: BoxDecoration(
                  color: NexusColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyGroups extends StatelessWidget {
  const _EmptyGroups();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: NexusSpacing.screenPadding,
      child: NexusCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                const Icon(
                  Icons.people_outline_rounded,
                  size: 48,
                  color: NexusColors.onSurfaceVariant,
                ),
                const SizedBox(height: NexusSpacing.stackMd),
                Text(
                  'Aucun groupe tontine',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Créez votre premier groupe',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
