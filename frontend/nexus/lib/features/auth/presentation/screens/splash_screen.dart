import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/auth_provider.dart';

/// SplashScreen — Point d'entrée de l'expérience Nexus.
/// Utilise le dégradé institutionnel et la typographie Manrope.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Vérification de la session
    Future.delayed(const Duration(milliseconds: 2500), () async {
      final session = ref.read(sessionServiceProvider);
      final token = await session.getAccessToken();

      if (mounted) {
        context.go(token != null ? '/home' : '/login');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              NexusColors.primary, // #000666
              NexusColors.primaryContainer, // #1A237E (Indigo léger)
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo Placeholder (Technologique et Sécurisé)
              const Icon(
                Icons.shield_rounded,
                size: 80,
                color: NexusColors.onPrimary,
              ),
              const SizedBox(height: NexusSpacing.stackLg),
              Text(
                'NEXUS',
                style: NexusTypography.textTheme.displayLarge?.copyWith(
                  color: NexusColors.onPrimary,
                  letterSpacing: 4.0,
                ),
              ),
              const Spacer(),
              Text(
                'PAN-AFRICAN FINANCIAL CORE',
                style: NexusTypography.textTheme.labelSmall?.copyWith(
                  color: NexusColors.onPrimary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: NexusSpacing.stack2xl),
            ],
          ),
        ),
      ),
    );
  }
}
