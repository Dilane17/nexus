import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/theme/app_spacing.dart';
import 'package:nexus/features/auth/presentation/providers/auth_provider.dart';
import 'package:nexus/features/auth/presentation/providers/user_profile_provider.dart';
import 'package:nexus/shared/models/app_enums.dart';
import 'package:nexus/shared/models/user_profile.dart';
import 'package:nexus/core/theme/widgets/nexus_card.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authProvider).user;
    final profile = ref.watch(profileProvider);

    // Ne devrait jamais être null ici (le router garantit l'auth)
    // mais on gère quand même un état de fallback.
    if (authUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Si le profil n'est pas encore chargé, afficher un loader
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Afficher le dashboard selon le rôle
    return _buildRoleBasedDashboard(context, ref, authUser, profile);
  }

  Widget _buildRoleBasedDashboard(
    BuildContext context,
    WidgetRef ref,
    dynamic authUser,
    UserProfile profile,
  ) {
    return switch (profile.role) {
      UserRole.borrower => _BorrowerDashboard(
        authUser: authUser,
        profile: profile,
      ),
      UserRole.investor => _InvestorDashboard(
        authUser: authUser,
        profile: profile,
      ),
      UserRole.admin => _AdminDashboard(authUser: authUser, profile: profile),
      UserRole.imfStaff => _ImfStaffDashboard(
        authUser: authUser,
        profile: profile,
      ),
      UserRole.agent => _AgentDashboard(authUser: authUser, profile: profile),
      UserRole.user => _UserDashboard(authUser: authUser, profile: profile),
    };
  }
}

// ── Borrower Dashboard ─────────────────────────────────────────────────────

class _BorrowerDashboard extends StatelessWidget {
  final dynamic authUser;
  final UserProfile profile;

  const _BorrowerDashboard({required this.authUser, required this.profile});

