import 'package:nexus/shared/models/app_enums.dart';

/// Configuration de navigation par rôle
class RoleNavigationConfig {
  final List<NavigationItem> bottomNavItems;
  final String initialRoute;
  final List<String> allowedRoutes;

  const RoleNavigationConfig({
    required this.bottomNavItems,
    required this.initialRoute,
    required this.allowedRoutes,
  });
}

/// Élément de navigation (bottom nav)
class NavigationItem {
  final String label;
  final String route;
  final String icon;
  final String activeIcon;

  const NavigationItem({
    required this.label,
    required this.route,
    required this.icon,
    required this.activeIcon,
  });
}

/// Configurations de navigation par rôle
class RoleNavigationConfigs {
  static const borrower = RoleNavigationConfig(
    bottomNavItems: [
      NavigationItem(
        label: 'Accueil',
        route: '/home',
        icon: 'home_outlined',
        activeIcon: 'home',
      ),
      NavigationItem(
        label: 'Prêts',
        route: '/loans',
        icon: 'payments_outlined',
        activeIcon: 'payments',
      ),
      NavigationItem(
        label: 'Tontine',
        route: '/tontine',
        icon: 'people_outline',
        activeIcon: 'people',
      ),
      NavigationItem(
        label: 'Wallet',
        route: '/wallet',
        icon: 'account_balance_wallet_outlined',
        activeIcon: 'account_balance_wallet',
      ),
    ],
    initialRoute: '/home',
    allowedRoutes: [
      '/home',
      '/loans',
      '/loans/create',
      '/loans/:id',
      '/tontine',
      '/tontine/groups/create',
      '/tontine/groups/:id',
      '/tontine/groups/:groupId/cycles/create',
      '/tontine/cycles/:cycleId/complete',
      '/wallet',
      '/wallet/deposit',
      '/wallet/withdraw',
      '/kyc',
      '/kyc/document',
      '/kyc/financial',
      '/kyc/review',
      '/kyc/pending',
      '/profile',
    ],
  );

  static const investor = RoleNavigationConfig(
    bottomNavItems: [
      NavigationItem(
        label: 'Accueil',
        route: '/home',
        icon: 'home_outlined',
        activeIcon: 'home',
      ),
      NavigationItem(
        label: 'Prêts',
        route: '/loans',
        icon: 'payments_outlined',
        activeIcon: 'payments',
      ),
      NavigationItem(
        label: 'Investissements',
        route: '/investments',
        icon: 'show_chart_outlined',
        activeIcon: 'show_chart',
      ),
      NavigationItem(
        label: 'Tontine',
        route: '/tontine',
        icon: 'people_outline',
        activeIcon: 'people',
      ),
      NavigationItem(
        label: 'Wallet',
        route: '/wallet',
        icon: 'account_balance_wallet_outlined',
        activeIcon: 'account_balance_wallet',
      ),
    ],
    initialRoute: '/home',
    allowedRoutes: [
      '/home',
      '/loans',
      '/investments',
      '/investments/:id',
      '/investments/invest/:loanId',
      '/investments/auto-invest',
      '/tontine',
      '/tontine/groups/create',
      '/tontine/groups/:id',
      '/tontine/groups/:groupId/cycles/create',
      '/tontine/cycles/:cycleId/complete',
      '/wallet',
      '/wallet/deposit',
      '/wallet/withdraw',
      '/kyc',
      '/kyc/document',
      '/kyc/financial',
      '/kyc/review',
      '/kyc/pending',
      '/profile',
    ],
  );

  static const admin = RoleNavigationConfig(
    bottomNavItems: [
      NavigationItem(
        label: 'Accueil',
        route: '/home',
        icon: 'home_outlined',
        activeIcon: 'home',
      ),
      NavigationItem(
        label: 'Prêts',
        route: '/loans',
        icon: 'receipt_long_outlined',
        activeIcon: 'receipt_long',
      ),
      NavigationItem(
        label: 'Tontine',
        route: '/tontine',
        icon: 'people_outline',
        activeIcon: 'people',
      ),
      NavigationItem(
        label: 'Wallet',
        route: '/wallet',
        icon: 'account_balance_wallet_outlined',
        activeIcon: 'account_balance_wallet',
      ),
    ],
    initialRoute: '/home',
    allowedRoutes: [
      '/home',
      '/loans',
      '/loans/:id',
      '/tontine',
      '/tontine/groups/create',
      '/tontine/groups/:id',
      '/tontine/groups/:groupId/cycles/create',
      '/tontine/cycles/:cycleId/complete',
      '/wallet',
      '/wallet/deposit',
      '/wallet/withdraw',
      '/profile',
    ],
  );

  static const imfStaff = RoleNavigationConfig(
    bottomNavItems: [
      NavigationItem(
        label: 'Accueil',
        route: '/home',
        icon: 'home_outlined',
        activeIcon: 'home',
      ),
      NavigationItem(
        label: 'Prêts',
        route: '/loans',
        icon: 'pending_actions_outlined',
        activeIcon: 'pending_actions',
      ),
      NavigationItem(
        label: 'Tontine',
        route: '/tontine',
        icon: 'people_outline',
        activeIcon: 'people',
      ),
    ],
    initialRoute: '/home',
    allowedRoutes: [
      '/home',
      '/loans',
      '/loans/:id',
      '/tontine',
      '/tontine/groups/:id',
      '/tontine/groups/:groupId/cycles/create',
      '/tontine/cycles/:cycleId/complete',
      '/profile',
    ],
  );

  static const agent = RoleNavigationConfig(
    bottomNavItems: [
      NavigationItem(
        label: 'Accueil',
        route: '/home',
        icon: 'home_outlined',
        activeIcon: 'home',
      ),
      NavigationItem(
        label: 'Prêts',
        route: '/loans',
        icon: 'payments_outlined',
        activeIcon: 'payments',
      ),
      NavigationItem(
        label: 'Tontine',
        route: '/tontine',
        icon: 'people_outline',
        activeIcon: 'people',
      ),
    ],
    initialRoute: '/home',
    allowedRoutes: [
      '/home',
      '/loans',
      '/tontine',
      '/tontine/groups/:id',
      '/tontine/groups/:groupId/cycles/create',
      '/tontine/cycles/:cycleId/complete',
      '/profile',
    ],
  );

  static const user = RoleNavigationConfig(
    bottomNavItems: [],
    initialRoute: '/kyc',
    allowedRoutes: [
      '/kyc',
      '/kyc/document',
      '/kyc/financial',
      '/kyc/review',
      '/kyc/pending',
      '/profile',
    ],
  );

  /// Obtenir la configuration de navigation pour un rôle donné
  static RoleNavigationConfig getConfigForRole(UserRole role) {
    return switch (role) {
      UserRole.borrower => borrower,
      UserRole.investor => investor,
      UserRole.admin => admin,
      UserRole.imfStaff => imfStaff,
      UserRole.agent => agent,
      UserRole.user => user,
    };
  }

  /// Vérifier si une route est autorisée pour un rôle
  static bool isRouteAllowed(String route, UserRole role) {
    final config = getConfigForRole(role);
    // Vérification exacte ou préfixe
    return config.allowedRoutes.any(
      (allowed) =>
          route == allowed || route.startsWith(allowed.replaceAll(':id', '')),
    );
  }
}
