import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus/core/error/exceptions.dart';
import 'package:nexus/core/network/dio_client.dart';
import 'package:nexus/features/investments/data/models/investment_models.dart';
import 'package:nexus/shared/models/api_response.dart';

class InvestmentRepository {
  final Dio _dio;

  InvestmentRepository() : _dio = DioClient().dio;

  Future<List<Investment>> getMyInvestments({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (status != null) params['status'] = status;

      final response = await _dio.get(
        '/investments/my',
        queryParameters: params,
      );
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (d) => d as Map<String, dynamic>,
      );
      if (!api.success || api.data == null) {
        throw ServerException(
          api.message ?? 'Erreur récupération investissements',
        );
      }
      return ApiPage<Investment>.fromJson(api.data!, Investment.fromJson).items;
    } on DioException catch (e) {
      throw _map(e, 'Erreur récupération investissements');
    }
  }

  Future<InvestmentSummary> getInvestmentSummary() async {
    try {
      final response = await _dio.get('/investments/my/summary');
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (d) => d as Map<String, dynamic>,
      );
      if (!api.success || api.data == null) {
        throw ServerException(api.message ?? 'Erreur récupération résumé');
      }
      return InvestmentSummary.fromJson(api.data!);
    } on DioException catch (e) {
      throw _map(e, 'Erreur récupération résumé');
    }
  }

  Future<Investment> getInvestmentById(String id) async {
    try {
      final response = await _dio.get('/investments/$id');
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (d) => d as Map<String, dynamic>,
      );
      if (!api.success || api.data == null) {
        throw ServerException(api.message ?? 'Investissement introuvable');
      }
      return Investment.fromJson(api.data!);
    } on DioException catch (e) {
      throw _map(e, 'Erreur récupération investissement');
    }
  }

  Future<Investment> createInvestment(CreateInvestmentRequest request) async {
    try {
      final response = await _dio.post('/investments', data: request.toJson());
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (d) => d as Map<String, dynamic>,
      );
      if (!api.success || api.data == null) {
        throw ServerException(api.message ?? 'Erreur investissement');
      }
      return Investment.fromJson(api.data!);
    } on DioException catch (e) {
      throw _map(e, 'Erreur investissement');
    }
  }

  Future<AutoInvestRule?> getAutoInvestRule() async {
    try {
      final response = await _dio.get('/investments/auto-invest');
      final api = ApiResponse<Map<String, dynamic>?>.fromJson(
        response.data,
        (d) => d as Map<String, dynamic>?,
      );
      if (!api.success) {
        throw ServerException(api.message ?? 'Erreur auto-invest');
      }
      if (api.data == null) return null;
      return AutoInvestRule.fromJson(api.data!);
    } on DioException catch (e) {
      throw _map(e, 'Erreur récupération règle auto-invest');
    }
  }

  Future<AutoInvestRule> putAutoInvestRule(
    AutoInvestRuleRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '/investments/auto-invest',
        data: request.toJson(),
      );
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (d) => d as Map<String, dynamic>,
      );
      if (!api.success || api.data == null) {
        throw ServerException(api.message ?? 'Erreur sauvegarde règle');
      }
      return AutoInvestRule.fromJson(api.data!);
    } on DioException catch (e) {
      throw _map(e, 'Erreur sauvegarde règle auto-invest');
    }
  }

  Future<void> runAutoInvest() async {
    try {
      final response = await _dio.post('/investments/auto-invest/run');
      final api = ApiResponse<dynamic>.fromJson(response.data, (d) => d);
      if (!api.success) {
        throw ServerException(api.message ?? 'Erreur exécution auto-invest');
      }
    } on DioException catch (e) {
      throw _map(e, 'Erreur exécution auto-invest');
    }
  }

  Exception _map(DioException e, String fallback) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException('Problème de connexion réseau');
    }
    if (e.response?.statusCode == 403) {
      return const ServerException('Profil investisseur requis');
    }
    if (e.response?.statusCode == 409) {
      final msg = e.response?.data?['message'] as String?;
      return ServerException(msg ?? 'Fonds insuffisants ou prêt non éligible');
    }
    final msg = e.response?.data?['message'] as String?;
    return ServerException(msg ?? fallback);
  }
}

final investmentRepositoryProvider = Provider<InvestmentRepository>(
  (ref) => InvestmentRepository(),
);
