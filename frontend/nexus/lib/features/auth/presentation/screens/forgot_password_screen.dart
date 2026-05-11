import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/widgets/nexus_button.dart';
import '../../data/repositories/auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();

      await ref.read(authRepositoryProvider).forgotPassword(email);

      if (mounted) {
        context.push('/reset-password', extra: {'email': email});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Impossible d'envoyer le code. Veuillez réessayer.";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexusColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: NexusColors.onSurface,
          ),
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
                  'Mot de passe oublié',
                  style: NexusTypography.textTheme.headlineLarge?.copyWith(
                    color: NexusColors.onSurface,
                  ),
                ),
                const SizedBox(height: NexusSpacing.stackSm),
                Text(
                  'Entrez votre adresse email pour recevoir un code de réinitialisation de votre mot de passe.',
                  style: NexusTypography.textTheme.bodyMedium?.copyWith(
                    color: NexusColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: NexusSpacing.stack2xl),

                Text(
                  'Email',
                  style: NexusTypography.textTheme.labelMedium,
                ),
                const SizedBox(height: NexusSpacing.stackXs),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: NexusTypography.textTheme.bodyMedium?.copyWith(
                    color: NexusColors.onSurface,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'exemple@email.com',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: NexusColors.onSurfaceVariant,
                    ),
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
                  label: 'Continuer',
                  onPressed: _handleSubmit,
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
