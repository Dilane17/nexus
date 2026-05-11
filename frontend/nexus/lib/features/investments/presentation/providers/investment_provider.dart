import 'package:flutter_riverpod/legacy.dart';
import 'package:nexus/core/error/exceptions.dart';
import 'package:nexus/features/investments/data/models/investment_models.dart';
import 'package:nexus/features/investments/data/repositories/investment_repository.dart';
import 'package:nexus/features/loans/data/models/loan_models.dart';
import 'package:nexus/features/loans/data/repositories/loan_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class InvestmentState {
  final List<Investment> investments;
  final InvestmentSummary? summary;
  final Investment? selectedInvestment;
  final AutoInvestRule? autoInvestRule;
  final List<Loan> marketplaceLoans;
  final bool isLoading;
  final bool isDetailLoading;
  final bool isSummaryLoading;
  final bool isSubmitting;
  final bool isMarketplaceLoading;
  final String? error;
  final int page;
  final bool hasMore;

  const InvestmentState({
    this.investments = const [],
    this.summary,
    this.selectedInvestment,
    this.autoInvestRule,
    this.marketplaceLoans = const [],
    this.isLoading = false,
    this.isDetailLoading = false,
    this.isSummaryLoading = false,
    this.isSubmitting = false,
    this.isMarketplaceLoading = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
  });

  InvestmentState copyWith({
    List<Investment>? investments,
    InvestmentSummary? summary,
    Investment? selectedInvestment,
    AutoInvestRule? autoInvestRule,
    List<Loan>? marketplaceLoans,
    bool? isLoading,
    bool? isDetailLoading,
    bool? isSummaryLoading,
    bool? isSubmitting,
    bool? isMarketplaceLoading,
    String? error,
    int? page,
    bool? hasMore,
    bool clearError = false,
    bool clearSelected = false,
    bool clearRule = false,
  }) {
    return InvestmentState(
      investments: investments ?? this.investments,
      summary: summary ?? this.summary,
      selectedInvestment:
          clearSelected ? null : selectedInvestment ?? this.selectedInvestment,
      autoInvestRule:
          clearRule ? null : autoInvestRule ?? this.autoInvestRule,
      marketplaceLoans: marketplaceLoans ?? this.marketplaceLoans,
      isLoading: isLoading ?? this.isLoading,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isSummaryLoading: isSummaryLoading ?? this.isSummaryLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isMarketplaceLoading:
          isMarketplaceLoading ?? this.isMarketplaceLoading,
      error: clearError ? null : error ?? this.error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class InvestmentNotifier extends StateNotifier<InvestmentState> {
  final InvestmentRepository _repo;
  final LoanRepository _loanRepo;

  InvestmentNotifier(this._repo, this._loanRepo)
      : super(const InvestmentState());

  Future<void> loadInvestments() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      page: 1,
      investments: [],
    );
    try {
      final list = await _repo.getMyInvestments(page: 1);
      state = state.copyWith(
        isLoading: false,
        investments: list,
        page: 1,
        hasMore: list.length >= 10,
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

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoading: true);
    try {
      final more = await _repo.getMyInvestments(page: nextPage);
      state = state.copyWith(
        isLoading: false,
        investments: [...state.investments, ...more],
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

  Future<void> loadSummary() async {
    state = state.copyWith(isSummaryLoading: true);
    try {
      final s = await _repo.getInvestmentSummary();
      state = state.copyWith(isSummaryLoading: false, summary: s);
    } on ServerException catch (e) {
      state = state.copyWith(isSummaryLoading: false, error: e.message);
    } on NetworkException catch (_) {
      state = state.copyWith(
        isSummaryLoading: false,
        error: 'Problème de connexion réseau',
      );
    }
  }

  Future<void> loadInvestmentDetail(String id) async {
    state = state.copyWith(isDetailLoading: true, clearError: true);
    try {
      final inv = await _repo.getInvestmentById(id);
      state = state.copyWith(isDetailLoading: false, selectedInvestment: inv);
    } on ServerException catch (e) {
      state = state.copyWith(isDetailLoading: false, error: e.message);
    } on NetworkException catch (_) {
      state = state.copyWith(
        isDetailLoading: false,
        error: 'Problème de connexion réseau',
      );
    }
  }

  Future<void> loadMarketplace() async {
    state = state.copyWith(isMarketplaceLoading: true, clearError: true);
    try {
      final loans = await _loanRepo.getFundingLoans(page: 1, limit: 20);
      state = state.copyWith(
        isMarketplaceLoading: false,
        marketplaceLoans: loans,
      );
    } on ServerException catch (e) {
      state = state.copyWith(isMarketplaceLoading: false, error: e.message);
    } on NetworkException catch (_) {
      state = state.copyWith(
        isMarketplaceLoading: false,
        error: 'Problème de connexion réseau',
      );
    }
  }

  Future<bool> invest({
    required String loanId,
    required int amount,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final inv = await _repo.createInvestment(
        CreateInvestmentRequest(loanId: loanId, amount: amount),
      );
      state = state.copyWith(
        isSubmitting: false,
        investments: [inv, ...state.investments],
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

  Future<void> loadAutoInvestRule() async {
    try {
      final rule = await _repo.getAutoInvestRule();
      state = state.copyWith(
        autoInvestRule: rule,
        clearRule: rule == null,
      );
    } on ServerException catch (_) {
      // Absence de règle n'est pas une erreur critique
    } on NetworkException catch (_) {}
  }

  Future<bool> saveAutoInvestRule(AutoInvestRuleRequest request) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final rule = await _repo.putAutoInvestRule(request);
      state = state.copyWith(isSubmitting: false, autoInvestRule: rule);
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

  Future<bool> runAutoInvest() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repo.runAutoInvest();
      state = state.copyWith(isSubmitting: false);
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

final investmentProvider =
    StateNotifierProvider<InvestmentNotifier, InvestmentState>(
  (ref) => InvestmentNotifier(
    ref.watch(investmentRepositoryProvider),
    ref.watch(loanRepositoryProvider),
  ),
);
