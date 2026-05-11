import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/core/formatters/date_formatter.dart';
import 'package:nexus/core/formatters/money_formatter.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/theme/app_spacing.dart';
import 'package:nexus/core/theme/widgets/nexus_button.dart';
import 'package:nexus/features/tontine/presentation/providers/tontine_provider.dart';

class CreateCycleScreen extends ConsumerStatefulWidget {
  final String groupId;

  const CreateCycleScreen({super.key, required this.groupId});

  @override
  ConsumerState<CreateCycleScreen> createState() => _CreateCycleScreenState();
}

class _CreateCycleScreenState extends ConsumerState<CreateCycleScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _beneficiaryId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(tontineProvider);
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
        title: const Text('Créer un cycle'),
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
                // ── Groupe info ──────────────────────────────────────────────
                if (group != null) ...[
                  Text(
                    'Groupe : ${group.name}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: NexusColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Cotisation mensuelle : ${MoneyFormatter.format(group.monthlyContribution)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: NexusColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: NexusSpacing.stackXl),
                ],

                // ── Date de début ─────────────────────────────────────────────
                Text('Date de début', style: theme.textTheme.titleSmall),
                const SizedBox(height: NexusSpacing.stackMd),
                InkWell(
                  onTap: () => _pickStartDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: NexusColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            _startDate == null
                                ? NexusColors.outline
                                : NexusColors.primary,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: NexusColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _startDate == null
                                ? 'Sélectionner une date'
                                : DateFormatter.formatShort(_startDate!),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  _startDate == null
                                      ? NexusColors.onSurfaceVariant
                                      : NexusColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                // ── Date de fin ───────────────────────────────────────────────
                Text('Date de fin', style: theme.textTheme.titleSmall),
                const SizedBox(height: NexusSpacing.stackMd),
                InkWell(
                  onTap: () => _pickEndDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: NexusColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            _endDate == null
                                ? NexusColors.outline
                                : NexusColors.primary,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: NexusColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _endDate == null
                                ? 'Sélectionner une date'
                                : DateFormatter.formatShort(_endDate!),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  _endDate == null
                                      ? NexusColors.onSurfaceVariant
                                      : NexusColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                // ── Bénéficiaire ──────────────────────────────────────────────
                Text('Bénéficiaire', style: theme.textTheme.titleSmall),
                const SizedBox(height: NexusSpacing.stackMd),
                if (group?.members.isEmpty ?? true)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: NexusColors.warningContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Aucun membre dans ce groupe',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: NexusColors.warning,
                      ),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _beneficiaryId,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_outline),
                      hintText: 'Sélectionner le bénéficiaire',
                    ),
                    items:
                        group?.members.map((member) {
                          return DropdownMenuItem<String>(
                            value: member.userId,
                            child: Text('${member.name} (${member.phone})'),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _beneficiaryId = value;
                      });
                    },
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requis';
                      return null;
                    },
                  ),
                const SizedBox(height: NexusSpacing.stackXl),

                NexusButton(
                  label: 'Créer le cycle',
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

  Future<void> _pickStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Reset end date if it's before new start date
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez d\'abord la date de début'),
          backgroundColor: NexusColors.warning,
        ),
      );
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate!.add(const Duration(days: 30)),
      firstDate: _startDate!.add(const Duration(days: 1)),
      lastDate: _startDate!.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner les dates'),
          backgroundColor: NexusColors.error,
        ),
      );
      return;
    }
    if (_endDate!.isBefore(_startDate!) ||
        _endDate!.isAtSameMomentAs(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La date de fin doit être après la date de début'),
          backgroundColor: NexusColors.error,
        ),
      );
      return;
    }

    final state = ref.read(tontineProvider);
    final nextCycleNumber = (state.selectedGroup?.cycles.length ?? 0) + 1;

    final cycle = await ref
        .read(tontineProvider.notifier)
        .createCycle(
          groupId: widget.groupId,
          cycleNumber: nextCycleNumber,
          startDate: _startDate!,
          endDate: _endDate!,
          beneficiaryId: _beneficiaryId!,
        );

    if (cycle != null && mounted) {
      // Refresh group details to get updated cycles
      await ref.read(tontineProvider.notifier).loadGroupDetail(widget.groupId);
      await ref.read(tontineProvider.notifier).loadCycles(widget.groupId);
      if (mounted) {
        context.pop();
      }
    }
  }
}