  @override
  Widget build(BuildContext context) {
    final borrowerData = profile.borrowerData;

    return Scaffold(
      backgroundColor: NexusColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: NexusSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeHeader(authUser: authUser),
              const SizedBox(height: NexusSpacing.stackLg),
              if (profile.needsKyc) ...[
                _KycBanner(status: profile.kycStatus),
                const SizedBox(height: NexusSpacing.stackLg),
              ],
              if (borrowerData != null) ...[
                _CreditScoreCard(score: borrowerData.creditScore),
                const SizedBox(height: NexusSpacing.stackLg),
              ],
              _QuickActionsGrid(profile: profile),
              const SizedBox(height: NexusSpacing.stackLg),
              _RecentActivitySection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreditScoreCard extends StatelessWidget {
  final num score;

  const _CreditScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fcfa = NumberFormat.decimalPattern('fr_FR');

    return NexusCard(
      useGradient: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Score de crédit', style: theme.textTheme.labelLarge),
              const Spacer(),
              const Icon(
                Icons.scoreboard_outlined,
                size: 18,
                color: NexusColors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: NexusSpacing.stackMd),
          Text(
            fcfa.format(score),
            style: theme.textTheme.displaySmall?.copyWith(
              color: NexusColors.primary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Basé sur votre historique de remboursement',
            style: theme.textTheme.labelSmall?.copyWith(
              color: NexusColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Investor Dashboard ─────────────────────────────────────────────────────

class _InvestorDashboard extends ConsumerWidget {
  final dynamic authUser;
  final UserProfile profile;

  const _InvestorDashboard({required this.authUser, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investorData = profile.investorData;

    return Scaffold(
      backgroundColor: NexusColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: NexusSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeHeader(authUser: authUser),
              const SizedBox(height: NexusSpacing.stackLg),
              if (profile.needsKyc) ...[
                _KycBanner(status: profile.kycStatus),
                const SizedBox(height: NexusSpacing.stackLg),
              ],
              if (investorData != null) ...[
                _InvestorStatsCard(investorData: investorData),
                const SizedBox(height: NexusSpacing.stackLg),
              ],
              _InvestorQuickActionsGrid(profile: profile),
              const SizedBox(height: NexusSpacing.stackLg),
              _RecentActivitySection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvestorStatsCard extends StatelessWidget {
  final InvestorData investorData;

  const _InvestorStatsCard({required this.investorData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fcfa = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );

    return NexusCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vos investissements', style: theme.textTheme.titleSmall),
          const SizedBox(height: NexusSpacing.stackMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(
                label: 'Solde',
                value: fcfa.format(investorData.walletBalance),
              ),
              _StatItem(
                label: 'Investi',
                value: fcfa.format(investorData.totalInvested),
              ),
              _StatItem(
                label: 'Gains',
                value: fcfa.format(investorData.totalReturns),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: NexusColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: NexusColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _InvestorQuickActionsGrid extends StatelessWidget {
  final UserProfile profile;

  const _InvestorQuickActionsGrid({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = [
      _Action(
        icon: Icons.add_circle_outline_rounded,
        label: 'Déposer',
        onTap: () => context.push('/investor/wallet/deposit'),
      ),
      _Action(
        icon: Icons.trending_up_rounded,
        label: 'Investir',
        onTap: () => context.push('/investor/marketplace'),
      ),
      _Action(
        icon: Icons.autorenew_rounded,
        label: 'Auto-invest',
        onTap: () => context.push('/investor/auto-invest'),
      ),
      _Action(
        icon: Icons.show_chart_rounded,
        label: 'Mes investissements',
        onTap: () => context.push('/investor/investments'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Actions rapides', style: theme.textTheme.titleSmall),
        const SizedBox(height: NexusSpacing.stackMd),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: actions.map((a) => _ActionButton(action: a)).toList(),
        ),
      ],
    );
  }
}

// ── Admin Dashboard ───────────────────────────────────────────────────────

class _AdminDashboard extends StatelessWidget {
  final dynamic authUser;
  final UserProfile profile;

  const _AdminDashboard({required this.authUser, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexusColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.admin_panel_settings,
                size: 64,
                color: NexusColors.primary,
              ),
              const SizedBox(height: NexusSpacing.stackLg),
              Text(
                'Dashboard Admin',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: NexusSpacing.stackMd),
              Text(
                'Fonctionnalité à venir',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── IMF Staff Dashboard ───────────────────────────────────────────────────

class _ImfStaffDashboard extends StatelessWidget {
  final dynamic authUser;
  final UserProfile profile;

  const _ImfStaffDashboard({required this.authUser, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexusColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business_center, size: 64, color: NexusColors.primary),
              const SizedBox(height: NexusSpacing.stackLg),
              Text(
                'Dashboard IMF',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: NexusSpacing.stackMd),
              Text(
                'Fonctionnalité à venir',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Agent Dashboard ───────────────────────────────────────────────────────

class _AgentDashboard extends StatelessWidget {
  final dynamic authUser;
  final UserProfile profile;

  const _AgentDashboard({required this.authUser, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexusColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.support_agent, size: 64, color: NexusColors.primary),
              const SizedBox(height: NexusSpacing.stackLg),
              Text(
                'Dashboard Agent',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: NexusSpacing.stackMd),
              Text(
                'Fonctionnalité à venir',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── User Dashboard (sans rôle) ──────────────────────────────────────────────

class _UserDashboard extends StatelessWidget {
  final dynamic authUser;
  final UserProfile profile;

  const _UserDashboard({required this.authUser, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexusColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: NexusSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeHeader(authUser: authUser),
              const SizedBox(height: NexusSpacing.stackLg),
              _KycBanner(status: profile.kycStatus),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  final dynamic authUser;

  const _HomeHeader({required this.authUser});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$_greeting,', style: theme.textTheme.bodyMedium),
              const SizedBox(height: NexusSpacing.stackXs),
              Text(authUser.firstName, style: theme.textTheme.headlineMedium),
            ],
          ),
        ),
        // Avatar / initiales
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: NexusColors.primaryFixed,
            child: Text(
              authUser.firstName.isNotEmpty
                  ? authUser.firstName[0].toUpperCase()
                  : 'N',
              style: theme.textTheme.titleMedium?.copyWith(
                color: NexusColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── KYC Banner ────────────────────────────────────────────────────────────────

class _KycBanner extends StatelessWidget {
  final KycStatus status;

  const _KycBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _kycConfig(status);

    return NexusCard(
      backgroundColor: config.bg,
      padding: const EdgeInsets.all(16),
      onTap: () => context.push('/kyc'),
      child: Row(
        children: [
          Icon(config.icon, color: config.fg, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: config.fg),
                ),
                const SizedBox(height: 2),
                Text(
                  config.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: config.fg.withAlpha(180),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: config.fg),
        ],
      ),
    );
  }

  ({Color bg, Color fg, IconData icon, String title, String subtitle})
  _kycConfig(KycStatus s) {
    return switch (s) {
      KycStatus.rejected => (
        bg: NexusColors.errorContainer,
        fg: NexusColors.onErrorContainer,
        icon: Icons.error_outline_rounded,
        title: 'Dossier rejeté',
        subtitle: 'Consultez le motif et corrigez votre dossier',
      ),
      KycStatus.session1Done => (
        bg: NexusColors.warningContainer,
        fg: NexusColors.warning,
        icon: Icons.hourglass_top_rounded,
        title: 'KYC en cours – Étape 2/3',
        subtitle: 'Renseignez vos informations financières',
      ),
      KycStatus.session2Done => (
        bg: NexusColors.warningContainer,
        fg: NexusColors.warning,
        icon: Icons.hourglass_bottom_rounded,
        title: 'KYC presque terminé – Étape 3/3',
        subtitle: 'Soumettez votre dossier pour validation',
      ),
      _ => (
        bg: NexusColors.infoContainer,
        fg: NexusColors.info,
        icon: Icons.verified_user_outlined,
        title: 'Vérifiez votre identité',
        subtitle: 'Nécessaire pour accéder aux prêts',
      ),
    };
  }
}

// ── Quick Actions ─────────────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  final UserProfile profile;

  const _QuickActionsGrid({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = [
      _Action(
        icon: Icons.add_circle_outline_rounded,
        label: 'Déposer',
        onTap: () => context.push('/wallet/deposit'),
      ),
      _Action(
        icon: Icons.remove_circle_outline_rounded,
        label: 'Retirer',
        onTap: () => context.push('/wallet/withdraw'),
      ),
      _Action(
        icon: Icons.handshake_outlined,
        label: 'Emprunter',
        enabled: profile.canAccessLoans,
        disabledHint: 'KYC requis',
        onTap: () => context.push('/loans/create'),
      ),
      _Action(
        icon: Icons.trending_up_rounded,
        label: 'Investir',
        onTap: () => context.push('/investments'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Actions rapides', style: theme.textTheme.titleSmall),
        const SizedBox(height: NexusSpacing.stackMd),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: actions.map((a) => _ActionButton(action: a)).toList(),
        ),
      ],
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final bool enabled;
  final String? disabledHint;
  final VoidCallback onTap;

  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.disabledHint,
  });
}

class _ActionButton extends StatelessWidget {
  final _Action action;

  const _ActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        action.enabled ? NexusColors.primary : NexusColors.onSurfaceVariant;

    return GestureDetector(
      onTap:
          action.enabled
              ? action.onTap
              : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(action.disabledHint ?? 'Non disponible'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color:
                  action.enabled
                      ? NexusColors.primaryFixed
                      : NexusColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(action.icon, color: color, size: 24),
          ),
          const SizedBox(height: NexusSpacing.stackXs),
          Text(
            action.label,
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ── Recent Activity ───────────────────────────────────────────────────────────

class _RecentActivitySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Activité récente', style: theme.textTheme.titleSmall),
            TextButton(
              onPressed: () => context.push('/wallet'),
              child: const Text('Tout voir'),
            ),
          ],
        ),
        const SizedBox(height: NexusSpacing.stackMd),
        NexusCard(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 40,
                    color: NexusColors.onSurfaceVariant,
                  ),
                  const SizedBox(height: NexusSpacing.stackMd),
                  Text(
                    'Aucune transaction récente',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vos transactions apparaîtront ici',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: NexusSpacing.stack2xl),
      ],
    );
  }
}
