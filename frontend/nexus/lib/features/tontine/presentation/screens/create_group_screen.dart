import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/theme/app_spacing.dart';
import 'package:nexus/core/theme/widgets/nexus_button.dart';
import 'package:nexus/features/tontine/presentation/providers/tontine_provider.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contributionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _contributionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final contribution = int.tryParse(
      _contributionController.text.replaceAll(RegExp(r'\s'), ''),
    );
    if (contribution == null) return;

    final group = await ref.read(tontineProvider.notifier).createGroup(
          name: _nameController.text.trim(),
          monthlyContribution: contribution,
        );

    if (group != null && mounted) {
      context.go('/tontine/groups/${group.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(tontineProvider);

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
        title: const Text('Créer un groupe'),
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
                // ── Nom du groupe ──────────────────────────────────────────────
                Text('Nom du groupe', style: theme.textTheme.titleSmall),
                const SizedBox(height: NexusSpacing.stackMd),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Ex : Tontine Famille Mensuelle',
                    prefixIcon: Icon(Icons.group_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requis';
                    if (v.trim().length < 3) return 'Minimum 3 caractères';
                    if (v.trim().length > 150) return 'Maximum 150 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                // ── Cotisation mensuelle ───────────────────────────────────────
                Text(
                  'Cotisation mensuelle (FCFA)',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: NexusSpacing.stackMd),
                TextFormField(
                  controller: _contributionController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'Ex : 10 000',
                    prefixIcon: Icon(Icons.payments_outlined),
                    suffixText: 'FCFA',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    final n =
                        int.tryParse(v.replaceAll(RegExp(r'\s'), ''));
                    if (n == null) return 'Montant invalide';
                    if (n < 1000) return 'Minimum 1 000 FCFA';
                    return null;
                  },
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                NexusButton(
                  label: 'Créer le groupe',
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
