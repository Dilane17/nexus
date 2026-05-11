import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus/core/error/exceptions.dart';
import 'package:nexus/core/network/dio_client.dart';
import 'package:nexus/features/tontine/data/models/tontine_models.dart';
import 'package:nexus/shared/models/api_response.dart';

class TontineRepository {
  final Dio _dio;

  TontineRepository() : _dio = DioClient().dio;

  Future<TontineScore> getMyScore() async {
    try {
      final response = await _dio.get('/tontine/my-score');
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (d) => d as Map<String, dynamic>,
      );
      if (!api.success || api.data == null) {
        throw ServerException(api.message ?? 'Erreur récupération score');
      }
      return TontineScore.fromJson(api.data!);
    } on DioException catch (e) {
      throw _map(e, 'Erreur récupération score tontine');
    }
  }

  Future<List<TontineGroup>> getGroups({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (status != null) params['status'] = status;

      final response = await _dio.get(
        '/tontine/groups',
        queryParameters: params,
      );
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (d) => d as Map<String, dynamic>,
      );
      if (!api.success || api.data == null) {
        throw ServerException(api.message ?? 'Erreur récupération groupes');
      }
      return ApiPage<TontineGroup>.fromJson(
        api.data!,
        TontineGroup.fromJson,
      ).items;
    } on DioException catch (e) {
      throw _map(e, 'Erreur récupération groupes');
    }
  }

  Future<TontineGroup> createGroup(CreateTontineGroupRequest request) async {
    try {
      final response = await _dio.post(
        '/tontine/groups',
        data: request.toJson(),
      );
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (d) => d as Map<String, dynamic>,
      );
      if (!api.success || api.data == null) {
        throw ServerException(api.message ?? 'Erreur création groupe');
      }
      return TontineGroup.fromJson(api.data!);
    } on DioException catch (e) {
      throw _map(e, 'Erreur création groupe');
    }
  }

  Future<TontineGroup> getGroupById(String id) async {
    try {
      final response = await _dio.get('/tontine/groups/$id');
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (d) => d as Map<String, dynamic>,
      );
      if (!api.success || api.data == null) {
        throw ServerException(api.message ?? 'Groupe introuvable');
      }
      return TontineGroup.fromJson(api.data!);
    } on DioException catch (e) {
      throw _map(e, 'Erreur récupération groupe');
    }
  }

  Future<void> joinGroup(String id) async {
    try {
      final response = await _dio.post('/tontine/groups/$id/join');
      final api = ApiResponse<dynamic>.fromJson(response.data, (d) => d);
      if (!api.success) {
        throw ServerException(api.message ?? 'Erreur adhésion groupe');
      }
    } on DioException catch (e) {
      throw _map(e, 'Erreur adhésion groupe');
    }
  }

  Future<TontineCycle> createCycle(
    String groupId,
    CreateCycleRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/tontine/groups/$groupId/cycles',
        data: request.toJson(),
      );
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (d) => d as Map<String, dynamic>,
      );
      if (!api.success || api.data == null) {
        throw ServerException(api.message ?? 'Erreur création cycle');
      }
      return TontineCycle.fromJson(api.data!);
    } on DioException catch (e) {
      throw _map(e, 'Erreur création cycle');
    }
  }

  Future<TontineCycle> completeCycle(
    String cycleId,
    CompleteCycleRequest request,
  ) async {
    try {
      final response = await _dio.patch(
        '/tontine/cycles/$cycleId/complete',
        data: request.toJson(),
      );
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (d) => d as Map<String, dynamic>,
      );
      if (!api.success || api.data == null) {
        throw ServerException(api.message ?? 'Erreur clôture cycle');
      }
      return TontineCycle.fromJson(api.data!);
    } on DioException catch (e) {
      throw _map(e, 'Erreur clôture cycle');
    }
  }

  Exception _map(DioException e, String fallback) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException('Problème de connexion réseau');
    }
    if (e.response?.statusCode == 403) {
      return const ServerException('Profil emprunteur requis');
    }
    if (e.response?.statusCode == 409) {
      final msg = e.response?.data?['message'] as String?;
      return ServerException(msg ?? 'Déjà membre ou groupe actif existant');
    }
    final msg = e.response?.data?['message'] as String?;
    return ServerException(msg ?? fallback);
  }
}

final tontineRepositoryProvider = Provider<TontineRepository>(
  (ref) => TontineRepository(),
);
