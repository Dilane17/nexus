import 'package:dio/dio.dart';
import '../services/session_service.dart';
import '../../features/auth/data/repositories/auth_repository.dart';

class AuthInterceptor extends Interceptor {
  final SessionService _session;
  final AuthRepository _authRepo;
  final Dio _dio; // Pour re-tenter la requête initiale

  AuthInterceptor(this._session, this._authRepo, this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _session.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _session.getRefreshToken();

      if (refreshToken != null) {
        try {
          // Tentative de rafraîchissement
          final tokens = await _authRepo.refreshTokens(refreshToken);
          final newAccess = tokens.accessToken;
          final newRefresh = tokens.refreshToken;

          await _session.saveTokens(newAccess, newRefresh);

          // On rejoue la requête originale
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newAccess';

          final response = await _dio.fetch(opts);
          return handler.resolve(response);
        } catch (e) {
          // Échec du refresh -> Déconnexion
          await _session.clearSession();
        }
      }
    }
    return handler.next(err);
  }
}
