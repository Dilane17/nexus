import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus/core/error/exceptions.dart';
import 'package:nexus/core/network/dio_client.dart';
import 'package:nexus/features/kyc/data/models/kyc_models.dart';
import 'package:nexus/shared/models/api_response.dart';

class KycRepository {
  final Dio _dio;

  KycRepository() : _dio = DioClient().dio;

  // ── Session 1 : document + selfie ─────────────────────────────────────────

  Future<void> submitSession1(KycSession1Request request) async {
    try {
      final response = await _dio.post(
        '/users/kyc/session-1',
        data: request.toJson(),
      );
      final api = ApiResponse<dynamic>.fromJson(response.data, (d) => d);
      if (!api.success) {
        throw ServerException(api.message ?? 'Erreur session 1 KYC');
      }
    } on DioException catch (e) {
      throw _mapError(e, 'Erreur soumission documents');
    }
  }

  // ── Session 2 : revenus ────────────────────────────────────────────────────

  Future<void> submitSession2(KycSession2Request request) async {
    try {
      final response = await _dio.post(
        '/users/kyc/session-2',
        data: request.toJson(),
      );
      final api = ApiResponse<dynamic>.fromJson(response.data, (d) => d);
      if (!api.success) {
        throw ServerException(api.message ?? 'Erreur session 2 KYC');
      }
    } on DioException catch (e) {
      throw _mapError(e, 'Erreur soumission informations financières');
    }
  }

  // ── Session 3 : soumission finale ─────────────────────────────────────────

  Future<void> submitSession3() async {
    try {
      final response = await _dio.post('/users/kyc/session-3');
      final api = ApiResponse<dynamic>.fromJson(response.data, (d) => d);
      if (!api.success) {
        throw ServerException(api.message ?? 'Erreur soumission finale KYC');
      }
    } on DioException catch (e) {
      throw _mapError(e, 'Erreur soumission finale');
    }
  }

  // ── Statut KYC ────────────────────────────────────────────────────────────

  Future<KycStatusResponse> getKycStatus() async {
    try {
      final response = await _dio.get('/users/kyc/status');
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (d) => d as Map<String, dynamic>,
      );
      if (!api.success || api.data == null) {
        throw ServerException(api.message ?? 'Impossible de récupérer le statut KYC');
      }
      return KycStatusResponse.fromJson(api.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Erreur récupération statut KYC');
    }
  }

  // ── Profil complet ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio.get('/users/profile');
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (d) => d as Map<String, dynamic>,
      );
      if (!api.success || api.data == null) {
        throw ServerException(api.message ?? 'Impossible de récupérer le profil');
      }
      return api.data!;
    } on DioException catch (e) {
      throw _mapError(e, 'Erreur récupération profil');
    }
  }

  // ── Gestion erreurs ────────────────────────────────────────────────────────

  Exception _mapError(DioException e, String fallback) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException('Problème de connexion réseau');
    }
    final msg = e.response?.data?['message'] as String?;
    return ServerException(msg ?? fallback);
  }
}

final kycRepositoryProvider = Provider<KycRepository>((ref) => KycRepository());
