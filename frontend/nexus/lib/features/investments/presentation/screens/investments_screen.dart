import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/core/formatters/money_formatter.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/theme/app_spacing.dart';
import 'package:nexus/core/theme/widgets/nexus_card.dart';
import 'package:nexus/features/investments/data/models/investment_models.dart';
import 'package:nexus/features/investments/presentation/providers/investment_provider.dart';
import 'package:nexus/features/loans/data/models/loan_models.dart';
import 'package:nexus/shared/models/app_enums.dart';

class InvestmentsScreen extends ConsumerStatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  ConsumerState<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends ConsumerState<InvestmentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(investmentProvider.notifier).loadInvestments();
      ref.read(investmentProvider.notifier).loadSummary();
      ref.read(investmentProvider.notifier).loadMarketplace();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(investmentProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(investmentProvider);

    ref.listen(investmentProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: NexusColors.error,
          ),
        );
        ref.read(investmentProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: NexusColors.background,
      appBar: AppBar(
        title: const Text('Investissements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: 'Auto-Invest',
            onPressed: () => context.push('/investments/auto-invest'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Portefeuille'), Tab(text: 'Marketplace')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PortfolioTab(state: state, scrollController: _scrollController),
          _MarketplaceTab(state: state),
        ],
      ),
    );
  }
}

// ── Portfolio Tab ─────────────────────────────────────────────────────────────

class _PortfolioTab extends StatelessWidget {
  final InvestmentState state;
  final ScrollController scrollController;

  const _PortfolioTab({required this.state, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Pas d'accès direct au notifier ici — géré par le parent
      },
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: NexusSpacing.screenPadding,
              child: Column(
                children: [
                  if (state.isSummaryLoading)
                    const _SkeletonSummary()
                  else if (state.summary != null)
                    _SummaryCard(summary: state.summary!),
                  const SizedBox(height: NexusSpacing.stackXl),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Mes investissements',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: NexusSpacing.stackMd),
                ],
              ),
            ),
          ),
          if (state.isLoading && state.investments.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: const CircularProgressIndicator(),
                ),
              ),
            )
          else if (state.investments.isEmpty)
            const SliverToBoxAdapter(child: _EmptyPortfolio())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == state.investments.length) {
                  return state.isLoading
                      ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                      : const SizedBox(height: NexusSpacing.stack2xl);
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: NexusSpacing.containerPadding,
                    vertical: 4,
                  ),
                  child: _InvestmentCard(investment: state.investments[index]),
                );
              }, childCount: state.investments.length + 1),
            ),
        ],
      ),
    );
  }
}

// ── Marketplace Tab ───────────────────────────────────────────────────────────

class _MarketplaceTab extends StatelessWidget {
  final InvestmentState state;

  const _MarketplaceTab({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isMarketplaceLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.marketplaceLoans.isEmpty) {
      return _EmptyMarketplace();
    }
    return ListView.separated(
      padding: NexusSpacing.screenPadding,
      itemCount: state.marketplaceLoans.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder:
          (context, index) =>
              _MarketplaceLoanCard(loan: state.marketplaceLoans[index]),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final InvestmentSummary summary;

  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NexusCard(
      useGradient: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Résumé portefeuille', style: theme.textTheme.titleSmall),
          const SizedBox(height: NexusSpacing.stackLg),
          Row(
            children: [
              _SummaryItem(
                label: 'Investi',
                value: MoneyFormatter.format(summary.totalInvested),
                color: NexusColors.primary,
              ),
              const SizedBox(width: NexusSpacing.gutter),
              _SummaryItem(
                label: 'Retour attendu',
                value: MoneyFormatter.format(summary.totalExpectedReturn),
                color: NexusColors.success,
              ),
              const SizedBox(width: NexusSpacing.gutter),
              _SummaryItem(
                label: 'Retour réel',
                value: MoneyFormatter.format(summary.totalActualReturn),
                color: NexusColors.info,
              ),
            ],
          ),
          const SizedBox(height: NexusSpacing.stackMd),
          Row(
            children: [
              _CountChip(
                label: '${summary.activeCount} actifs',
                color: NexusColors.success,
              ),
              const SizedBox(width: 8),
              _CountChip(
                label: '${summary.completedCount} terminés',
                color: NexusColors.info,
              ),
              const SizedBox(width: 8),
              if (summary.defaultedCount > 0)
                _CountChip(
                  label: '${summary.defaultedCount} défauts',
                  color: NexusColors.error,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: NexusColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final Color color;

  const _CountChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

// ── Investment Card ───────────────────────────────────────────────────────────

class _InvestmentCard extends StatelessWidget {
  final Investment investment;

  const _InvestmentCard({required this.investment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg) = _statusColors(investment.status);

    return NexusCard(
      onTap: () => context.push('/investments/${investment.id}'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
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
                        investment.status.displayName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (investment.isGuaranteed) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: NexusColors.success,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: NexusSpacing.stackMd),
                Text(
                  MoneyFormatter.format(investment.amount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: NexusColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Retour attendu',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: NexusColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                MoneyFormatter.format(investment.expectedReturn),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: NexusColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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

  (Color bg, Color fg) _statusColors(InvestmentStatus s) {
    return switch (s) {
      InvestmentStatus.active => (
        NexusColors.successContainer,
        NexusColors.success,
      ),
      InvestmentStatus.completed => (
        NexusColors.infoContainer,
        NexusColors.info,
      ),
      InvestmentStatus.defaulted => (
        NexusColors.errorContainer,
        NexusColors.error,
      ),
      InvestmentStatus.guaranteed => (
        NexusColors.successContainer,
        NexusColors.success,
      ),
    };
  }
}

// ── Marketplace Loan Card ─────────────────────────────────────────────────────

class _MarketplaceLoanCard extends StatelessWidget {
  final Loan loan;

  const _MarketplaceLoanCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NexusCard(
      onTap: () => context.push('/investments/invest/${loan.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                MoneyFormatter.format(loan.amount),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: NexusColors.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: NexusColors.infoContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${loan.durationMonths} mois',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: NexusColors.info,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: NexusSpacing.stackMd),
          Row(
            children: [
              Text(
                'Taux : ${(loan.interestRate * 100).toStringAsFixed(1)}%/an',
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                'Investir →',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: NexusColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Skeleton Summary ──────────────────────────────────────────────────────────

class _SkeletonSummary extends StatelessWidget {
  const _SkeletonSummary();

  @override
  Widget build(BuildContext context) {
    return NexusCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            height: 16,
            width: 120,
            decoration: BoxDecoration(
              color: NexusColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: NexusSpacing.stackLg),
          Row(
            children: List.generate(
              3,
              (_) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: NexusColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty States ──────────────────────────────────────────────────────────────

class _EmptyPortfolio extends StatelessWidget {
  const _EmptyPortfolio();

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
                  Icons.trending_up_rounded,
                  size: 48,
                  color: NexusColors.onSurfaceVariant,
                ),
                const SizedBox(height: NexusSpacing.stackMd),
                Text(
                  'Aucun investissement',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Explorez la marketplace pour investir',
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

class _EmptyMarketplace extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: NexusSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 64,
              color: NexusColors.onSurfaceVariant,
            ),
            const SizedBox(height: NexusSpacing.stackLg),
            Text(
              'Aucun prêt disponible',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: NexusSpacing.stackMd),
            Text(
              'Les prêts en cours de financement\napparaîtront ici',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
