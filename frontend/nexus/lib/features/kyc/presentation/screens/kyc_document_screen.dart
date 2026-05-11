import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexus/core/theme/app_colors.dart';
import 'package:nexus/core/theme/app_spacing.dart';
import 'package:nexus/core/theme/widgets/nexus_button.dart';
import 'package:nexus/features/files/presentation/providers/file_upload_provider.dart';
import 'package:nexus/features/kyc/data/models/kyc_models.dart';
import 'package:nexus/features/kyc/presentation/providers/kyc_provider.dart';
import 'package:nexus/features/kyc/presentation/widgets/kyc_progress_bar.dart';

class KycDocumentScreen extends ConsumerStatefulWidget {
  const KycDocumentScreen({super.key});

  @override
  ConsumerState<KycDocumentScreen> createState() => _KycDocumentScreenState();
}

class _KycDocumentScreenState extends ConsumerState<KycDocumentScreen> {
  DocumentType _selectedDoc = DocumentType.cni;
  File? _documentFile;
  File? _selfieFile;
  String? _documentUrl;
  String? _selfieUrl;

  final _picker = ImagePicker();

  Future<void> _pickAndUpload({
    required String slot,
    required ImageSource source,
    required void Function(File, String) onSuccess,
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) return;

    final file = File(picked.path);
    final url = await ref.read(fileUploadProvider(slot).notifier).upload(file);
    if (url != null && mounted) onSuccess(file, url);
  }

  Future<void> _submit() async {
    if (_documentUrl == null || _selfieUrl == null) return;
    final ok = await ref.read(kycProvider.notifier).submitSession1(
          documentType: _selectedDoc.toJson(),
          documentUrl: _documentUrl!,
          selfieUrl: _selfieUrl!,
        );
    if (ok && mounted) context.go('/kyc/financial');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final docState = ref.watch(fileUploadProvider('document'));
    final selfieState = ref.watch(fileUploadProvider('selfie'));
    final kycState = ref.watch(kycProvider);

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
        title: const Text('Documents d\'identité'),
        leading: BackButton(onPressed: () => context.go('/kyc')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: NexusSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const KycProgressBar(step: 1),
              const SizedBox(height: NexusSpacing.stackXl),

              Text('Type de document', style: theme.textTheme.titleSmall),
              const SizedBox(height: NexusSpacing.stackMd),
              _DocTypeSelector(
                selected: _selectedDoc,
                onChanged: (d) => setState(() => _selectedDoc = d),
              ),
              const SizedBox(height: NexusSpacing.stackXl),

              Text('Photo du document', style: theme.textTheme.titleSmall),
              const SizedBox(height: NexusSpacing.stackMd),
              _ImageUploadTile(
                label: _selectedDoc.displayName,
                file: _documentFile,
                uploadState: docState,
                onPickGallery: () => _pickAndUpload(
                  slot: 'document',
                  source: ImageSource.gallery,
                  onSuccess: (f, url) =>
                      setState(() { _documentFile = f; _documentUrl = url; }),
                ),
                onPickCamera: () => _pickAndUpload(
                  slot: 'document',
                  source: ImageSource.camera,
                  onSuccess: (f, url) =>
                      setState(() { _documentFile = f; _documentUrl = url; }),
                ),
              ),
              const SizedBox(height: NexusSpacing.stackXl),

              Text('Selfie avec le document', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                'Tenez votre document à côté de votre visage',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: NexusSpacing.stackMd),
              _ImageUploadTile(
                label: 'Selfie',
                file: _selfieFile,
                uploadState: selfieState,
                onPickGallery: () => _pickAndUpload(
                  slot: 'selfie',
                  source: ImageSource.gallery,
                  onSuccess: (f, url) =>
                      setState(() { _selfieFile = f; _selfieUrl = url; }),
                ),
                onPickCamera: () => _pickAndUpload(
                  slot: 'selfie',
                  source: ImageSource.camera,
                  onSuccess: (f, url) =>
                      setState(() { _selfieFile = f; _selfieUrl = url; }),
                ),
              ),
              const SizedBox(height: NexusSpacing.stackXl),

              NexusButton(
                label: 'Continuer',
                isLoading: kycState.isLoading,
                onPressed:
                    (_documentUrl != null && _selfieUrl != null && !kycState.isLoading)
                        ? _submit
                        : null,
              ),
              const SizedBox(height: NexusSpacing.stackMd),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets locaux ─────────────────────────────────────────────────────────────

class _DocTypeSelector extends StatelessWidget {
  final DocumentType selected;
  final void Function(DocumentType) onChanged;

  const _DocTypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DocumentType.values.map((d) {
        final isSelected = d == selected;
        return ChoiceChip(
          label: Text(d.toJson()),
          selected: isSelected,
          onSelected: (_) => onChanged(d),
          selectedColor: NexusColors.primaryFixed,
          labelStyle: TextStyle(
            color: isSelected
                ? NexusColors.primary
                : NexusColors.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        );
      }).toList(),
    );
  }
}

class _ImageUploadTile extends StatelessWidget {
  final String label;
  final File? file;
  final FileUploadState uploadState;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;

  const _ImageUploadTile({
    required this.label,
    required this.file,
    required this.uploadState,
    required this.onPickGallery,
    required this.onPickCamera,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (uploadState is FileUploadLoading) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: NexusColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NexusColors.outlineVariant),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (file != null && uploadState is FileUploadSuccess) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              file!,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onPickCamera,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: NexusColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    final hasError = uploadState is FileUploadError;
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: NexusColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError ? NexusColors.error : NexusColors.outlineVariant,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasError) ...[
            const Icon(Icons.error_outline_rounded,
                color: NexusColors.error, size: 28),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                (uploadState as FileUploadError).message,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: NexusColors.error),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
          ] else ...[
            const Icon(Icons.add_photo_alternate_outlined,
                color: NexusColors.onSurfaceVariant, size: 32),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: onPickCamera,
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Caméra'),
              ),
              TextButton.icon(
                onPressed: onPickGallery,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Galerie'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
