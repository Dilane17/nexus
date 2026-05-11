import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/core/formatters/date_formatter.dart';
import 'package:nexus/core/formatters/money_formatter.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/theme/app_spacing.dart';
import 'package:nexus/core/theme/widgets/nexus_card.dart';
import 'package:nexus/core/theme/widgets/nexus_chip.dart';
import 'package:nexus/features/investments/presentation/providers/investment_provider.dart';
import 'package:nexus/shared/widgets/nexus_info_row.dart';

class InvestmentDetailScreen extends ConsumerStatefulWidget {
  final String investmentId;

  const InvestmentDetailScreen({super.key, required this.investmentId});

  @override
  ConsumerState<InvestmentDetailScreen> createState() =>
      _InvestmentDetailScreenState();
}

class _InvestmentDetailScreenState
    extends ConsumerState<InvestmentDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(investmentProvider.notifier)
          .loadInvestmentDetail(widget.investmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(investmentProvider);
    final inv = state.selectedInvestment;

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
        title: const Text('Détail investissement'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body:
          state.isDetailLoading
              ? const Center(child: CircularProgressIndicator())
              : inv == null
              ? const Center(child: Text('Investissement introuvable'))
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Montant investi',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                MoneyFormatter.format(inv.amount),
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(color: NexusColors.primary),
                              ),
                            ],
                          ),
                        ),
                        NexusStatusChip.fromInvestmentStatus(inv.status),
                      ],
                    ),
                    if (inv.isGuaranteed) ...[
                      const SizedBox(height: NexusSpacing.stackMd),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: NexusColors.successContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              size: 16,
                              color: NexusColors.success,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Garanti — Tier ${inv.guaranteeTier}',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: NexusColors.success),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: NexusSpacing.stackXl),

                    // ── Détails financiers ──────────────────────────────────
                    NexusCard(
                      child: Column(
                        children: [
                          NexusInfoRow(
                            label: 'Retour attendu',
                            value: MoneyFormatter.format(inv.expectedReturn),
                            valueColor: NexusColors.success,
                          ),
                          const Divider(height: 20),
                          NexusInfoRow(
                            label: 'Retour réel',
                            value: MoneyFormatter.format(inv.actualReturn),
                            valueColor:
                                inv.actualReturn > 0
                                    ? NexusColors.success
                                    : NexusColors.error,
                          ),
                          const Divider(height: 20),
                          NexusInfoRow(
                            label: 'Devise',
                            value: inv.currency.symbol,
                          ),
                          const Divider(height: 20),
                          NexusInfoRow(
                            label: 'Date de maturité',
                            value: DateFormatter.formatShort(inv.maturityDate),
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
}
