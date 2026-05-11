import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shapes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/widgets/nexus_button.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isAccepted = false;
  bool _isLoading = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updateState);
    _confirmPasswordController.addListener(_updateState);
    _emailController.addListener(_updateState);
    _phoneController.addListener(_updateState);
    _firstNameController.addListener(_updateState);
    _lastNameController.addListener(_updateState);
    _cityController.addListener(_updateState);
    _districtController.addListener(_updateState);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || !_isAccepted) return;
    setState(() {
      _serverError = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final phone = '+229${_phoneController.text.trim()}';

    try {
      await ref
          .read(authProvider.notifier)
          .register(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            phone: phone,
            email: email,
            password: _passwordController.text,
            city: _cityController.text.trim(),
            district: _districtController.text.trim(),
          );

      if (mounted) {
        context.go('/verify-email', extra: email);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _serverError = 'Une erreur s\'est produite. Veuillez réessayer.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCityPicker() {
    final cities = [
      'Cotonou',
      'Parakou',
      'Porto-Novo',
      'Abomey-Calavi',
      'Djougou',
      'Natitingou',
      'Autres',
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: NexusColors.surfaceContainerLowest,
      shape: NexusShapes.bottomSheetShape,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: NexusColors.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: NexusSpacing.stackLg),
                Text(
                  'Sélectionnez votre ville',
                  style: NexusTypography.textTheme.headlineSmall,
                ),
                const SizedBox(height: NexusSpacing.stackSm),
                Text(
                  'Choisissez votre localité pour personnaliser votre expérience.',
                  style: NexusTypography.textTheme.bodySmall,
                ),
                const SizedBox(height: NexusSpacing.stackLg),
                ...cities.map(
                  (city) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      city,
                      style: NexusTypography.textTheme.titleMedium,
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: NexusColors.onSurfaceVariant,
                    ),
                    onTap: () {
                      _cityController.text = city;
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool get _isFormValid {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        RegExp(r'^\d{8}$').hasMatch(_phoneController.text.trim()) &&
        emailRegex.hasMatch(email) &&
        _cityController.text.isNotEmpty &&
        _districtController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text &&
        _isAccepted;
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _serverError = null;
      _isLoading = true;
    });
    try {
      await ref.read(authProvider.notifier).loginWithGoogle();
      if (mounted) context.go('/home');
    } catch (_) {
      if (mounted) {
        setState(() {
          _serverError =
              'Impossible de se connecter avec Google. Veuillez réessayer.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _passwordStrength {
    final pass = _passwordController.text;
    var score = 0;
    if (pass.length >= 8) score++;
    if (RegExp(r'(?=.*?[A-Z])').hasMatch(pass)) score++;
    if (RegExp(r'(?=.*?[0-9])').hasMatch(pass)) score++;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexusColors.background,
      body: Stack(
        children: [
          const _RegisterBackground(),
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
                      'Créer un compte',
                      style: NexusTypography.textTheme.displayLarge?.copyWith(
                        color: NexusColors.onSurface,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: NexusSpacing.stackXl),
                    Container(
                      decoration: BoxDecoration(
                        color: NexusColors.surfaceContainerLowest.withValues(
                          alpha: 0.94,
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
                            blurRadius: 30,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inscription',
                              style: NexusTypography.textTheme.headlineMedium,
                            ),
                            if (_serverError != null) ...[
                              const SizedBox(height: NexusSpacing.stackLg),
                              _ServerErrorBanner(message: _serverError!),
                            ],
                            const SizedBox(height: NexusSpacing.stackLg),
                            Row(
                              children: [
                                Expanded(
                                  child: _AuthTextField(
                                    label: 'Prénom',
                                    controller: _firstNameController,
                                    hintText: 'Ex. Awa',
                                    textInputAction: TextInputAction.next,
                                    prefixIcon: const Icon(
                                      Icons.badge_outlined,
                                      color: NexusColors.onSurfaceVariant,
                                    ),
                                    validator:
                                        (v) =>
                                            v?.isEmpty ?? true
                                                ? 'Ce champ est requis'
                                                : null,
                                  ),
                                ),
                                const SizedBox(width: NexusSpacing.gutter),
                                Expanded(
                                  child: _AuthTextField(
                                    label: 'Nom',
                                    controller: _lastNameController,
                                    hintText: 'Ex. Kossi',
                                    textInputAction: TextInputAction.next,
                                    prefixIcon: const Icon(
                                      Icons.person_outline_rounded,
                                      color: NexusColors.onSurfaceVariant,
                                    ),
                                    validator:
                                        (v) =>
                                            v?.isEmpty ?? true
                                                ? 'Ce champ est requis'
                                                : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: NexusSpacing.stackLg),
                            _AuthTextField(
                              label: 'Email',
                              controller: _emailController,
                              hintText: 'exemple@email.com',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: NexusColors.onSurfaceVariant,
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Ce champ est requis';
                                }
                                if (!RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                ).hasMatch(v)) {
                                  return 'Adresse email invalide';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: NexusSpacing.stackLg),
                            _AuthTextField(
                              label: 'Téléphone',
                              controller: _phoneController,
                              hintText: '97000000',
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              prefixIcon: _PhonePrefix(),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 86,
                                minHeight: 48,
                              ),
                              validator: (v) {
                                final value = v?.trim() ?? '';
                                if (value.isEmpty) {
                                  return 'Ce champ est requis';
                                }
                                if (!RegExp(r'^\d{8}$').hasMatch(value)) {
                                  return 'Entrez 8 chiffres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: NexusSpacing.stackLg),
                            Row(
                              children: [
                                Expanded(
                                  child: _AuthTextField(
                                    label: 'Ville',
                                    controller: _cityController,
                                    hintText: 'Choisir une ville',
                                    readOnly: true,
                                    onTap: _showCityPicker,
                                    prefixIcon: const Icon(
                                      Icons.location_city_outlined,
                                      color: NexusColors.onSurfaceVariant,
                                    ),
                                    suffixIcon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: NexusColors.onSurfaceVariant,
                                    ),
                                    validator:
                                        (v) =>
                                            v?.isEmpty ?? true
                                                ? 'Ce champ est requis'
                                                : null,
                                  ),
                                ),
                                const SizedBox(width: NexusSpacing.gutter),
                                Expanded(
                                  child: _AuthTextField(
                                    label: 'Quartier',
                                    controller: _districtController,
                                    hintText: 'Votre quartier',
                                    textInputAction: TextInputAction.next,
                                    prefixIcon: const Icon(
                                      Icons.map_outlined,
                                      color: NexusColors.onSurfaceVariant,
                                    ),
                                    validator:
                                        (v) =>
                                            v?.isEmpty ?? true
                                                ? 'Ce champ est requis'
                                                : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: NexusSpacing.stackLg),
                            _AuthTextField(
                              label: 'Mot de passe',
                              controller: _passwordController,
                              hintText: 'Minimum 8 caractères',
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                color: NexusColors.onSurfaceVariant,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: NexusColors.onSurfaceVariant,
                                ),
                                onPressed:
                                    () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Ce champ est requis';
                                }
                                if (v.length < 8) {
                                  return 'Minimum 8 caractères';
                                }
                                if (!RegExp(r'(?=.*?[A-Z])').hasMatch(v)) {
                                  return 'Doit contenir une majuscule';
                                }
                                if (!RegExp(r'(?=.*?[0-9])').hasMatch(v)) {
                                  return 'Doit contenir un chiffre';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: NexusSpacing.stackMd),
                            _PasswordStrengthBar(score: _passwordStrength),
                            const SizedBox(height: NexusSpacing.stackMd),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _PasswordRuleChip(
                                  label: '8 caractères',
                                  isActive:
                                      _passwordController.text.length >= 8,
                                ),
                                _PasswordRuleChip(
                                  label: '1 majuscule',
                                  isActive: RegExp(
                                    r'(?=.*?[A-Z])',
                                  ).hasMatch(_passwordController.text),
                                ),
                                _PasswordRuleChip(
                                  label: '1 chiffre',
                                  isActive: RegExp(
                                    r'(?=.*?[0-9])',
                                  ).hasMatch(_passwordController.text),
                                ),
                              ],
                            ),
                            const SizedBox(height: NexusSpacing.stackLg),
                            _AuthTextField(
                              label: 'Confirmer le mot de passe',
                              controller: _confirmPasswordController,
                              hintText: 'Répétez votre mot de passe',
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _register(),
                              prefixIcon: const Icon(
                                Icons.lock_person_outlined,
                                color: NexusColors.onSurfaceVariant,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: NexusColors.onSurfaceVariant,
                                ),
                                onPressed:
                                    () => setState(
                                      () => _obscureConfirm = !_obscureConfirm,
                                    ),
                              ),
                              validator: (v) {
                                if (v?.isEmpty ?? true) {
                                  return 'Ce champ est requis';
                                }
                                if (v != _passwordController.text) {
                                  return 'Les mots de passe ne correspondent pas';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: NexusSpacing.stackLg),
                            _TermsPanel(
                              isAccepted: _isAccepted,
                              onChanged:
                                  (value) => setState(
                                    () => _isAccepted = value ?? false,
                                  ),
                            ),
                            const SizedBox(height: NexusSpacing.stackLg),
                            NexusButton(
                              label: 'Créer mon compte',
                              onPressed:
                                  _isFormValid && !_isLoading
                                      ? _register
                                      : null,
                              isLoading: _isLoading,
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
                            'Vous avez déjà un compte ?',
                            style: NexusTypography.textTheme.bodyMedium,
                          ),
                          GestureDetector(
                            onTap: () => context.push('/login'),
                            child: Text(
                              'Se connecter',
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

class _RegisterBackground extends StatelessWidget {
  const _RegisterBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF7F9FC), Color(0xFFF2F5FF), Color(0xFFFDF8F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -30,
            child: _AmbientShape(
              size: 210,
              color: NexusColors.secondaryContainer.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            top: 160,
            left: -80,
            child: _AmbientShape(
              size: 190,
              color: NexusColors.primary.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            bottom: -70,
            right: -40,
            child: _AmbientShape(
              size: 220,
              color: NexusColors.primaryContainer.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientShape extends StatelessWidget {
  const _AmbientShape({required this.size, required this.color});

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

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.label,
    required this.controller,
    required this.validator,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixIconConstraints,
    this.readOnly = false,
    this.obscureText = false,
    this.onTap,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final BoxConstraints? prefixIconConstraints;
  final bool readOnly;
  final bool obscureText;
  final VoidCallback? onTap;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: NexusTypography.textTheme.labelMedium?.copyWith(
            color: NexusColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: NexusSpacing.stackSm),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          readOnly: readOnly,
          onTap: onTap,
          onFieldSubmitted: onFieldSubmitted,
          style: NexusTypography.textTheme.bodyMedium?.copyWith(
            color: NexusColors.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: NexusColors.surface,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            prefixIconConstraints: prefixIconConstraints,
          ),
        ),
      ],
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    if (score == 0) {
      return const SizedBox.shrink();
    }

    var color = NexusColors.error;
    var label = 'Sécurité faible';
    if (score == 2) {
      color = NexusColors.warning;
      label = 'Sécurité moyenne';
    } else if (score == 3) {
      color = NexusColors.success;
      label = 'Sécurité forte';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Container(
                    height: 6,
                    margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
                    decoration: BoxDecoration(
                      color:
                          index < score
                              ? color
                              : NexusColors.outlineVariant.withValues(
                                alpha: 0.8,
                              ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: NexusTypography.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordRuleChip extends StatelessWidget {
  const _PasswordRuleChip({required this.label, required this.isActive});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:
            isActive
                ? NexusColors.successContainer
                : NexusColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              isActive
                  ? NexusColors.success.withValues(alpha: 0.2)
                  : NexusColors.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            size: 16,
            color:
                isActive ? NexusColors.success : NexusColors.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: NexusTypography.textTheme.labelMedium?.copyWith(
              color:
                  isActive ? NexusColors.success : NexusColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsPanel extends StatelessWidget {
  const _TermsPanel({required this.isAccepted, required this.onChanged});

  final bool isAccepted;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NexusColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: isAccepted,
              activeColor: NexusColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: NexusTypography.textTheme.bodySmall?.copyWith(
                  color: NexusColors.onSurfaceVariant,
                  height: 1.45,
                ),
                children: [
                  const TextSpan(text: "J'accepte les "),
                  TextSpan(
                    text: "conditions d'utilisation",
                    style: const TextStyle(
                      color: NexusColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = () {},
                  ),
                  const TextSpan(text: " et la "),
                  TextSpan(
                    text: "politique de confidentialité",
                    style: const TextStyle(
                      color: NexusColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = () {},
                  ),
                  const TextSpan(text: ' de Nexus.'),
                ],
              ),
            ),
          ),
        ],
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

class _PhonePrefix extends StatelessWidget {
  const _PhonePrefix();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+229',
            style: NexusTypography.textTheme.bodyMedium?.copyWith(
              color: NexusColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 20, color: NexusColors.outlineVariant),
        ],
      ),
    );
  }
}

class _ServerErrorBanner extends StatelessWidget {
  const _ServerErrorBanner({required this.message});

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
