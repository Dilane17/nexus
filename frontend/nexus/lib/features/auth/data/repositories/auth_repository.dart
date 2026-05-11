import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus/core/network/dio_client.dart';
import 'package:nexus/core/error/exceptions.dart';
import 'package:nexus/shared/models/api_response.dart';
import 'package:nexus/shared/models/auth_tokens.dart';
import 'package:nexus/shared/models/auth_user.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository() : _dio = DioClient().dio;

  Future<AuthTokens> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw ServerException(
          apiResponse.message ?? 'Erreur lors de la connexion',
        );
      }

      return AuthTokens.fromJson(apiResponse.data!);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Problème de connexion réseau');
      }
      final message =
          e.response?.data['message'] ?? 'Erreur lors de la connexion';
      throw ServerException(message);
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    String? phone,
    required String email,
    required String password,
    required String city,
    required String district,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          'email': email,
          'password': password,
          'city': city,
          'district': district,
        },
      );

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data,
        (data) => data,
      );

      if (!apiResponse.success) {
        throw ServerException(
          apiResponse.message ?? "Erreur lors de l'inscription",
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Problème de connexion réseau');
      }
      final message =
          e.response?.data['message'] ?? "Erreur lors de l'inscription";
      throw ServerException(message);
    }
  }

  Future<AuthTokens> verifyEmail(String email, String code) async {
    try {
      final response = await _dio.post(
        '/auth/verify-email',
        data: {'email': email, 'code': code},
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw ServerException(apiResponse.message ?? 'Code OTP invalide');
      }

      return AuthTokens.fromJson(apiResponse.data!);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Problème de connexion réseau');
      }
      final message = e.response?.data['message'] ?? 'Code OTP invalide';
      throw ServerException(message);
    }
  }

  Future<void> resendOtp(String email) async {
    try {
      final response = await _dio.post(
        '/auth/resend-otp',
        data: {'email': email},
      );

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data,
        (data) => data,
      );

      if (!apiResponse.success) {
        throw ServerException(
          apiResponse.message ?? 'Erreur lors du renvoi du code',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Problème de connexion réseau');
      }
      final message =
          e.response?.data['message'] ?? 'Erreur lors du renvoi du code';
      throw ServerException(message);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data,
        (data) => data,
      );

      if (!apiResponse.success) {
        throw ServerException(
          apiResponse.message ??
              'Erreur lors de la demande de réinitialisation',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Problème de connexion réseau');
      }
      final message =
          e.response?.data['message'] ??
          'Erreur lors de la demande de réinitialisation';
      throw ServerException(message);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {
          'email': email,
          'code': code,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data,
        (data) => data,
      );

      if (!apiResponse.success) {
        throw ServerException(
          apiResponse.message ?? 'Erreur lors de la réinitialisation',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Problème de connexion réseau');
      }
      final message =
          e.response?.data['message'] ?? 'Erreur lors de la réinitialisation';
      throw ServerException(message);
    }
  }

  Future<AuthTokens> refreshTokens(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw ServerException(apiResponse.message ?? 'Session expirée');
      }

      return AuthTokens.fromJson(apiResponse.data!);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Problème de connexion réseau');
      }
      throw ServerException('Session expirée');
    }
  }

  Future<AuthUser> getMe() async {
    try {
      final response = await _dio.get('/auth/me');
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw ServerException(
          apiResponse.message ?? 'Impossible de récupérer le profil',
        );
      }

      return AuthUser.fromJson(apiResponse.data!);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Problème de connexion réseau');
      }
      final message =
          e.response?.data['message'] ?? 'Impossible de récupérer le profil';
      throw ServerException(message);
    }
  }

  Future<AuthTokens?> signInWithGoogleIdToken(String idToken) async {
    try {
      final response = await _dio.post(
        '/auth/google/mobile',
        data: {'idToken': idToken},
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw ServerException(
          apiResponse.message ?? 'Connexion Google impossible',
        );
      }

      final data = apiResponse.data!;
      if (data['needsVerification'] == true) {
        throw ServerException(
          data['message'] as String? ?? 'Vérification email requise',
        );
      }

      return AuthTokens.fromJson(data['tokens'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Problème de connexion réseau');
      }
      final message =
          e.response?.data['message'] ?? 'Connexion Google impossible';
      throw ServerException(message);
    }
  }

  Future<AuthUser> updateProfile({
    String? firstName,
    String? lastName,
    String? city,
    String? district,
  }) async {
    try {
      final response = await _dio.patch(
        '/auth/me',
        data: {
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          if (city != null) 'city': city,
          if (district != null) 'district': district,
        },
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw ServerException(apiResponse.message ?? 'Erreur de mise à jour');
      }

      return AuthUser.fromJson(apiResponse.data!);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Problème de connexion réseau');
      }
      final message =
          e.response?.data['message'] ?? 'Erreur de mise à jour du profil';
      throw ServerException(message);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.patch(
        '/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data,
        (data) => data,
      );

      if (!apiResponse.success) {
        throw ServerException(
          apiResponse.message ?? 'Erreur lors du changement de mot de passe',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Problème de connexion réseau');
      }
      final message =
          e.response?.data['message'] ??
          'Erreur lors du changement de mot de passe';
      throw ServerException(message);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException {
      rethrow;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);
