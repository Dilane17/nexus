import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus/core/error/exceptions.dart';
import 'package:nexus/core/network/dio_client.dart';
import 'package:nexus/features/loans/data/models/loan_models.dart';
import 'package:nexus/shared/models/api_response.dart';

class LoanRepository {
  final Dio _dio;

  LoanRepository() : _dio = DioClient().dio;

  // ── Liste des prêts de l'utilisateur (emprunteur, paginée) ──────────────────

  Future<List<Loan>> getMyLoans({int page = 1, int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/loans/my',
        queryParameters: {'page': page, 'limit': limit},
      );
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (d) => d as Map<String, dynamic>,
      );
      if (!api.success || api.data == null) {
        throw ServerException(api.message ?? 'Erreur récupération prêts');
      }
      return ApiPage<Loan>.fromJson(api.data!, Loan.fromJson).items;
    } on DioException catch (e) {
      throw _map(e, 'Erreur récupération prêts');
    }
  }

  // ── Marketplace investisseur — prêts FUNDING des autres emprunteurs ──────────

  Future<List<Loan>> getFundingLoans({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        '/loans/funding',
        queryParameters: {'page': page, 'limit': limit},
      );
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (d) => d as Map<String, dynamic>,
      );
      if (!api.success || api.data == null) {
        throw ServerException(api.message ?? 'Erreur récupération marketplace');
      }
      return ApiPage<Loan>.fromJson(api.data!, Loan.fromJson).items;
    } on DioException catch (e) {
      throw _map(e, 'Erreur récupération marketplace');
    }
  }

  // ── Détail d'un prêt ─────────────────────────────────────────────────────

  Future<Loan> getLoanById(String id) async {
    try {
      final response = await _dio.get('/loans/$id');
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (d) => d as Map<String, dynamic>,
      );
      if (!api.success || api.data == null) {
        throw ServerException(api.message ?? 'Prêt introuvable');
      }
      return Loan.fromJson(api.data!);
    } on DioException catch (e) {
      throw _map(e, 'Erreur récupération prêt');
    }
  }

  // ── Créer un prêt ─────────────────────────────────────────────────────────

  Future<Loan> createLoan(CreateLoanRequest request) async {
    try {
      final response = await _dio.post('/loans', data: request.toJson());
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (d) => d as Map<String, dynamic>,
      );
      if (!api.success || api.data == null) {
        throw ServerException(api.message ?? 'Erreur création prêt');
      }
      return Loan.fromJson(api.data!);
    } on DioException catch (e) {
      throw _map(e, 'Erreur création prêt');
    }
  }

  // ── Rembourser un prêt ────────────────────────────────────────────────────

  Future<Loan> repayLoan(String id, RepayLoanRequest request) async {
    try {
      final response = await _dio.post(
        '/loans/$id/repay',
        data: request.toJson(),
      );
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (d) => d as Map<String, dynamic>,
      );
      if (!api.success || api.data == null) {
        throw ServerException(api.message ?? 'Erreur remboursement');
      }
      return Loan.fromJson(api.data!);
    } on DioException catch (e) {
      throw _map(e, 'Erreur remboursement');
    }
  }

  // ── Gestion erreurs ───────────────────────────────────────────────────────

  Exception _map(DioException e, String fallback) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException('Problème de connexion réseau');
    }
    if (e.response?.statusCode == 403) {
      return const ServerException(
        'KYC requis pour accéder aux prêts',
      );
    }
    final msg = e.response?.data?['message'] as String?;
    return ServerException(msg ?? fallback);
  }
}

final loanRepositoryProvider = Provider<LoanRepository>(
  (ref) => LoanRepository(),
);
