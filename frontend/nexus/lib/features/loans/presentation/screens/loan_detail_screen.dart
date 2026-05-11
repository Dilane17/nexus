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
import 'package:nexus/features/loans/data/models/loan_models.dart';
import 'package:nexus/features/loans/presentation/providers/loan_provider.dart';
import 'package:nexus/shared/models/app_enums.dart';
import 'package:nexus/shared/widgets/nexus_info_row.dart';
import 'package:nexus/shared/widgets/nexus_momo_selector.dart';

class LoanDetailScreen extends ConsumerStatefulWidget {
  final String loanId;

  const LoanDetailScreen({super.key, required this.loanId});

  @override
  ConsumerState<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends ConsumerState<LoanDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loanProvider.notifier).loadLoanDetail(widget.loanId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loanProvider);
    final loan = state.selectedLoan;

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
        title: const Text('Détail du prêt'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body:
          state.isDetailLoading
              ? const Center(child: CircularProgressIndicator())
              : loan == null
              ? const Center(child: Text('Prêt introuvable'))
              : _LoanDetailBody(
                loan: loan,
                isSubmitting: state.isSubmitting,
                onRepay: () => _showRepaySheet(context, loan),
              ),
    );
  }

  void _showRepaySheet(BuildContext context, Loan loan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NexusColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RepaySheet(loan: loan, loanId: widget.loanId),
    );
  }
}

// ── Contenu principal ──────────────────────────────────────────────────────────

class _LoanDetailBody extends StatelessWidget {
  final Loan loan;
  final bool isSubmitting;
  final VoidCallback onRepay;

  const _LoanDetailBody({
    required this.loan,
    required this.isSubmitting,
    required this.onRepay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: NexusSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête montant + statut ────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Montant emprunté', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      MoneyFormatter.format(loan.amount),
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: NexusColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              NexusStatusChip.fromLoanStatus(loan.status),
            ],
          ),
          const SizedBox(height: NexusSpacing.stackXl),

          // ── Barre de progression (si actif ou en retard) ───────────────────
          if (loan.status == LoanStatus.active ||
              loan.status == LoanStatus.overdue) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Remboursement', style: theme.textTheme.titleSmall),
                Text(
                  '${(loan.repaidRatio * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: NexusColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: NexusSpacing.stackMd),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: loan.repaidRatio,
                backgroundColor: NexusColors.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(
                  loan.status == LoanStatus.overdue
                      ? NexusColors.error
                      : NexusColors.primary,
                ),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: NexusSpacing.stackXl),
          ],

          // ── Informations financières ────────────────────────────────────────
          NexusCard(
            child: Column(
              children: [
                NexusInfoRow(
                  label: 'Mensualité',
                  value: MoneyFormatter.format(loan.monthlyInstallment),
                ),
                const Divider(height: 20),
                NexusInfoRow(
                  label: 'Solde restant',
                  value: MoneyFormatter.format(loan.outstandingBalance),
                  valueColor:
                      loan.outstandingBalance > 0
                          ? NexusColors.warning
                          : NexusColors.success,
                ),
                const Divider(height: 20),
                NexusInfoRow(
                  label: 'Taux d\'intérêt',
                  value:
                      '${(loan.interestRate * 100).toStringAsFixed(1)}% / an',
                ),
                const Divider(height: 20),
                NexusInfoRow(
                  label: 'Durée',
                  value: '${loan.durationMonths} mois',
                ),
                if (loan.nextDueDate != null) ...[
                  const Divider(height: 20),
                  NexusInfoRow(
                    label: 'Prochaine échéance',
                    value: DateFormatter.formatShort(loan.nextDueDate!),
                    valueColor:
                        loan.status == LoanStatus.overdue
                            ? NexusColors.error
                            : NexusColors.onSurface,
                  ),
                ],
                if (loan.disbursedAt != null) ...[
                  const Divider(height: 20),
                  NexusInfoRow(
                    label: 'Date de décaissement',
                    value: DateFormatter.formatShort(loan.disbursedAt!),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: NexusSpacing.stackLg),

          // ── Objet du prêt ──────────────────────────────────────────────────
          if (loan.purpose != null && loan.purpose!.isNotEmpty) ...[
            Text('Objet du prêt', style: theme.textTheme.titleSmall),
            const SizedBox(height: NexusSpacing.stackMd),
            NexusCard(
              child: Text(loan.purpose!, style: theme.textTheme.bodyMedium),
            ),
            const SizedBox(height: NexusSpacing.stackLg),
          ],

          // ── Motif de rejet ────────────────────────────────────────────────
          if (loan.status == LoanStatus.cancelled &&
              loan.rejectionReason != null) ...[
            NexusCard(
              backgroundColor: NexusColors.errorContainer,
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: NexusColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loan.rejectionReason!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: NexusColors.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: NexusSpacing.stackLg),
          ],

          // ── CTA Rembourser ─────────────────────────────────────────────────
          if (loan.canRepay)
            NexusButton(
              label:
                  loan.status == LoanStatus.overdue
                      ? 'Régulariser le retard'
                      : 'Effectuer un remboursement',
              isLoading: isSubmitting,
              onPressed: isSubmitting ? null : onRepay,
            ),

          const SizedBox(height: NexusSpacing.stack2xl),
        ],
      ),
    );
  }
}

// ── Sheet de remboursement ────────────────────────────────────────────────────

class _RepaySheet extends ConsumerStatefulWidget {
  final Loan loan;
  final String loanId;

  const _RepaySheet({required this.loan, required this.loanId});

  @override
  ConsumerState<_RepaySheet> createState() => _RepaySheetState();
}

class _RepaySheetState extends ConsumerState<_RepaySheet> {
  MomoProvider _provider = MomoProvider.mtnMomo;
  final _amountController = TextEditingController();
  final _refController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.loan.monthlyInstallment.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.trim();
    final refText = _refController.text.trim();
    if (amountText.isEmpty || refText.isEmpty) return;
    final amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) return;
    final ok = await ref
        .read(loanProvider.notifier)
        .repayLoan(
          loanId: widget.loanId,
          amount: amount,
          momoReference: refText,
          provider: _provider,
        );
    if (ok && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remboursement initié avec succès'),
          backgroundColor: NexusColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(loanProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Remboursement', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Mensualité : ${MoneyFormatter.format(widget.loan.monthlyInstallment)}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: NexusSpacing.stackLg),

          // Sélecteur opérateur MoMo
          Text('Opérateur Mobile Money', style: theme.textTheme.titleSmall),
          const SizedBox(height: NexusSpacing.stackMd),
          NexusMomoSelector(
            selected: _provider,
            onChanged: (p) => setState(() => _provider = p),
          ),
          const SizedBox(height: NexusSpacing.stackLg),

          // Montant
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Montant (FCFA)',
              hintText: 'Ex : 35000',
              prefixIcon: Icon(Icons.monetization_on_outlined),
            ),
          ),
          const SizedBox(height: NexusSpacing.stackMd),

          // Référence MoMo
          TextField(
            controller: _refController,
            decoration: const InputDecoration(
              labelText: 'Référence transaction MoMo',
              hintText: 'Ex : MTN-20260418-ABC123',
              prefixIcon: Icon(Icons.receipt_outlined),
            ),
          ),
          const SizedBox(height: NexusSpacing.stackXl),

          NexusButton(
            label: 'Confirmer le remboursement',
            isLoading: state.isSubmitting,
            onPressed: state.isSubmitting ? null : _submit,
          ),
          const SizedBox(height: NexusSpacing.stackMd),
        ],
      ),
    );
  }
}
