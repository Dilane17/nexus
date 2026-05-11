import 'dart:io';
import 'package:flutter_riverpod/legacy.dart';
import 'package:nexus/core/error/exceptions.dart';
import 'package:nexus/features/files/data/file_upload_service.dart';

// ── State ─────────────────────────────────────────────────────────────────────

/// Les trois états possibles d'un upload.
/// Sealed class = le compilateur garantit que le switch est exhaustif.
sealed class FileUploadState {
  const FileUploadState();
}

final class FileUploadIdle extends FileUploadState {
  const FileUploadIdle();
}

final class FileUploadLoading extends FileUploadState {
  const FileUploadLoading();
}

final class FileUploadSuccess extends FileUploadState {
  final String url;
  const FileUploadSuccess(this.url);
}

final class FileUploadError extends FileUploadState {
  final String message;
  const FileUploadError(this.message);
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class FileUploadNotifier extends StateNotifier<FileUploadState> {
  final FileUploadService _service;

  FileUploadNotifier(this._service) : super(const FileUploadIdle());

  /// Lance l'upload et retourne l'URL si succès, null sinon.
  Future<String?> upload(File file) async {
    state = const FileUploadLoading();

    try {
      final result = await _service.uploadImage(file);
      state = FileUploadSuccess(result.url);
      return result.url;
    } on ServerException catch (e) {
      state = FileUploadError(e.message);
      return null;
    } on NetworkException catch (e) {
      state = FileUploadError(e.message);
      return null;
    } catch (_) {
      state = const FileUploadError('Erreur inattendue lors de l\'upload');
      return null;
    }
  }

  void reset() => state = const FileUploadIdle();
}

// ── Providers ─────────────────────────────────────────────────────────────────

/// Provider family : un slot par image ('document', 'selfie', 'statement').
/// Chaque slot a son propre état indépendant.
final fileUploadProvider = StateNotifierProvider.family<
    FileUploadNotifier, FileUploadState, String>(
  (ref, slot) => FileUploadNotifier(ref.watch(fileUploadServiceProvider)),
);
