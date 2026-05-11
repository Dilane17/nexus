import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/widgets/nexus_button.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await ref.read(authProvider.notifier).loginWithGoogle();

      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Impossible de se connecter avec Google. Veuillez réessayer.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _login() async {
    setState(() {
      _errorMessage = null;
    });

    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final email = _emailController.text.trim();

      await ref
          .read(authProvider.notifier)
          .login(email: email, password: _passwordController.text);

      if (!mounted) return;

      final authState = ref.read(authProvider);

      if (authState.isAuthenticated) {
        context.go('/home');
      } else {
        setState(() {
          _errorMessage =
              authState.errorMessage ?? 'Une erreur inattendue est survenue.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexusColors.background,
      body: Stack(
        children: [
          const _AuthBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                NexusSpacing.containerPadding,
                NexusSpacing.stackLg,
                NexusSpacing.containerPadding,
                NexusSpacing.stackXl,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenue sur Nexus',
                      style: NexusTypography.textTheme.displayLarge?.copyWith(
                        color: NexusColors.onSurface,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: NexusSpacing.stackXl),
                    Container(
                      decoration: BoxDecoration(
                        color: NexusColors.surfaceContainerLowest.withValues(
                          alpha: 0.92,
                        ),
                        borderRadius: NexusShapes.cardRadius,
                        border: Border.all(
                          color: NexusColors.outlineVariant.withValues(
                            alpha: 0.55,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: NexusColors.primary.withValues(alpha: 0.06),
                            blurRadius: 32,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: 48,
                                  width: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    gradient: const LinearGradient(
                                      colors: [
                                        NexusColors.primary,
                                        NexusColors.primaryContainer,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_outlined,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Connectez vous',
                                        style: NexusTypography
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              color: NexusColors.onSurface,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: NexusSpacing.stackLg),
                              _AuthErrorBanner(message: _errorMessage!),
                            ],
                            const SizedBox(height: NexusSpacing.stackLg),
                            _AuthSectionLabel(label: 'Email'),
                            const SizedBox(height: NexusSpacing.stackSm),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              style: NexusTypography.textTheme.bodyMedium
                                  ?.copyWith(color: NexusColors.onSurface),
                              decoration: InputDecoration(
                                hintText: 'exemple@email.com',
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: NexusColors.onSurfaceVariant,
                                ),
                                filled: true,
                                fillColor: NexusColors.surface,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre adresse email';
                                }
                                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                                  return 'Adresse email invalide';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: NexusSpacing.stackLg),
                            _AuthSectionLabel(label: 'Mot de passe'),
                            const SizedBox(height: NexusSpacing.stackSm),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscureText,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _login(),
                              style: NexusTypography.textTheme.bodyMedium
                                  ?.copyWith(color: NexusColors.onSurface),
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                filled: true,
                                fillColor: NexusColors.surface,
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: NexusColors.onSurfaceVariant,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: NexusColors.onSurfaceVariant,
                                    size: 22,
                                  ),
                                  onPressed: _toggleObscureText,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre mot de passe';
                                }
                                if (value.length < 8) {
                                  return 'Le mot de passe doit contenir au moins 8 caractères';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: NexusSpacing.stackSm),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed:
                                    () => context.push('/forgot-password'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 40),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Mot de passe oublié ?',
                                  style: NexusTypography.textTheme.labelLarge
                                      ?.copyWith(
                                        color: NexusColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: NexusSpacing.stackMd),
                            NexusButton(
                              label: 'Se connecter',
                              onPressed: _login,
                              isLoading: _isLoading,
                              isFullWidth: true,
                            ),
                            const SizedBox(height: NexusSpacing.stackLg),
                            const _AuthDivider(label: 'Ou continuer avec'),
                            const SizedBox(height: NexusSpacing.stackLg),
                            SizedBox(
                              width: double.infinity,
                              height: NexusSpacing.largeTapTarget,
                              child: OutlinedButton(
                                onPressed:
                                    _isLoading ? null : _handleGoogleSignIn,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor:
                                      NexusColors.surfaceContainerLowest,
                                  foregroundColor: NexusColors.onSurface,
                                  side: BorderSide(
                                    color: NexusColors.outlineVariant
                                        .withValues(alpha: 0.8),
                                  ),
                                  shape: NexusShapes.buttonShape,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/icons/google_logo.png',
                                      height: 24,
                                      width: 24,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.g_mobiledata,
                                                size: 28,
                                                color: NexusColors.error,
                                              ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Continuer avec Google',
                                      style: NexusTypography
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: NexusColors.onSurface,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: NexusSpacing.stackLg),
                    Center(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          Text(
                            'Pas encore de compte ?',
                            style: NexusTypography.textTheme.bodyMedium
                                ?.copyWith(color: NexusColors.onSurfaceVariant),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/register'),
                            child: Text(
                              'Créer un compte',
                              style: NexusTypography.textTheme.labelLarge
                                  ?.copyWith(
                                    color: NexusColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF5F8FF), Color(0xFFF8F9FC), Color(0xFFF0F4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -40,
            child: _GlowCircle(
              size: 220,
              color: NexusColors.secondaryContainer.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            top: 110,
            left: -70,
            child: _GlowCircle(
              size: 180,
              color: NexusColors.primary.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            bottom: -90,
            right: -30,
            child: _GlowCircle(
              size: 240,
              color: NexusColors.primaryContainer.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _AuthSectionLabel extends StatelessWidget {
  const _AuthSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: NexusTypography.textTheme.labelMedium?.copyWith(
        color: NexusColors.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _AuthDivider extends StatelessWidget {
  const _AuthDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: NexusColors.outlineVariant.withValues(alpha: 0.8),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: NexusTypography.textTheme.labelMedium?.copyWith(
              color: NexusColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: NexusColors.outlineVariant.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _AuthErrorBanner extends StatelessWidget {
  const _AuthErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NexusColors.errorContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NexusColors.error.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.error_outline_rounded,
              color: NexusColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: NexusTypography.textTheme.bodySmall?.copyWith(
                color: NexusColors.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
