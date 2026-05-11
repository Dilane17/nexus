import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus/core/error/exceptions.dart';
import 'package:nexus/core/network/dio_client.dart';
import 'package:nexus/features/wallet/data/models/transaction_models.dart';
import 'package:nexus/shared/models/api_response.dart';

class TransactionRepository {
  final Dio _dio;

  TransactionRepository() : _dio = DioClient().dio;

  Future<List<Transaction>> getMyTransactions({
    int page = 1,
    int limit = 20,
    String? type,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (type != null) params['type'] = type;

      final response = await _dio.get(
        '/transactions/my',
        queryParameters: params,
      );
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (d) => d as Map<String, dynamic>,
      );
      if (!api.success || api.data == null) {
        throw ServerException(
          api.message ?? 'Erreur récupération transactions',
        );
      }
      return ApiPage<Transaction>.fromJson(api.data!, Transaction.fromJson).items;
    } on DioException catch (e) {
      throw _map(e, 'Erreur récupération transactions');
    }
  }

  Future<Transaction> deposit(DepositRequest request) async {
    try {
      final response = await _dio.post(
        '/transactions/deposit',
        data: request.toJson(),
      );
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (d) => d as Map<String, dynamic>,
      );
      if (!api.success || api.data == null) {
        throw ServerException(api.message ?? 'Erreur dépôt');
      }
      final txData = api.data!['transaction'] as Map<String, dynamic>?;
      if (txData == null) {
        throw ServerException('Données de transaction manquantes');
      }
      return Transaction.fromJson(txData);
    } on DioException catch (e) {
      throw _map(e, 'Erreur dépôt');
    }
  }

  Future<Transaction> withdraw(WithdrawalRequest request) async {
    try {
      final response = await _dio.post(
        '/transactions/withdraw',
        data: request.toJson(),
      );
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (d) => d as Map<String, dynamic>,
      );
      if (!api.success || api.data == null) {
        throw ServerException(api.message ?? 'Erreur retrait');
      }
      return Transaction.fromJson(api.data!);
    } on DioException catch (e) {
      throw _map(e, 'Erreur retrait');
    }
  }

  Exception _map(DioException e, String fallback) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException('Problème de connexion réseau');
    }
    if (e.response?.statusCode == 409) {
      final msg = e.response?.data?['message'] as String?;
      return ServerException(msg ?? 'Solde insuffisant');
    }
    final msg = e.response?.data?['message'] as String?;
    return ServerException(msg ?? fallback);
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(),
);
