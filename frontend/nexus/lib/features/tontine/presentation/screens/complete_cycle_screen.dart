import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/core/formatters/date_formatter.dart';
import 'package:nexus/core/formatters/money_formatter.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/theme/app_spacing.dart';
import 'package:nexus/core/theme/widgets/nexus_button.dart';
import 'package:nexus/core/theme/widgets/nexus_card.dart';
import 'package:nexus/features/tontine/presentation/providers/tontine_provider.dart';

class CompleteCycleScreen extends ConsumerStatefulWidget {
  final String cycleId;

  const CompleteCycleScreen({super.key, required this.cycleId});

  @override
  ConsumerState<CompleteCycleScreen> createState() =>
      _CompleteCycleScreenState();
}

class _CompleteCycleScreenState extends ConsumerState<CompleteCycleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _membersPaidController = TextEditingController();
  final _membersDefaultedController = TextEditingController();
  final _totalCollectedController = TextEditingController();
  num _monthlyContribution = 0;
  int _totalMembers = 0;
  late String _groupId;

  @override
  void initState() {
    super.initState();
    _groupId = GoRouterState.of(context).extra as String? ?? '';
    _initializeData();
  }

  void _initializeData() {
    final state = ref.read(tontineProvider);
    final group = state.selectedGroup;

    if (group != null) {
      _monthlyContribution = group.monthlyContribution;
      _totalMembers = group.memberCount;
    }
  }

  @override
  void dispose() {
    _membersPaidController.dispose();
    _membersDefaultedController.dispose();
    _totalCollectedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(tontineProvider);
    final cycle = state.cycles.firstWhere((c) => c.id == widget.cycleId);
    final group = state.selectedGroup;

    ref.listen(tontineProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: NexusColors.error,
          ),
        );
        ref.read(tontineProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: NexusColors.background,
      appBar: AppBar(
        title: const Text('Clôturer le cycle'),
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
                // ── Cycle info ──────────────────────────────────────────────
                NexusCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cycle ${cycle.cycleNumber}',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: NexusSpacing.stackMd),
                      Text(
                        '${DateFormatter.formatShort(cycle.startDate)} – ${DateFormatter.formatShort(cycle.endDate)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: NexusColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: NexusSpacing.stackMd),
                      if (group != null) ...[
                        Text(
                          'Cotisation mensuelle : ${MoneyFormatter.format(group.monthlyContribution)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: NexusColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'Membres du groupe : ${group.memberCount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: NexusColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                // ── Membres ayant payé ────────────────────────────────────────
                Text('Membres ayant payé', style: theme.textTheme.titleSmall),
                const SizedBox(height: NexusSpacing.stackMd),
                TextFormField(
                  controller: _membersPaidController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'Ex : 5',
                    prefixIcon: Icon(Icons.check_circle_outline),
                    suffixText: 'membres',
                  ),
                  onChanged: (_) => _updateTotalCollected(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    final n = int.tryParse(v);
                    if (n == null) return 'Nombre invalide';
                    if (n < 0) return 'Doit être positif';
                    if (n > _totalMembers) {
                      return 'Ne peut pas dépasser $_totalMembers membres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                // ── Membres en défaut ─────────────────────────────────────────
                Text('Membres en défaut', style: theme.textTheme.titleSmall),
                const SizedBox(height: NexusSpacing.stackMd),
                TextFormField(
                  controller: _membersDefaultedController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'Ex : 1',
                    prefixIcon: Icon(Icons.cancel_outlined),
                    suffixText: 'membres',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    final n = int.tryParse(v);
                    if (n == null) return 'Nombre invalide';
                    if (n < 0) return 'Doit être positif';
                    return null;
                  },
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                // ── Total collecté ────────────────────────────────────────────
                Text(
                  'Total collecté (FCFA)',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: NexusSpacing.stackMd),
                TextFormField(
                  controller: _totalCollectedController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'Calculé automatiquement',
                    prefixIcon: Icon(Icons.payments_outlined),
                    suffixText: 'FCFA',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    final n = int.tryParse(v);
                    if (n == null) return 'Montant invalide';
                    if (n < 0) return 'Doit être positif';
                    return null;
                  },
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                // ── Validation ────────────────────────────────────────────────
                NexusCard(
                  backgroundColor: NexusColors.infoContainer,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: NexusColors.info,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Le score tontine sera mis à jour après clôture',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: NexusColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                NexusButton(
                  label: 'Clôturer le cycle',
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

  void _updateTotalCollected() {
    final paid = int.tryParse(_membersPaidController.text) ?? 0;
    final total = paid * _monthlyContribution;
    _totalCollectedController.text = total.toString();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final paid = int.tryParse(_membersPaidController.text) ?? 0;
    final defaulted = int.tryParse(_membersDefaultedController.text) ?? 0;
    final total =
        int.tryParse(
          _totalCollectedController.text.replaceAll(RegExp(r'\s'), ''),
        ) ??
        0;

    // Validate that paid + defaulted doesn't exceed total members
    if (paid + defaulted > _totalMembers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Le total des membres ($paid + $defaulted = ${paid + defaulted}) ne peut pas dépasser $_totalMembers',
          ),
          backgroundColor: NexusColors.error,
        ),
      );
      return;
    }

    final updatedCycle = await ref
        .read(tontineProvider.notifier)
        .completeCycle(
          cycleId: widget.cycleId,
          membersPaid: paid,
          membersDefaulted: defaulted,
          totalCollected: total,
        );

    if (updatedCycle != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cycle clôturé avec succès'),
          backgroundColor: NexusColors.success,
        ),
      );
      // Refresh group details
      await ref.read(tontineProvider.notifier).loadGroupDetail(_groupId);
      await ref.read(tontineProvider.notifier).loadCycles(_groupId);
      if (mounted) {
        context.pop();
      }
    }
  }
}
