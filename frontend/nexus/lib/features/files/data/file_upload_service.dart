import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus/core/error/exceptions.dart';
import 'package:nexus/core/network/dio_client.dart';
import 'package:nexus/shared/models/api_response.dart';

/// Résultat d'un upload réussi.
/// Le backend retourne `{ success: true, data: { url: "https://..." } }`.
class UploadResult {
  final String url;
  const UploadResult(this.url);
}

/// Service d'upload d'images pour le KYC.
///
/// Contraintes backend (/files/upload) :
///   - Champ multipart : "file"
///   - Type MIME : image/* uniquement
///   - Taille max : 5 MB
///
/// Ce service compresse automatiquement l'image si elle dépasse 4 MB
/// (marge de sécurité avant la limite serveur).
class FileUploadService {
  final Dio _dio;

  FileUploadService() : _dio = DioClient().dio;

  static const int _maxBytes = 4 * 1024 * 1024; // 4 MB (marge avant 5 MB)

  Future<UploadResult> uploadImage(File file) async {
    File fileToUpload = file;

    // Compression si le fichier dépasse la marge
    if (await file.length() > _maxBytes) {
      fileToUpload = await _compress(file);
    }

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          fileToUpload.path,
          // Le content-type est détecté automatiquement par Dio via l'extension
        ),
      });

      final response = await _dio.post(
        '/files/upload',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw ServerException(
          apiResponse.message ?? 'Échec de l\'upload',
        );
      }

      final url = apiResponse.data!['url'] as String?;
      if (url == null || url.isEmpty) {
        throw const ServerException('URL de fichier manquante dans la réponse');
      }

      return UploadResult(url);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const NetworkException('Connexion lente, réessayez');
      }
      if (e.response?.statusCode == 413) {
        throw const ServerException(
          'Fichier trop volumineux malgré la compression',
        );
      }
      final msg = e.response?.data?['message'] as String?;
      throw ServerException(msg ?? 'Erreur lors de l\'upload');
    }
  }

  // ── Compression ────────────────────────────────────────────────────────────

  Future<File> _compress(File file) async {
    final outPath = '${file.path}_compressed.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      outPath,
      quality: 75,
      minWidth: 1024,
      minHeight: 1024,
    );

    if (result == null) return file; // fallback : envoyer l'original
    return File(result.path);
  }
}

// ── Riverpod Provider ──────────────────────────────────────────────────────────

final fileUploadServiceProvider = Provider<FileUploadService>((ref) {
  return FileUploadService();
});
