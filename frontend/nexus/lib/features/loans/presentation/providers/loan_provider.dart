import 'package:flutter_riverpod/legacy.dart';
import 'package:nexus/core/error/exceptions.dart';
import 'package:nexus/features/loans/data/models/loan_models.dart';
import 'package:nexus/features/loans/data/repositories/loan_repository.dart';
import 'package:nexus/shared/models/app_enums.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class LoanState {
  final List<Loan> loans;
  final Loan? selectedLoan;
  final bool isLoading; // chargement liste
  final bool isDetailLoading; // chargement détail
  final bool isSubmitting; // create ou repay en cours
  final String? error;
  final int page;
  final bool hasMore;

  const LoanState({
    this.loans = const [],
    this.selectedLoan,
    this.isLoading = false,
    this.isDetailLoading = false,
    this.isSubmitting = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
  });

  LoanState copyWith({
    List<Loan>? loans,
    Loan? selectedLoan,
    bool? isLoading,
    bool? isDetailLoading,
    bool? isSubmitting,
    String? error,
    int? page,
    bool? hasMore,
    bool clearError = false,
    bool clearSelected = false,
  }) {
    return LoanState(
      loans: loans ?? this.loans,
      selectedLoan: clearSelected ? null : selectedLoan ?? this.selectedLoan,
      isLoading: isLoading ?? this.isLoading,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : error ?? this.error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class LoanNotifier extends StateNotifier<LoanState> {
  final LoanRepository _repo;

  LoanNotifier(this._repo) : super(const LoanState());

  // ── Chargement initial (page 1) ────────────────────────────────────────────

  Future<void> loadLoans() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      page: 1,
      loans: [],
    );
    try {
      final loans = await _repo.getMyLoans(page: 1);
      state = state.copyWith(
        isLoading: false,
        loans: loans,
        page: 1,
        hasMore: loans.length >= 10,
      );
    } on ServerException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } on NetworkException catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Problème de connexion réseau',
      );
    }
  }

  // ── Pagination : charger la page suivante ──────────────────────────────────

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoading: true);
    try {
      final more = await _repo.getMyLoans(page: nextPage);
      state = state.copyWith(
        isLoading: false,
        loans: [...state.loans, ...more],
        page: nextPage,
        hasMore: more.length >= 10,
      );
    } on ServerException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } on NetworkException catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Problème de connexion réseau',
      );
    }
  }

  // ── Détail d'un prêt ──────────────────────────────────────────────────────

  Future<void> loadLoanDetail(String id) async {
    state = state.copyWith(isDetailLoading: true, clearError: true);
    try {
      final loan = await _repo.getLoanById(id);
      state = state.copyWith(isDetailLoading: false, selectedLoan: loan);
    } on ServerException catch (e) {
      state = state.copyWith(isDetailLoading: false, error: e.message);
    } on NetworkException catch (_) {
      state = state.copyWith(
        isDetailLoading: false,
        error: 'Problème de connexion réseau',
      );
    }
  }

  // ── Création prêt ─────────────────────────────────────────────────────────

  Future<Loan?> createLoan({
    required int amount,
    required int durationMonths,
    required String purpose,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final loan = await _repo.createLoan(
        CreateLoanRequest(
          amount: amount,
          durationMonths: durationMonths,
          purpose: purpose,
        ),
      );
      // Ajouter en tête de liste
      state = state.copyWith(
        isSubmitting: false,
        loans: [loan, ...state.loans],
        selectedLoan: loan,
      );
      return loan;
    } on ServerException catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.message);
      return null;
    } on NetworkException catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Problème de connexion réseau',
      );
      return null;
    }
  }

  // ── Remboursement ─────────────────────────────────────────────────────────

  Future<bool> repayLoan({
    required String loanId,
    required int amount,
    required String momoReference,
    required MomoProvider provider,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final updated = await _repo.repayLoan(
        loanId,
        RepayLoanRequest(
          amount: amount,
          momoReference: momoReference,
          momoProvider: provider,
        ),
      );
      // Mettre à jour le prêt dans la liste et dans selectedLoan
      state = state.copyWith(
        isSubmitting: false,
        selectedLoan: updated,
        loans: state.loans.map((l) => l.id == loanId ? updated : l).toList(),
      );
      return true;
    } on ServerException catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.message);
      return false;
    } on NetworkException catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Problème de connexion réseau',
      );
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final loanProvider = StateNotifierProvider<LoanNotifier, LoanState>(
  (ref) => LoanNotifier(ref.watch(loanRepositoryProvider)),
);
