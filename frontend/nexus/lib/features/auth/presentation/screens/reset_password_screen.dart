import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/widgets/nexus_button.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? email;

  const ResetPasswordScreen({
    super.key,
    this.email,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).resetPassword(
            email: widget.email ?? '',
            code: _codeController.text.trim(),
            newPassword: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe modifié. Connectez-vous.'),
            backgroundColor: NexusColors.success,
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('ServerException: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.email ?? '';

    return Scaffold(
      backgroundColor: NexusColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: NexusColors.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: NexusSpacing.containerPadding,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: NexusSpacing.stackLg),
                Text(
                  'Nouveau mot de passe',
                  style: NexusTypography.textTheme.headlineLarge?.copyWith(
                    color: NexusColors.onSurface,
                  ),
                ),
                const SizedBox(height: NexusSpacing.stackSm),
                Text(
                  'Entrez le code envoyé à $target puis définissez votre nouveau mot de passe.',
                  style: NexusTypography.textTheme.bodyMedium?.copyWith(
                    color: NexusColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: NexusSpacing.stack2xl),
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  decoration: const InputDecoration(
                    labelText: 'Code OTP',
                    hintText: '00000',
                    counterText: '',
                  ),
                  validator: (value) {
                    final code = value?.trim() ?? '';
                    if (!RegExp(r'^\d{5}$').hasMatch(code)) {
                      return 'Le code doit contenir exactement 5 chiffres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: NexusSpacing.stackMd),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    final password = value ?? '';
                    if (password.length < 8) {
                      return 'Au moins 8 caractères';
                    }
                    if (!RegExp(r'[A-Z]').hasMatch(password)) {
                      return 'Au moins une majuscule';
                    }
                    if (!RegExp(r'[0-9]').hasMatch(password)) {
                      return 'Au moins un chiffre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: NexusSpacing.stackMd),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: NexusSpacing.stackMd),
                  Text(
                    _errorMessage!,
                    style: NexusTypography.textTheme.labelSmall?.copyWith(
                      color: NexusColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: NexusSpacing.stack2xl),
                NexusButton(
                  label: 'Réinitialiser',
                  onPressed: _submit,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
