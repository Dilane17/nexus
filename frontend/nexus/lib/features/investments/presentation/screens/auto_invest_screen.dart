import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/theme/app_spacing.dart';
import 'package:nexus/core/theme/widgets/nexus_button.dart';
import 'package:nexus/core/theme/widgets/nexus_card.dart';
import 'package:nexus/features/investments/data/models/investment_models.dart';
import 'package:nexus/features/investments/presentation/providers/investment_provider.dart';

class AutoInvestScreen extends ConsumerStatefulWidget {
  const AutoInvestScreen({super.key});

  @override
  ConsumerState<AutoInvestScreen> createState() => _AutoInvestScreenState();
}

class _AutoInvestScreenState extends ConsumerState<AutoInvestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _maxAmountController = TextEditingController();
  final _minScoreController = TextEditingController();
  int _maxDuration = 12;
  bool _isActive = false;

  static const _durations = [3, 6, 9, 12, 18, 24];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(investmentProvider.notifier).loadAutoInvestRule();
      _prefillFromRule(ref.read(investmentProvider).autoInvestRule);
    });
  }

  void _prefillFromRule(AutoInvestRule? rule) {
    if (rule == null) return;
    _maxAmountController.text = rule.maxAmount.round().toString();
    _minScoreController.text = rule.minHybridScore.toString();
    setState(() {
      _maxDuration = rule.maxDuration;
      _isActive = rule.isActive;
    });
  }

  @override
  void dispose() {
    _maxAmountController.dispose();
    _minScoreController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final maxAmount = int.tryParse(
      _maxAmountController.text.replaceAll(RegExp(r'\s'), ''),
    );
    final minScore = num.tryParse(_minScoreController.text);
    if (maxAmount == null || minScore == null) return;

    final ok = await ref.read(investmentProvider.notifier).saveAutoInvestRule(
          AutoInvestRuleRequest(
            isActive: _isActive,
            maxAmount: maxAmount,
            maxDuration: _maxDuration,
            minHybridScore: minScore,
          ),
        );

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Règle Auto-Invest sauvegardée'),
          backgroundColor: NexusColors.success,
        ),
      );
    }
  }

  Future<void> _run() async {
    final ok = await ref.read(investmentProvider.notifier).runAutoInvest();
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auto-Invest exécuté'),
          backgroundColor: NexusColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        title: const Text('Auto-Invest'),
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
                // ── Toggle actif ───────────────────────────────────────────────
                NexusCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Activer Auto-Invest',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Investit automatiquement selon vos critères',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: NexusColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                // ── Montant max ────────────────────────────────────────────────
                Text(
                  'Montant maximum par investissement (FCFA)',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: NexusSpacing.stackMd),
                TextFormField(
                  controller: _maxAmountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'Ex : 50 000',
                    prefixIcon: Icon(Icons.payments_outlined),
                    suffixText: 'FCFA',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    final n =
                        int.tryParse(v.replaceAll(RegExp(r'\s'), ''));
                    if (n == null || n < 5000) return 'Minimum 5 000 FCFA';
                    return null;
                  },
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                // ── Durée max ──────────────────────────────────────────────────
                Text(
                  'Durée maximum (mois)',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: NexusSpacing.stackMd),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _durations.map((d) {
                    final selected = d == _maxDuration;
                    return GestureDetector(
                      onTap: () => setState(() => _maxDuration = d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
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
                          '$d mois',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: selected
                                ? Colors.white
                                : NexusColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                // ── Score minimum ──────────────────────────────────────────────
                Text(
                  'Score hybride minimum',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: NexusSpacing.stackMd),
                TextFormField(
                  controller: _minScoreController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Ex : 0.6 (entre 0 et 1)',
                    prefixIcon: Icon(Icons.score_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    final n = num.tryParse(v);
                    if (n == null) return 'Valeur invalide';
                    if (n < 0 || n > 1) return 'Entre 0 et 1';
                    return null;
                  },
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                // ── Sauvegarder ────────────────────────────────────────────────
                NexusButton(
                  label: 'Sauvegarder la règle',
                  isLoading: state.isSubmitting,
                  onPressed: state.isSubmitting ? null : _save,
                ),
                const SizedBox(height: NexusSpacing.stackMd),
                NexusButton(
                  label: 'Exécuter maintenant',
                  style: NexusButtonStyle.secondary,
                  isLoading: false,
                  onPressed: state.isSubmitting ? null : _run,
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
