import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/theme/app_spacing.dart';
import 'package:nexus/core/theme/widgets/nexus_button.dart';
import 'package:nexus/features/wallet/presentation/providers/transaction_provider.dart';
import 'package:nexus/shared/models/app_enums.dart';
import 'package:nexus/shared/widgets/nexus_momo_selector.dart';

class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  MomoProvider _provider = MomoProvider.mtnMomo;

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
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
        .deposit(
          amount: amount,
          provider: _provider,
          phone: _phoneController.text.trim(),
        );

    if (ok && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dépôt initié — en attente de confirmation MoMo'),
          backgroundColor: NexusColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
      appBar: AppBar(
        title: const Text('Déposer des fonds'),
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
                // ── Montant ───────────────────────────────────────────────────
                Text('Montant (FCFA)', style: theme.textTheme.titleSmall),
                const SizedBox(height: NexusSpacing.stackMd),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'Ex : 50 000',
                    prefixIcon: Icon(Icons.payments_outlined),
                    suffixText: 'FCFA',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    final n = int.tryParse(v.replaceAll(RegExp(r'\s'), ''));
                    if (n == null) return 'Montant invalide';
                    if (n < 1000) return 'Minimum 1 000 FCFA';
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

                // ── Numéro MoMo ───────────────────────────────────────────────
                Text('Numéro Mobile Money', style: theme.textTheme.titleSmall),
                const SizedBox(height: NexusSpacing.stackMd),
                TextFormField(
                  controller: _phoneController,
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
                  label: 'Confirmer le dépôt',
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
