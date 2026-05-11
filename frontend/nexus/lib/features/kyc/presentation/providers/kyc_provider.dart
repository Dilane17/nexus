import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:nexus/core/error/exceptions.dart';
import 'package:nexus/features/auth/presentation/providers/auth_provider.dart';
import 'package:nexus/features/kyc/data/models/kyc_models.dart';
import 'package:nexus/features/kyc/data/repositories/kyc_repository.dart';
import 'package:nexus/shared/models/app_enums.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum KycStep { intro, document, financial, review, pending, rejected }

class KycState {
  final KycStep currentStep;
  final KycStatus kycStatus;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  // Données collectées au fil des sessions
  final String? documentUrl;
  final String? selfieUrl;
  final String? documentType;
  final String? momoStatementUrl;
  final String? rejectionReason;

  const KycState({
    this.currentStep = KycStep.intro,
    this.kycStatus = KycStatus.notStarted,
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.documentUrl,
    this.selfieUrl,
    this.documentType,
    this.momoStatementUrl,
    this.rejectionReason,
  });

  KycState copyWith({
    KycStep? currentStep,
    KycStatus? kycStatus,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    String? documentUrl,
    String? selfieUrl,
    String? documentType,
    String? momoStatementUrl,
    String? rejectionReason,
    bool clearError = false,
  }) {
    return KycState(
      currentStep: currentStep ?? this.currentStep,
      kycStatus: kycStatus ?? this.kycStatus,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      documentUrl: documentUrl ?? this.documentUrl,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      documentType: documentType ?? this.documentType,
      momoStatementUrl: momoStatementUrl ?? this.momoStatementUrl,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class KycNotifier extends StateNotifier<KycState> {
  final KycRepository _repo;
  final Ref _ref;

  KycNotifier(this._repo, this._ref) : super(const KycState());

  // ── Chargement initial : déduire l'étape depuis le statut KYC ──────────────

  Future<void> loadStatus() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _repo.getKycStatus();
      final step =
          data.submittedAt != null
              ? KycStep.pending
              : _stepFromStatus(data.status);
      state = state.copyWith(
        isLoading: false,
        kycStatus: data.status,
        currentStep: step,
        documentUrl: data.documentUrl,
        selfieUrl: data.selfieUrl,
        documentType: data.documentType,
        momoStatementUrl: data.momoStatementUrl,
        rejectionReason: data.rejectionReason,
      );
    } on ServerException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } on NetworkException catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Problème de connexion réseau',
      );
    }
  }

  // ── Session 1 : soumettre document + selfie ────────────────────────────────

  Future<bool> submitSession1({
    required String documentType,
    required String documentUrl,
    required String selfieUrl,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.submitSession1(
        KycSession1Request(
          documentType: documentType,
          documentUrl: documentUrl,
          selfieUrl: selfieUrl,
        ),
      );
      state = state.copyWith(
        isLoading: false,
        kycStatus: KycStatus.session1Done,
        currentStep: KycStep.financial,
        documentType: documentType,
        documentUrl: documentUrl,
        selfieUrl: selfieUrl,
      );
      return true;
    } on ServerException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } on NetworkException catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Problème de connexion réseau',
      );
      return false;
    }
  }

  // ── Session 2 : soumettre revenus ──────────────────────────────────────────

  Future<bool> submitSession2({
    required num monthlyIncome,
    required String incomeSource,
    String? momoStatementUrl,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.submitSession2(
        KycSession2Request(
          monthlyIncome: monthlyIncome,
          incomeSource: incomeSource,
          momoStatementUrl: momoStatementUrl,
        ),
      );
      state = state.copyWith(
        isLoading: false,
        kycStatus: KycStatus.session2Done,
        currentStep: KycStep.review,
        momoStatementUrl: momoStatementUrl,
      );
      return true;
    } on ServerException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } on NetworkException catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Problème de connexion réseau',
      );
      return false;
    }
  }

  // ── Session 3 : soumission finale ─────────────────────────────────────────

  Future<bool> submitSession3() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.submitSession3();
      // Après soumission, on rafraîchit aussi le user global (authProvider)
      await _ref.read(authProvider.notifier).restoreSession();
      state = state.copyWith(
        isLoading: false,
        kycStatus: KycStatus.session2Done,
        currentStep: KycStep.pending,
        isSuccess: true,
      );
      return true;
    } on ServerException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } on NetworkException catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Problème de connexion réseau',
      );
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  // ── Helpers ────────────────────────────────────────────────────────────────

  KycStep _stepFromStatus(KycStatus status) => switch (status) {
    KycStatus.notStarted => KycStep.intro,
    KycStatus.session1Done => KycStep.financial,
    KycStatus.session2Done => KycStep.review,
    KycStatus.submitted => KycStep.pending,
    KycStatus.validated => KycStep.pending,
    KycStatus.rejected => KycStep.rejected,
  };
}

// ── Provider ──────────────────────────────────────────────────────────────────

final kycProvider = StateNotifierProvider<KycNotifier, KycState>((ref) {
  return KycNotifier(ref.watch(kycRepositoryProvider), ref);
});
