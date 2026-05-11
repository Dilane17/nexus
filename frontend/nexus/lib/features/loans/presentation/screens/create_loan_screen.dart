import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/theme/app_spacing.dart';
import 'package:nexus/core/theme/widgets/nexus_button.dart';
import 'package:nexus/core/theme/widgets/nexus_card.dart';
import 'package:nexus/core/theme/widgets/nexus_input.dart';
import 'package:nexus/features/loans/presentation/providers/loan_provider.dart';

class CreateLoanScreen extends ConsumerStatefulWidget {
  const CreateLoanScreen({super.key});

  @override
  ConsumerState<CreateLoanScreen> createState() => _CreateLoanScreenState();
}

class _CreateLoanScreenState extends ConsumerState<CreateLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  int _selectedDuration = 6; // mois

  static const _durations = [3, 6, 9, 12];
  static const _minAmount = 25000;
  static const _maxAmount = 500000;

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = int.tryParse(
      _amountController.text.replaceAll(RegExp(r'\s'), ''),
    );
    if (amount == null) return;

    final loan = await ref.read(loanProvider.notifier).createLoan(
          amount: amount,
          durationMonths: _selectedDuration,
          purpose: _purposeController.text.trim(),
        );

    if (loan != null && mounted) {
      context.go('/loans/${loan.id}');
    }
  }

  /// Calcule une mensualité estimée (intérêts fixe 15% pour simulation UI).
  String get _estimatedInstallment {
    final amount =
        int.tryParse(_amountController.text.replaceAll(RegExp(r'\s'), ''));
    if (amount == null || amount == 0) return '—';
    const rate = 0.15;
    // Mensualité simplifiée : principal + intérêts linéaires du mois
    final simple = (amount / _selectedDuration) + (amount * (rate / 12));
    return '≈ ${simple.round()} FCFA / mois';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(loanProvider);

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
        title: const Text('Nouvelle demande de prêt'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: NexusSpacing.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Montant ──────────────────────────────────────────────────
                NexusInput(
                  label: 'Montant souhaité (FCFA)',
                  hint: '25 000 – 500 000',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    final n = int.tryParse(v.replaceAll(RegExp(r'\s'), ''));
                    if (n == null) return 'Montant invalide';
                    if (n < _minAmount) return 'Minimum $_minAmount FCFA';
                    if (n > _maxAmount) return 'Maximum $_maxAmount FCFA';
                    return null;
                  },
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                // ── Durée ────────────────────────────────────────────────────
                Text('Durée de remboursement', style: theme.textTheme.titleSmall),
                const SizedBox(height: NexusSpacing.stackMd),
                Row(
                  children: _durations.map((d) {
                    final selected = d == _selectedDuration;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedDuration = d),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? NexusColors.primary
                                : NexusColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? NexusColors.primary
                                  : NexusColors.outlineVariant,
                            ),
                          ),
                          child: Text(
                            '$d\nmois',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: selected
                                  ? Colors.white
                                  : NexusColors.onSurfaceVariant,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                // ── Simulation mensualité ─────────────────────────────────────
                NexusCard(
                  backgroundColor: NexusColors.primaryFixed,
                  child: Row(
                    children: [
                      const Icon(Icons.calculate_outlined,
                          color: NexusColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mensualité estimée',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: NexusColors.onPrimaryFixed,
                            ),
                          ),
                          Text(
                            _estimatedInstallment,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: NexusColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        'Simulation\nnon contractuelle',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: NexusColors.onSurfaceVariant,
                          fontSize: 9,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                // ── Objet du prêt ─────────────────────────────────────────────
                NexusInput(
                  label: 'Objet du prêt',
                  hint: 'Décrivez l\'usage prévu (achat matériel, fonds de commerce…)',
                  controller: _purposeController,
                  maxLines: 4,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requis';
                    if (v.trim().length < 10) {
                      return 'Minimum 10 caractères';
                    }
                    if (v.trim().length > 500) {
                      return 'Maximum 500 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                // ── Note BCEAO ────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: NexusColors.infoContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: NexusColors.info, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Taux BCEAO : max 18% / an. '
                          'Le taux exact sera fixé par l\'IMF après validation.',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: NexusColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                NexusButton(
                  label: 'Soumettre la demande',
                  isLoading: state.isSubmitting,
                  onPressed: state.isSubmitting ? null : _submit,
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
