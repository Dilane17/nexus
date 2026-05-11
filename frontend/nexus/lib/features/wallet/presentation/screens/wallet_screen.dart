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
import 'package:nexus/features/auth/presentation/providers/user_profile_provider.dart';
import 'package:nexus/features/wallet/data/models/transaction_models.dart';
import 'package:nexus/features/wallet/presentation/providers/transaction_provider.dart';
import 'package:nexus/shared/models/app_enums.dart';
import 'package:nexus/shared/widgets/nexus_skeleton_patterns.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionProvider.notifier).loadTransactions();
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
      ref.read(transactionProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionProvider);

    ref.listen(transactionProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: NexusColors.error,
          ),
        );
        ref.read(transactionProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: NexusColors.background,
      appBar: AppBar(title: const Text('Portefeuille')),
      body: RefreshIndicator(
        onRefresh:
            () => ref.read(transactionProvider.notifier).loadTransactions(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: NexusSpacing.screenPadding,
                child: Column(
                  children: [
                    _BalanceCard(
                      balance:
                          ref
                              .watch(userProfileProvider)
                              .value
                              ?.investorData
                              ?.walletBalance ??
                          0,
                    ),
                    const SizedBox(height: NexusSpacing.stackLg),
                    _ActionRow(),
                    const SizedBox(height: NexusSpacing.stackXl),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Historique',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(height: NexusSpacing.stackMd),
                    _FilterChips(
                      selected: state.selectedType,
                      onSelected:
                          (type) => ref
                              .read(transactionProvider.notifier)
                              .filterByType(type),
                    ),
                    const SizedBox(height: NexusSpacing.stackMd),
                  ],
                ),
              ),
            ),
            if (state.isLoading && state.transactions.isEmpty)
              const SliverToBoxAdapter(child: NexusListSkeleton())
            else if (state.transactions.isEmpty)
              const SliverToBoxAdapter(child: _EmptyHistory())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index == state.transactions.length) {
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
                    child: _TransactionTile(
                      transaction: state.transactions[index],
                    ),
                  );
                }, childCount: state.transactions.length + 1),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Chips ──────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final TransactionType? selected;
  final ValueChanged<TransactionType?> onSelected;

  const _FilterChips({required this.selected, required this.onSelected});

  static const _filters = [
    (null, 'Tous'),
    (TransactionType.investorDeposit, 'Dépôts'),
    (TransactionType.investorWithdrawal, 'Retraits'),
    (TransactionType.loanRepayment, 'Remboursements'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            _filters.map((entry) {
              final (type, label) = entry;
              final isActive = selected == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(label),
                  selected: isActive,
                  onSelected: (_) => onSelected(type),
                  selectedColor: NexusColors.primaryFixed,
                  checkmarkColor: NexusColors.primary,
                  labelStyle: TextStyle(
                    color:
                        isActive
                            ? NexusColors.primary
                            : NexusColors.onSurfaceVariant,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

// ── Balance Card ──────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final num balance;

  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NexusCard(
      useGradient: true,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Solde disponible',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: NexusColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: NexusColors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: NexusSpacing.stackMd),
          Text(
            MoneyFormatter.format(balance),
            style: theme.textTheme.displaySmall?.copyWith(
              color: NexusColors.primary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Calculé sur les transactions confirmées',
            style: theme.textTheme.labelSmall?.copyWith(
              color: NexusColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Row ────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: NexusButton(
            label: 'Déposer',
            icon: Icons.add_rounded,
            onPressed: () => context.push('/wallet/deposit'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: NexusButton(
            label: 'Retirer',
            icon: Icons.remove_rounded,
            style: NexusButtonStyle.secondary,
            onPressed: () => context.push('/wallet/withdraw'),
          ),
        ),
      ],
    );
  }
}

// ── Transaction Tile ──────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDebit = transaction.isDebit;
    final amountColor = isDebit ? NexusColors.error : NexusColors.success;
    final amountPrefix = isDebit ? '– ' : '+ ';

    return NexusCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  isDebit
                      ? NexusColors.errorContainer
                      : NexusColors.successContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _iconFor(transaction.type),
              size: 20,
              color: amountColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.type.displayName,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormatter.formatWithTime(transaction.initiatedAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: NexusColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$amountPrefix${MoneyFormatter.format(transaction.amount)}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              NexusStatusChip.fromTransactionStatus(transaction.status),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(TransactionType type) {
    return switch (type) {
      TransactionType.investorDeposit => Icons.arrow_downward_rounded,
      TransactionType.investorWithdrawal => Icons.arrow_upward_rounded,
      TransactionType.loanDisbursement => Icons.handshake_outlined,
      TransactionType.loanRepayment => Icons.replay_rounded,
      TransactionType.platformCommission => Icons.percent_rounded,
      TransactionType.guaranteeActivation => Icons.shield_outlined,
      TransactionType.imfRepurchase => Icons.swap_horiz_rounded,
      TransactionType.agentCommission => Icons.person_outlined,
    };
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

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
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: NexusColors.onSurfaceVariant,
                ),
                const SizedBox(height: NexusSpacing.stackMd),
                Text(
                  'Aucune transaction',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Commencez par déposer des fonds',
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
