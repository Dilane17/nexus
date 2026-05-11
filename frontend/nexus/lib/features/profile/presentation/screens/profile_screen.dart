import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/theme/app_spacing.dart';
import 'package:nexus/core/theme/widgets/nexus_button.dart';
import 'package:nexus/core/theme/widgets/nexus_card.dart';
import 'package:nexus/features/auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _cityController;
  late final TextEditingController _districtController;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSavingProfile = false;
  bool _isSavingPassword = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _cityController = TextEditingController(text: user?.city ?? '');
    _districtController = TextEditingController(text: user?.district ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSavingProfile = true);
    final ok = await ref.read(authProvider.notifier).updateProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      city: _cityController.text.trim(),
      district: _districtController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSavingProfile = false);
    final msg = ok ? 'Profil mis à jour' : ref.read(authProvider).errorMessage ?? 'Erreur';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? NexusColors.success : NexusColors.error,
      ),
    );
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.length < 8 ||
        _newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vérifiez les champs mot de passe'),
          backgroundColor: NexusColors.error,
        ),
      );
      return;
    }
    setState(() => _isSavingPassword = true);
    final ok = await ref.read(authProvider.notifier).changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
    if (!mounted) return;
    setState(() => _isSavingPassword = false);
    if (ok) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
    final msg = ok ? 'Mot de passe modifié' : ref.read(authProvider).errorMessage ?? 'Erreur';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? NexusColors.success : NexusColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: NexusColors.background,
      appBar: AppBar(
        title: const Text('Mon profil'),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: NexusColors.error),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: NexusSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: NexusColors.primaryFixed,
                child: Text(
                  user?.firstName.isNotEmpty == true
                      ? user!.firstName[0].toUpperCase()
                      : 'N',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: NexusColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: NexusSpacing.stackMd),
            Center(
              child: Text(
                user?.fullName ?? '',
                style: theme.textTheme.titleMedium,
              ),
            ),
            Center(
              child: Text(
                user?.phone ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: NexusColors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: NexusSpacing.stackXl),

            Text('Informations personnelles', style: theme.textTheme.titleSmall),
            const SizedBox(height: NexusSpacing.stackMd),
            Form(
              key: _formKey,
              child: NexusCard(
                child: Column(
                  children: [
                    _ProfileField(
                      label: 'Prénom',
                      controller: _firstNameController,
                      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: NexusSpacing.stackMd),
                    _ProfileField(
                      label: 'Nom',
                      controller: _lastNameController,
                      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: NexusSpacing.stackMd),
                    _ProfileField(
                      label: 'Ville',
                      controller: _cityController,
                    ),
                    const SizedBox(height: NexusSpacing.stackMd),
                    _ProfileField(
                      label: 'Quartier',
                      controller: _districtController,
                    ),
                    const SizedBox(height: NexusSpacing.stackLg),
                    NexusButton(
                      label: 'Enregistrer',
                      isLoading: _isSavingProfile,
                      onPressed: _isSavingProfile ? null : _saveProfile,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: NexusSpacing.stackXl),

            Text('Changer le mot de passe', style: theme.textTheme.titleSmall),
            const SizedBox(height: NexusSpacing.stackMd),
            NexusCard(
              child: Column(
                children: [
                  _PasswordField(
                    label: 'Mot de passe actuel',
                    controller: _currentPasswordController,
                  ),
                  const SizedBox(height: NexusSpacing.stackMd),
                  _PasswordField(
                    label: 'Nouveau mot de passe',
                    controller: _newPasswordController,
                  ),
                  const SizedBox(height: NexusSpacing.stackMd),
                  _PasswordField(
                    label: 'Confirmer le nouveau mot de passe',
                    controller: _confirmPasswordController,
                  ),
                  const SizedBox(height: NexusSpacing.stackLg),
                  NexusButton(
                    label: 'Modifier le mot de passe',
                    style: NexusButtonStyle.secondary,
                    isLoading: _isSavingPassword,
                    onPressed: _isSavingPassword ? null : _changePassword,
                  ),
                ],
              ),
            ),
            const SizedBox(height: NexusSpacing.stack2xl),
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const _ProfileField({
    required this.label,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: NexusColors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: const InputDecoration(
            filled: true,
            fillColor: NexusColors.surface,
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatefulWidget {
  final String label;
  final TextEditingController controller;

  const _PasswordField({required this.label, required this.controller});

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: NexusColors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          obscureText: _obscure,
          decoration: InputDecoration(
            filled: true,
            fillColor: NexusColors.surface,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: NexusColors.onSurfaceVariant,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
      ],
    );
  }
}
