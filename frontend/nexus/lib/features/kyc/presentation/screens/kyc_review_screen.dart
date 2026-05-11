import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/theme/app_spacing.dart';
import 'package:nexus/core/theme/widgets/nexus_button.dart';
import 'package:nexus/core/theme/widgets/nexus_card.dart';
import 'package:nexus/features/kyc/presentation/providers/kyc_provider.dart';
import 'package:nexus/features/kyc/presentation/widgets/kyc_progress_bar.dart';

class KycReviewScreen extends ConsumerWidget {
  const KycReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final kycState = ref.watch(kycProvider);

    ref.listen(kycProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: NexusColors.error,
          ),
        );
        ref.read(kycProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: NexusColors.background,
      appBar: AppBar(
        title: const Text('Récapitulatif'),
        leading: BackButton(onPressed: () => context.go('/kyc/financial')),
      ),
      body: SafeArea(
        child: Padding(
          padding: NexusSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const KycProgressBar(step: 3),
              const SizedBox(height: NexusSpacing.stackXl),

              Text(
                'Vérifiez vos informations',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: NexusSpacing.stackMd),
              Text(
                'Assurez-vous que tout est correct avant de soumettre.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: NexusSpacing.stackXl),

              // Récapitulatif section 1
              NexusCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(title: 'Document d\'identité', step: 1),
                    const Divider(height: 24),
                    _ReviewRow(
                      label: 'Type',
                      value: kycState.documentType ?? '—',
                    ),
                    const SizedBox(height: 8),
                    _ReviewRow(
                      label: 'Document',
                      value: kycState.documentUrl != null ? 'Uploadé ✓' : '—',
                      valueColor: kycState.documentUrl != null
                          ? NexusColors.success
                          : null,
                    ),
                    const SizedBox(height: 8),
                    _ReviewRow(
                      label: 'Selfie',
                      value: kycState.selfieUrl != null ? 'Uploadé ✓' : '—',
                      valueColor: kycState.selfieUrl != null
                          ? NexusColors.success
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: NexusSpacing.stackMd),

              // Récapitulatif section 2
              NexusCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(title: 'Informations financières', step: 2),
                    const Divider(height: 24),
                    _ReviewRow(
                      label: 'Revenu mensuel',
                      value: kycState.documentType != null
                          ? 'Renseigné ✓'
                          : '—',
                    ),
                    const SizedBox(height: 8),
                    _ReviewRow(
                      label: 'Relevé MoMo',
                      value: kycState.momoStatementUrl != null
                          ? 'Fourni ✓'
                          : 'Non fourni',
                      valueColor: kycState.momoStatementUrl != null
                          ? NexusColors.success
                          : NexusColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Avertissement
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NexusColors.warningContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: NexusColors.warning, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'La validation prend 24 à 48 heures ouvrées.',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: NexusColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: NexusSpacing.stackMd),

              NexusButton(
                label: 'Soumettre le dossier',
                isLoading: kycState.isLoading,
                onPressed: kycState.isLoading
                    ? null
                    : () async {
                        final ok = await ref
                            .read(kycProvider.notifier)
                            .submitSession3();
                        if (ok && context.mounted) {
                          context.go('/kyc/pending');
                        }
                      },
              ),
              const SizedBox(height: NexusSpacing.stackMd),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int step;

  const _SectionHeader({required this.title, required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: NexusColors.primaryFixed,
          child: Text(
            '$step',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: NexusColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const Spacer(),
        GestureDetector(
          onTap: () => context
              .go(step == 1 ? '/kyc/document' : '/kyc/financial'),
          child: Text(
            'Modifier',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: NexusColors.primary,
                ),
          ),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ReviewRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            color: valueColor ?? NexusColors.onSurface,
          ),
        ),
      ],
    );
  }
}
