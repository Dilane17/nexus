import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/core/formatters/money_formatter.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/theme/app_spacing.dart';
import 'package:nexus/core/theme/widgets/nexus_button.dart';
import 'package:nexus/core/theme/widgets/nexus_card.dart';
import 'package:nexus/features/investments/presentation/providers/investment_provider.dart';
import 'package:nexus/features/loans/presentation/providers/loan_provider.dart';

/// Écran d'investissement dans un prêt spécifique.
/// Route : /investments/invest/:loanId
class InvestInLoanScreen extends ConsumerStatefulWidget {
  final String loanId;

  const InvestInLoanScreen({super.key, required this.loanId});

  @override
  ConsumerState<InvestInLoanScreen> createState() => _InvestInLoanScreenState();
}

class _InvestInLoanScreenState extends ConsumerState<InvestInLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loanProvider.notifier).loadLoanDetail(widget.loanId);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = int.tryParse(
      _amountController.text.replaceAll(RegExp(r'\s'), ''),
    );
    if (amount == null) return;

    final ok = await ref
        .read(investmentProvider.notifier)
        .invest(loanId: widget.loanId, amount: amount);

    if (ok && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Investissement effectué avec succès'),
          backgroundColor: NexusColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loanState = ref.watch(loanProvider);
    final invState = ref.watch(investmentProvider);
    final loan = loanState.selectedLoan;

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
        title: const Text('Investir dans ce prêt'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body:
          loanState.isDetailLoading
              ? const Center(child: CircularProgressIndicator())
              : loan == null
              ? const Center(child: Text('Prêt introuvable'))
              : SafeArea(
                child: SingleChildScrollView(
                  padding: NexusSpacing.screenPadding,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Résumé prêt ──────────────────────────────────────
                        NexusCard(
                          backgroundColor: NexusColors.primaryFixed,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Prêt',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: NexusColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                MoneyFormatter.format(loan.amount),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: NexusColors.primary,
                                ),
                              ),
                              const SizedBox(height: NexusSpacing.stackMd),
                              Row(
                                children: [
                                  Text(
                                    '${(loan.interestRate * 100).toStringAsFixed(1)}% / an',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '${loan.durationMonths} mois',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: NexusSpacing.stackXl),

                        // ── Montant à investir ───────────────────────────────
                        Text(
                          'Montant à investir (FCFA)',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: NexusSpacing.stackMd),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            hintText: 'Min. 5 000 FCFA',
                            prefixIcon: Icon(Icons.payments_outlined),
                            suffixText: 'FCFA',
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requis';
                            final n = int.tryParse(
                              v.replaceAll(RegExp(r'\s'), ''),
                            );
                            if (n == null) return 'Montant invalide';
                            if (n < 5000) return 'Minimum 5 000 FCFA';
                            if (n > loan.amount) {
                              return 'Dépasse le montant du prêt';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: NexusSpacing.stackXl),

                        NexusButton(
                          label: 'Confirmer l\'investissement',
                          isLoading: invState.isSubmitting,
                          onPressed: invState.isSubmitting ? null : _submit,
                        ),
                        const SizedBox(height: NexusSpacing.stack2xl),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
