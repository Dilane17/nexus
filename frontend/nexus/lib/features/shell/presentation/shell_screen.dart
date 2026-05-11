import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/navigation/role_navigation.dart';
import 'package:nexus/features/auth/presentation/providers/user_profile_provider.dart';
import 'package:nexus/shared/models/app_enums.dart';

/// Squelette principal de l'app après authentification.
/// Il contient la BottomNavigationBar dynamique selon le rôle
/// et délègue le contenu à la branche active via [StatefulNavigationShell].
class ShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final role = profile?.role ?? UserRole.user;

    // Si le profil n'est pas encore chargé, afficher un loader
    if (profile == null) {
      return Scaffold(body: const Center(child: CircularProgressIndicator()));
    }

    final navConfig = RoleNavigationConfigs.getConfigForRole(role);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar:
          navConfig.bottomNavItems.isEmpty
              ? null // Pas de bottom nav pour les users sans rôle spécifique
              : _NexusBottomNav(
                currentIndex: navigationShell.currentIndex,
                items: navConfig.bottomNavItems,
                onTap:
                    (index) => navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    ),
              ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────

class _NexusBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<NavigationItem> items;
  final void Function(int) onTap;

  const _NexusBottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: NexusColors.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      indicatorColor: NexusColors.primaryFixed,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations:
          items
              .map(
                (item) => NavigationDestination(
                  icon: Icon(_getIcon(item.icon, false)),
                  selectedIcon: Icon(
                    _getIcon(item.activeIcon, true),
                    color: NexusColors.primary,
                  ),
                  label: item.label,
                ),
              )
              .toList(),
    );
  }

  IconData _getIcon(String iconName, bool isSelected) {
    // Mapping simple des noms d'icônes en IconData
    // En production, utiliser un système plus robuste
    return switch (iconName) {
      'home_outlined' => Icons.home_outlined,
      'home' => Icons.home,
      'payments_outlined' => Icons.payments_outlined,
      'payments' => Icons.payments,
      'trending_up_outlined' => Icons.trending_up_outlined,
      'trending_up' => Icons.trending_up,
      'people_outline' => Icons.people_outline,
      'people' => Icons.people,
      'account_balance_wallet_outlined' =>
        Icons.account_balance_wallet_outlined,
      'account_balance_wallet' => Icons.account_balance_wallet,
      'show_chart_outlined' => Icons.show_chart_outlined,
      'show_chart' => Icons.show_chart,
      'autorenew_outlined' => Icons.autorenew_outlined,
      'autorenew' => Icons.autorenew,
      'dashboard_outlined' => Icons.dashboard_outlined,
      'dashboard' => Icons.dashboard,
      'verified_user_outlined' => Icons.verified_user_outlined,
      'verified_user' => Icons.verified_user,
      'pending_actions_outlined' => Icons.pending_actions_outlined,
      'pending_actions' => Icons.pending_actions,
      'check_circle_outline' => Icons.check_circle_outline,
      'check_circle' => Icons.check_circle,
      'receipt_long_outlined' => Icons.receipt_long_outlined,
      'receipt_long' => Icons.receipt_long,
      'account_balance_outlined' => Icons.account_balance_outlined,
      'account_balance' => Icons.account_balance,
      'assessment_outlined' => Icons.assessment_outlined,
      'assessment' => Icons.assessment,
      'support_agent_outlined' => Icons.support_agent_outlined,
      'support_agent' => Icons.support_agent,
      _ => Icons.circle,
    };
  }
}
