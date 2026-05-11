import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/core/formatters/money_formatter.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/theme/app_spacing.dart';
import 'package:nexus/core/theme/widgets/nexus_button.dart';
import 'package:nexus/core/theme/widgets/nexus_card.dart';
import 'package:nexus/features/auth/presentation/providers/auth_provider.dart';
import 'package:nexus/features/loans/data/models/loan_models.dart';
import 'package:nexus/features/loans/presentation/providers/loan_provider.dart';
import 'package:nexus/features/loans/presentation/widgets/loan_widgets.dart';
import 'package:nexus/shared/models/app_enums.dart';

class LoansScreen extends ConsumerStatefulWidget {
  const LoansScreen({super.key});

  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Chargement initial au premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loanProvider.notifier).loadLoans();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Charger plus quand on approche du bas de la liste
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(loanProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loanProvider);
    final user = ref.watch(authProvider).user;
    final theme = Theme.of(context);

    ref.listen(loanProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: NexusColors.error,
          ),
        );
        ref.read(loanProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: NexusColors.background,
      appBar: AppBar(
        title: const Text('Mes Prêts'),
        centerTitle: false,
        actions: [
          if (user?.canAccessLoans == true)
            TextButton.icon(
              onPressed: () => context.push('/loans/create'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nouveau'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(loanProvider.notifier).loadLoans(),
        child: _buildBody(context, state, user?.canAccessLoans ?? false, theme),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    LoanState state,
    bool canAccessLoans,
    ThemeData theme,
  ) {
    // KYC non validé
    if (!canAccessLoans) {
      return _KycRequiredEmptyState();
    }

    // Premier chargement
    if (state.isLoading && state.loans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Aucun prêt
    if (!state.isLoading && state.loans.isEmpty) {
      return _EmptyLoansState();
    }

    return ListView.separated(
      controller: _scrollController,
      padding: NexusSpacing.screenPadding,
      itemCount: state.loans.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: NexusSpacing.stackMd),
      itemBuilder: (context, index) {
        if (index == state.loans.length) {
          // Indicateur de chargement en bas de liste
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _LoanCard(
          loan: state.loans[index],
          onTap: () => context.push('/loans/${state.loans[index].id}'),
        );
      },
    );
  }
}

// ── Carte de prêt ─────────────────────────────────────────────────────────────

class _LoanCard extends StatelessWidget {
  final Loan loan;
  final VoidCallback onTap;

  const _LoanCard({required this.loan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NexusCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  MoneyFormatter.format(loan.amount),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              LoanStatusBadge(status: loan.status),
            ],
          ),
          const SizedBox(height: NexusSpacing.stackXs),
          Text(
            '${loan.durationMonths} mois · ${(loan.interestRate * 100).toStringAsFixed(1)}% / an',
            style: theme.textTheme.bodySmall,
          ),
          if (loan.status == LoanStatus.active ||
              loan.status == LoanStatus.overdue) ...[
            const SizedBox(height: NexusSpacing.stackMd),
            // Barre de progression du remboursement
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: loan.repaidRatio,
                backgroundColor: NexusColors.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(
                  loan.status == LoanStatus.overdue
                      ? NexusColors.error
                      : NexusColors.primary,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: NexusSpacing.stackXs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Restant : ${MoneyFormatter.format(loan.outstandingBalance)}',
                  style: theme.textTheme.labelSmall,
                ),
                Text(
                  '${(loan.repaidRatio * 100).toStringAsFixed(0)}% remboursé',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ],
          if (loan.status == LoanStatus.overdue) ...[
            const SizedBox(height: NexusSpacing.stackXs),
            Text(
              '${loan.daysOverdue} jour(s) de retard',
              style: theme.textTheme.labelSmall?.copyWith(
                color: NexusColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── États vides ───────────────────────────────────────────────────────────────

class _EmptyLoansState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: NexusSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.payments_outlined,
              size: 64,
              color: NexusColors.onSurfaceVariant,
            ),
            const SizedBox(height: NexusSpacing.stackLg),
            Text(
              'Aucun prêt en cours',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: NexusSpacing.stackMd),
            Text(
              'Faites votre première demande de prêt.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NexusSpacing.stackXl),
            NexusButton(
              label: 'Faire une demande',
              isFullWidth: false,
              onPressed: () => context.push('/loans/create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _KycRequiredEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: NexusSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 64,
              color: NexusColors.onSurfaceVariant,
            ),
            const SizedBox(height: NexusSpacing.stackLg),
            Text(
              'KYC requis',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: NexusSpacing.stackMd),
            Text(
              'Vérifiez votre identité pour accéder aux prêts Nexus.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NexusSpacing.stackXl),
            NexusButton(
              label: 'Vérifier mon identité',
              isFullWidth: false,
              onPressed: () => context.go('/kyc'),
            ),
          ],
        ),
      ),
    );
  }
}
