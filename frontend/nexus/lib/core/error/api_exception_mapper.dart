import 'package:dio/dio.dart';
import 'package:nexus/core/error/exceptions.dart';

/// Mapper centralisé pour les exceptions API.
/// Transforme les DioException en ServerException/NetworkException
/// avec des messages UX cohérents.
class ApiExceptionMapper {
  /// Mappe une DioException vers une exception applicative.
  static Exception mapDioException(
    DioException e,
    String contextFallback,
  ) {
    // Timeout réseau
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const NetworkException(
        'Problème de connexion réseau. Vérifiez votre connexion.',
      );
    }

    // Pas de connexion
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkException(
        'Pas de connexion internet. Vérifiez votre connexion.',
      );
    }

    // Erreur serveur avec code de statut
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    if (statusCode != null) {
      return _mapStatusCode(statusCode, responseData, contextFallback);
    }

    // Annulation par l'utilisateur
    if (e.type == DioExceptionType.cancel) {
      return const ServerException('Opération annulée');
    }

    // Erreur inconnue
    return ServerException(contextFallback);
  }

  /// Mappe un code de statut HTTP vers une exception avec message UX.
  static Exception _mapStatusCode(
    int statusCode,
    dynamic responseData,
    String contextFallback,
  ) {
    // Extraire le message du backend si disponible
    final serverMessage = _extractServerMessage(responseData);

    switch (statusCode) {
      case 400:
        return ServerException(serverMessage ?? 'Requête invalide');
      case 401:
        return const ServerException('Non authentifié. Veuillez vous reconnecter.');
      case 403:
        return ServerException(
          serverMessage ?? 'Accès refusé. Permissions insuffisantes.',
        );
      case 404:
        return ServerException(serverMessage ?? 'Ressource introuvable');
      case 409:
        return ServerException(
          serverMessage ?? 'Conflit de données. Veuillez réessayer.',
        );
      case 422:
        return ServerException(
          serverMessage ?? 'Données invalides. Veuillez vérifier votre saisie.',
        );
      case 429:
        return const ServerException(
          'Trop de requêtes. Veuillez attendre quelques secondes.',
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return const ServerException(
          'Erreur serveur temporaire. Veuillez réessayer plus tard.',
        );
      default:
        return ServerException(serverMessage ?? contextFallback);
    }
  }

  /// Extrait le message d'erreur depuis la réponse du backend.
  static String? _extractServerMessage(dynamic data) {
    if (data == null) return null;

    // Cas 1: data est une Map avec clé 'message'
    if (data is Map<String, dynamic>) {
      return data['message'] as String?;
    }

    // Cas 2: data est une Map avec clé 'error'
    if (data is Map<String, dynamic>) {
      return data['error'] as String?;
    }

    // Cas 3: data est une String
    if (data is String) {
      return data;
    }

    return null;
  }

  /// Crée un message d'erreur spécifique au contexte.
  /// Utilisé pour donner plus de contexte sur l'opération qui a échoué.
  static String withContext(String operation, String error) {
    return '$operation : $error';
  }
}
