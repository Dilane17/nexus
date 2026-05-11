import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/theme/app_spacing.dart';
import 'package:nexus/core/theme/widgets/nexus_button.dart';
import 'package:nexus/features/auth/presentation/providers/auth_provider.dart';
import 'package:nexus/features/kyc/presentation/providers/kyc_provider.dart';
import 'package:nexus/shared/models/app_enums.dart';

/// Écran affiché après la soumission du dossier.
/// Gère deux états : en attente de validation et rejeté.
class KycPendingScreen extends ConsumerWidget {
  const KycPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kycState = ref.watch(kycProvider);
    final user = ref.watch(authProvider).user;

    // Déduire l'état depuis le user (la source de vérité après session3)
    final isRejected = user?.kycStatus == KycStatus.rejected ||
        kycState.currentStep == KycStep.rejected;

    return PopScope(
      canPop: false, // Empêcher le retour arrière depuis cet écran
      child: Scaffold(
        backgroundColor: NexusColors.background,
        body: SafeArea(
          child: Padding(
            padding: NexusSpacing.screenPadding,
            child: isRejected
                ? _RejectedView(
                    reason: user?.kycStatus == KycStatus.rejected
                        ? kycState.rejectionReason
                        : null,
                    ref: ref,
                  )
                : _PendingView(),
          ),
        ),
      ),
    );
  }
}

// ── Vue : en attente ──────────────────────────────────────────────────────────

class _PendingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: NexusColors.warningContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.hourglass_top_rounded,
            size: 52,
            color: NexusColors.warning,
          ),
        ),
        const SizedBox(height: NexusSpacing.stackXl),
        Text(
          'Dossier en cours d\'analyse',
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: NexusSpacing.stackMd),
        Text(
          'Votre dossier KYC a été soumis avec succès.\n'
          'Notre équipe IMF le validera sous 24 à 48h ouvrées.\n'
          'Vous recevrez une notification dès que la décision sera prise.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        _InfoTile(
          icon: Icons.notifications_outlined,
          text: 'Notification à la validation',
        ),
        const SizedBox(height: NexusSpacing.stackMd),
        _InfoTile(
          icon: Icons.access_time_rounded,
          text: '24 à 48h ouvrées',
        ),
        const SizedBox(height: NexusSpacing.stackXl),
        NexusButton(
          label: 'Retour à l\'accueil',
          onPressed: () => context.go('/home'),
        ),
        const SizedBox(height: NexusSpacing.stackMd),
      ],
    );
  }
}

// ── Vue : rejeté ──────────────────────────────────────────────────────────────

class _RejectedView extends StatelessWidget {
  final String? reason;
  final WidgetRef ref;

  const _RejectedView({this.reason, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: NexusColors.errorContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.cancel_outlined,
            size: 52,
            color: NexusColors.error,
          ),
        ),
        const SizedBox(height: NexusSpacing.stackXl),
        Text(
          'Dossier rejeté',
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: NexusSpacing.stackMd),
        Text(
          'Votre dossier KYC n\'a pas été validé.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        if (reason != null && reason!.isNotEmpty) ...[
          const SizedBox(height: NexusSpacing.stackLg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NexusColors.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Motif du rejet',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: NexusColors.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: NexusColors.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
        const Spacer(),
        NexusButton(
          label: 'Corriger mon dossier',
          onPressed: () {
            // Recharger le statut puis retourner au début du KYC
            ref.read(kycProvider.notifier).loadStatus();
            context.go('/kyc/document');
          },
        ),
        const SizedBox(height: NexusSpacing.stackMd),
        NexusButton(
          label: 'Retour à l\'accueil',
          style: NexusButtonStyle.secondary,
          onPressed: () => context.go('/home'),
        ),
        const SizedBox(height: NexusSpacing.stackMd),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoTile({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: NexusColors.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
