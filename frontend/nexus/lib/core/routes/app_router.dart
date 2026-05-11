import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nexus/features/auth/presentation/providers/auth_provider.dart';
import 'package:nexus/features/auth/presentation/providers/user_profile_provider.dart';
import 'package:nexus/features/auth/presentation/screens/splash_screen.dart';
import 'package:nexus/features/auth/presentation/screens/login_screen.dart';
import 'package:nexus/features/auth/presentation/screens/register_screen.dart';
import 'package:nexus/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:nexus/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:nexus/features/auth/presentation/screens/reset_password_screen.dart';

import 'package:nexus/features/shell/presentation/shell_screen.dart';
import 'package:nexus/features/home/presentation/home_screen.dart';
import 'package:nexus/features/loans/presentation/screens/loans_screen.dart';
import 'package:nexus/features/loans/presentation/screens/loan_detail_screen.dart';
import 'package:nexus/features/loans/presentation/screens/create_loan_screen.dart';
import 'package:nexus/features/investments/presentation/screens/investments_screen.dart';
import 'package:nexus/features/investments/presentation/screens/investment_detail_screen.dart';
import 'package:nexus/features/investments/presentation/screens/invest_in_loan_screen.dart';
import 'package:nexus/features/investments/presentation/screens/auto_invest_screen.dart';
import 'package:nexus/features/tontine/presentation/screens/tontine_screen.dart';
import 'package:nexus/features/tontine/presentation/screens/tontine_group_detail_screen.dart';
import 'package:nexus/features/tontine/presentation/screens/create_group_screen.dart';
import 'package:nexus/features/tontine/presentation/screens/create_cycle_screen.dart';
import 'package:nexus/features/tontine/presentation/screens/complete_cycle_screen.dart';
import 'package:nexus/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:nexus/features/wallet/presentation/screens/deposit_screen.dart';
import 'package:nexus/features/wallet/presentation/screens/withdraw_screen.dart';

import 'package:nexus/features/profile/presentation/screens/profile_screen.dart';
import 'package:nexus/features/kyc/presentation/screens/kyc_intro_screen.dart';
import 'package:nexus/features/kyc/presentation/screens/kyc_document_screen.dart';
import 'package:nexus/features/kyc/presentation/screens/kyc_financial_screen.dart';
import 'package:nexus/features/kyc/presentation/screens/kyc_review_screen.dart';
import 'package:nexus/features/kyc/presentation/screens/kyc_pending_screen.dart';
import 'package:nexus/shared/models/app_enums.dart';
import 'package:nexus/shared/models/user_profile.dart';
import 'package:nexus/core/navigation/role_navigation.dart';

/// Redirige vers la route appropriée selon le rôle et le KYC.
String _getRoleBasedRedirect(UserProfile? profile) {
  if (profile == null) return '/home';

  final role = profile.role;
  final kycStatus = profile.kycStatus;

  // Si KYC non validé, rediriger vers KYC
  if (kycStatus != KycStatus.validated) {
    // Si soumis, rediriger vers pending screen
    if (kycStatus == KycStatus.submitted) {
      return '/kyc/pending';
    }
    return '/kyc';
  }

  // Rediriger selon le rôle
  final navConfig = RoleNavigationConfigs.getConfigForRole(role);
  return navConfig.initialRoute;
}

