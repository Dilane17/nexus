import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/theme/app_spacing.dart';
import 'package:nexus/core/theme/widgets/nexus_button.dart';
import 'package:nexus/core/theme/widgets/nexus_input.dart';
import 'package:nexus/features/files/presentation/providers/file_upload_provider.dart';
import 'package:nexus/features/kyc/data/models/kyc_models.dart';
import 'package:nexus/features/kyc/presentation/providers/kyc_provider.dart';
import 'package:nexus/features/kyc/presentation/widgets/kyc_progress_bar.dart';

class KycFinancialScreen extends ConsumerStatefulWidget {
  const KycFinancialScreen({super.key});

  @override
  ConsumerState<KycFinancialScreen> createState() => _KycFinancialScreenState();
}

class _KycFinancialScreenState extends ConsumerState<KycFinancialScreen> {
  final _incomeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  IncomeSource _selectedSource = IncomeSource.salarie;
  File? _statementFile;
  String? _statementUrl;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  Future<void> _pickStatement(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;
    final file = File(picked.path);
    final url = await ref
        .read(fileUploadProvider('statement').notifier)
        .upload(file);
    if (url != null && mounted) {
      setState(() {
        _statementFile = file;
        _statementUrl = url;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final income = num.tryParse(
      _incomeController.text.replaceAll(RegExp(r'\s'), ''),
    );
    if (income == null) return;

    final ok = await ref.read(kycProvider.notifier).submitSession2(
          monthlyIncome: income,
          incomeSource: _selectedSource.toJson(),
          momoStatementUrl: _statementUrl,
        );
    if (ok && mounted) context.go('/kyc/review');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kycState = ref.watch(kycProvider);
    final statementState = ref.watch(fileUploadProvider('statement'));

    ref.listen(kycProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: NexusColors.error,
          ),
        );
        ref.read(kycProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: NexusColors.background,
      appBar: AppBar(
        title: const Text('Informations financières'),
        leading: BackButton(onPressed: () => context.go('/kyc/document')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: NexusSpacing.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const KycProgressBar(step: 2),
                const SizedBox(height: NexusSpacing.stackXl),

                NexusInput(
                  label: 'Revenu mensuel net (FCFA)',
                  hint: 'Ex : 150 000',
                  controller: _incomeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    final n = num.tryParse(v);
                    if (n == null || n <= 0) return 'Montant invalide';
                    if (n > 10000000) return 'Montant trop élevé';
                    return null;
                  },
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                Text('Source de revenus', style: theme.textTheme.titleSmall),
                const SizedBox(height: NexusSpacing.stackMd),
                _IncomeSourceSelector(
                  selected: _selectedSource,
                  onChanged: (s) => setState(() => _selectedSource = s),
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                Row(
                  children: [
                    Text('Relevé Mobile Money', style: theme.textTheme.titleSmall),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: NexusColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Optionnel', style: theme.textTheme.labelSmall),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Améliore vos chances d\'approbation',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: NexusSpacing.stackMd),
                _StatementUploadTile(
                  file: _statementFile,
                  uploadState: statementState,
                  onPickCamera: () => _pickStatement(ImageSource.camera),
                  onPickGallery: () => _pickStatement(ImageSource.gallery),
                ),
                const SizedBox(height: NexusSpacing.stackXl),

                NexusButton(
                  label: 'Continuer',
                  isLoading: kycState.isLoading,
                  onPressed: kycState.isLoading ? null : _submit,
                ),
                const SizedBox(height: NexusSpacing.stackMd),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sélecteur de source de revenus ────────────────────────────────────────────
// Flutter 3.32+ : Radio/RadioListTile groupValue/onChanged sont dépréciés.
// On utilise RadioGroup<T> comme ancêtre, les Radio enfants héritent du groupe.

class _IncomeSourceSelector extends StatelessWidget {
  final IncomeSource selected;
  final void Function(IncomeSource) onChanged;

  const _IncomeSourceSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioGroup<IncomeSource>(
      groupValue: selected,
      onChanged: (v) { if (v != null) onChanged(v); },
      child: Column(
        children: IncomeSource.values.map((s) {
          return InkWell(
            onTap: () => onChanged(s),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Radio<IncomeSource>(value: s),
                  const SizedBox(width: 8),
                  Text(
                    s.displayName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatementUploadTile extends StatelessWidget {
  final File? file;
  final FileUploadState uploadState;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;

  const _StatementUploadTile({
    required this.file,
    required this.uploadState,
    required this.onPickCamera,
    required this.onPickGallery,
  });

  @override
  Widget build(BuildContext context) {
    if (uploadState is FileUploadLoading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (file != null && uploadState is FileUploadSuccess) {
      return ListTile(
        leading: const Icon(
          Icons.check_circle_rounded,
          color: NexusColors.success,
        ),
        title: const Text('Relevé uploadé'),
        subtitle: Text(file!.path.split('/').last),
        trailing: IconButton(
          onPressed: onPickCamera,
          icon: const Icon(Icons.refresh_rounded),
        ),
        contentPadding: EdgeInsets.zero,
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPickCamera,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Caméra'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPickGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Galerie'),
          ),
        ),
      ],
    );
  }
}
