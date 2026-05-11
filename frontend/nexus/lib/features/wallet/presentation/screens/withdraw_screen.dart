import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/core/formatters/money_formatter.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/theme/app_spacing.dart';
import 'package:nexus/core/theme/widgets/nexus_button.dart';
import 'package:nexus/core/theme/widgets/nexus_card.dart';
import 'package:nexus/features/auth/presentation/providers/user_profile_provider.dart';
import 'package:nexus/features/wallet/presentation/providers/transaction_provider.dart';
import 'package:nexus/shared/models/app_enums.dart';
import 'package:nexus/shared/widgets/nexus_momo_selector.dart';

class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _numberController = TextEditingController();
  MomoProvider _provider = MomoProvider.mtnMomo;

  @override
  void dispose() {
    _amountController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = int.tryParse(
      _amountController.text.replaceAll(RegExp(r'\s'), ''),
    );
    if (amount == null) return;

    final ok = await ref
        .read(transactionProvider.notifier)
        .withdraw(
          amount: amount,
          provider: _provider,
          number: _numberController.text.trim(),
        );

    if (ok && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Retrait initié — en attente de confirmation MoMo'),
          backgroundColor: NexusColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(transactionProvider);
    final balance =
        ref
            .watch(userProfileProvider)
            .value
            ?.investorData
            ?.walletBalance ??
        0;

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
      appBar: AppBar(
        title: const Text('Retirer des fonds'),
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
                // ── Solde disponible ──────────────────────────────────────────
                NexusCard(
                  backgroundColor: NexusColors.surfaceContainerLow,
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 20,
                        color: NexusColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Solde disponible',
                            style: theme.textTheme.labelSmall,
                          ),
                          Text(
                            MoneyFormatter.format(balance),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: NexusColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                // ── Montant ───────────────────────────────────────────────────
                Text('Montant (FCFA)', style: theme.textTheme.titleSmall),
                const SizedBox(height: NexusSpacing.stackMd),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'Ex : 25 000',
                    prefixIcon: Icon(Icons.payments_outlined),
                    suffixText: 'FCFA',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    final n = int.tryParse(v.replaceAll(RegExp(r'\s'), ''));
                    if (n == null) return 'Montant invalide';
                    if (n < 1000) return 'Minimum 1 000 FCFA';
                    if (n > balance) return 'Solde insuffisant';
                    return null;
                  },
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                // ── Opérateur ─────────────────────────────────────────────────
                Text(
                  'Opérateur Mobile Money',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: NexusSpacing.stackMd),
                NexusMomoSelector(
                  selected: _provider,
                  onChanged: (p) => setState(() => _provider = p),
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                // ── Numéro destinataire ───────────────────────────────────────
                Text('Numéro destinataire', style: theme.textTheme.titleSmall),
                const SizedBox(height: NexusSpacing.stackMd),
                TextFormField(
                  controller: _numberController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Ex : +22997000000',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requis';
                    if (v.trim().length < 8) return 'Numéro trop court';
                    return null;
                  },
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                NexusButton(
                  label: 'Confirmer le retrait',
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