// ChangeNotifier qui porte l'AuthState courant et UserProfile
// pour notifier GoRouter des changements d'auth et de rôle.
class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(AuthState initial) : _authState = initial;

  AuthState _authState;
  UserProfile? _profile;

  AuthState get authState => _authState;
  UserProfile? get profile => _profile;

  void updateAuth(AuthState next) {
    _authState = next;
    notifyListeners();
  }

  void updateProfile(UserProfile? profile) {
    _profile = profile;
    notifyListeners();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref.read(authProvider));

  // ref.listen ne recrée PAS le provider — il synchronise juste le notifier.
  ref.listen<AuthState>(authProvider, (_, next) => notifier.updateAuth(next));
  ref.listen<AsyncValue<UserProfile?>>(
    userProfileProvider,
    (_, next) => notifier.updateProfile(next.value),
  );
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = notifier.authState;
      final profile = notifier.profile;
      final isAuthenticated = authState.isAuthenticated;
      final loc = state.matchedLocation;

      final isAuthRoute =
          loc == '/login' ||
          loc == '/register' ||
          loc == '/forgot-password' ||
          loc == '/reset-password';

      final isSplashRoute = loc == '/';
      final isVerifyEmailRoute = loc == '/verify-email';

      if (isSplashRoute) return null;

      if (!isAuthenticated && loc.startsWith('/kyc')) {
        // Permettre l'accès au KYC sans auth pour le flow de réinitialisation
        // Sinon rediriger vers login
        return '/login';
      }

      if (!isAuthenticated) {
        final isPublicRoute =
            loc == '/kyc' || loc.startsWith('/kyc/') || loc == '/profile';
        if (!isPublicRoute && !isAuthRoute) return '/login';
      }

      if (isAuthenticated) {
        final user = authState.user;
        if (user != null &&
            !user.isEmailVerified &&
            !isVerifyEmailRoute &&
            !isAuthRoute) {
          return '/verify-email';
        }
        if (isAuthRoute) return _getRoleBasedRedirect(profile);
      }

      // Vérifier les permissions basées sur le rôle
      if (isAuthenticated && profile != null) {
        if (!RoleNavigationConfigs.isRouteAllowed(loc, profile.role)) {
          // Route non autorisée pour ce rôle, rediriger vers le dashboard du rôle
          return _getRoleBasedRedirect(profile);
        }
      }

      return null;
    },
    routes: [
      // ── Hors shell (public + non-navigable) ────────────────────────────────
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/verify-email',
        builder: (_, state) {
          final email = state.extra as String? ?? '';
          return VerifyEmailScreen(email: email);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) {
          final extra = state.extra;
          if (extra is Map<String, String?>) {
            return ResetPasswordScreen(email: extra['email']);
          }
          return const ResetPasswordScreen();
        },
      ),

      // ── KYC (hors shell — flow onboarding sans bottom nav) ─────────────────
      GoRoute(
        path: '/kyc',
        builder: (_, _) => const KycIntroScreen(),
        routes: [
          GoRoute(
            path: 'document',
            builder: (_, _) => const KycDocumentScreen(),
          ),
          GoRoute(
            path: 'financial',
            builder: (_, _) => const KycFinancialScreen(),
          ),
          GoRoute(path: 'review', builder: (_, _) => const KycReviewScreen()),
          GoRoute(path: 'pending', builder: (_, _) => const KycPendingScreen()),
        ],
      ),

      // ── Shell (routes protégées avec bottom navigation) ─────────────────────
      StatefulShellRoute.indexedStack(
        builder:
            (_, _, navigationShell) =>
                ShellScreen(navigationShell: navigationShell),
        branches: [
          // ── Onglet 0 : Accueil ──────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),

          // ── Onglet 1 : Prêts ────────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/loans',
                builder: (_, _) => const LoansScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    builder: (_, _) => const CreateLoanScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder:
                        (_, state) => LoanDetailScreen(
                          loanId: state.pathParameters['id']!,
                        ),
                  ),
                ],
              ),
            ],
          ),

          // ── Onglet 2 : Investissements ──────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/investments',
                builder: (_, _) => const InvestmentsScreen(),
                routes: [
                  GoRoute(
                    path: 'auto-invest',
                    builder: (_, _) => const AutoInvestScreen(),
                  ),
                  GoRoute(
                    path: 'invest/:loanId',
                    builder:
                        (_, state) => InvestInLoanScreen(
                          loanId: state.pathParameters['loanId']!,
                        ),
                  ),
                  GoRoute(
                    path: ':id',
                    builder:
                        (_, state) => InvestmentDetailScreen(
                          investmentId: state.pathParameters['id']!,
                        ),
                  ),
                ],
              ),
            ],
          ),

          // ── Onglet 3 : Tontine ──────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tontine',
                builder: (_, _) => const TontineScreen(),
                routes: [
                  GoRoute(
                    path: 'groups/create',
                    builder: (_, _) => const CreateGroupScreen(),
                  ),
                  GoRoute(
                    path: 'groups/:id',
                    builder:
                        (_, state) => TontineGroupDetailScreen(
                          groupId: state.pathParameters['id']!,
                        ),
                    routes: [
                      GoRoute(
                        path: 'cycles/create',
                        builder:
                            (_, state) => CreateCycleScreen(
                              groupId: state.pathParameters['id']!,
                            ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'cycles/:cycleId/complete',
                    builder:
                        (_, state) => CompleteCycleScreen(
                          cycleId: state.pathParameters['cycleId']!,
                        ),
                  ),
                ],
              ),
            ],
          ),

          // ── Onglet 4 : Wallet ───────────────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wallet',
                builder: (_, _) => const WalletScreen(),
                routes: [
                  GoRoute(
                    path: 'deposit',
                    builder: (_, _) => const DepositScreen(),
                  ),
                  GoRoute(
                    path: 'withdraw',
                    builder: (_, _) => const WithdrawScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ── Profil (hors shell — plein écran) ──────────────────────────────────
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
    ],
  );
});
