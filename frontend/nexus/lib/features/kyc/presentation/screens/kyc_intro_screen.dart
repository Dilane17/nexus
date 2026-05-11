import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/theme/app_spacing.dart';
import 'package:nexus/core/theme/widgets/nexus_button.dart';
import 'package:nexus/features/kyc/presentation/providers/kyc_provider.dart';

class KycIntroScreen extends ConsumerWidget {
  const KycIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: NexusColors.background,
      appBar: AppBar(
        title: const Text('Vérification d\'identité'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: NexusSpacing.screenPadding,
          child: Column(
            children: [
              const Spacer(),
              // Illustration
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: NexusColors.primaryFixed,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  size: 52,
                  color: NexusColors.primary,
                ),
              ),
              const SizedBox(height: NexusSpacing.stackXl),
              Text(
                'Vérifiez votre identité',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: NexusSpacing.stackMd),
              Text(
                'La vérification KYC est obligatoire pour accéder aux prêts.\n'
                'Le processus prend moins de 5 minutes.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: NexusSpacing.stackXl),

              // Étapes
              _KycStep(
                number: '1',
                title: 'Document d\'identité',
                subtitle: 'Photo de votre CNI, passeport ou permis',
              ),
              const SizedBox(height: NexusSpacing.stackMd),
              _KycStep(
                number: '2',
                title: 'Informations financières',
                subtitle: 'Revenus mensuels et source de revenus',
              ),
              const SizedBox(height: NexusSpacing.stackMd),
              _KycStep(
                number: '3',
                title: 'Soumission',
                subtitle: 'Validation par l\'IMF sous 24–48h',
              ),
              const Spacer(),
              NexusButton(
                label: 'Commencer la vérification',
                onPressed: () {
                  // Charger le statut pour reprendre au bon endroit
                  ref.read(kycProvider.notifier).loadStatus();
                  context.go('/kyc/document');
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

class _KycStep extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;

  const _KycStep({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: NexusColors.primaryFixed,
          child: Text(
            number,
            style: theme.textTheme.labelLarge?.copyWith(
              color: NexusColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: NexusSpacing.stackMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
