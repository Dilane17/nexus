import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus/core/network/dio_client.dart';
import 'package:nexus/core/error/exceptions.dart';
import 'package:nexus/shared/models/api_response.dart';
import 'package:nexus/shared/models/user_profile.dart';

class UserRepository {
  final Dio _dio;

  UserRepository() : _dio = DioClient().dio;

  Future<UserProfile> getProfile() async {
    try {
      final response = await _dio.get('/users/profile');
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw ServerException(
          apiResponse.message ?? 'Impossible de récupérer le profil',
        );
      }

      return UserProfile.fromJson(apiResponse.data!);
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
}

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(),
);
