import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nexus/core/config/app_config.dart';

/// Client HTTP singleton.
///
/// Responsabilités :
///   1. Injecter le Bearer token sur chaque requête.
///   2. Sur 401, tenter un refresh silencieux via un Dio bare (sans intercepteur)
///      pour éviter la récursion infinie, puis rejouer la requête originale.
///   3. Si le refresh échoue, supprimer les tokens (l'AuthNotifier détectera
///      l'absence de token au prochain appel à restoreSession).
class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late final Dio dio;

  final _storage = const FlutterSecureStorage();

  // Flag anti-récursion : on n'essaie le refresh qu'une seule fois à la fois.
  bool _isRefreshing = false;

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true, logPrint: (o) => debugPrint(o.toString())),
      );
    }
  }

  // ── Injection du token ──────────────────────────────────────────────────────

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  // ── Gestion 401 + auto-refresh ──────────────────────────────────────────────

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode == 401 && !_isRefreshing) {
      final refreshToken = await _storage.read(key: 'refresh_token');

      if (refreshToken != null) {
        _isRefreshing = true;
        try {
          // Dio bare = aucun intercepteur → pas de boucle infinie
          final refreshDio = Dio(
            BaseOptions(
              baseUrl: AppConfig.baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              contentType: 'application/json',
            ),
          );

          final response = await refreshDio.post(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
            options: Options(
              headers: {'Authorization': 'Bearer $refreshToken'},
            ),
          );

          // Format backend : { success, data: { accessToken, refreshToken } }
          final data = response.data['data'] as Map<String, dynamic>;
          final newAccess = data['accessToken'] as String;
          final newRefresh = data['refreshToken'] as String;

          await _storage.write(key: 'access_token', value: newAccess);
          await _storage.write(key: 'refresh_token', value: newRefresh);

          // Rejouer la requête originale avec le nouveau token
          final opts = error.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newAccess';
          final retryResponse = await dio.fetch(opts);
          return handler.resolve(retryResponse);
        } catch (_) {
          // Refresh invalide → tokens supprimés, l'utilisateur sera redirigé
          await _storage.delete(key: 'access_token');
          await _storage.delete(key: 'refresh_token');
        } finally {
          _isRefreshing = false;
        }
      }
    }

    return handler.next(error);
  }
}
