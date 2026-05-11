import 'package:flutter_riverpod/legacy.dart';
import 'package:nexus/core/error/exceptions.dart';
import 'package:nexus/features/wallet/data/models/transaction_models.dart';
import 'package:nexus/features/wallet/data/repositories/transaction_repository.dart';
import 'package:nexus/shared/models/app_enums.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class TransactionState {
  final List<Transaction> transactions;
  final TransactionType? selectedType;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final int page;
  final bool hasMore;

  const TransactionState({
    this.transactions = const [],
    this.selectedType,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
  });

  TransactionState copyWith({
    List<Transaction>? transactions,
    TransactionType? selectedType,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    int? page,
    bool? hasMore,
    bool clearError = false,
    bool clearType = false,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      selectedType: clearType ? null : selectedType ?? this.selectedType,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : error ?? this.error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class TransactionNotifier extends StateNotifier<TransactionState> {
  final TransactionRepository _repo;

  TransactionNotifier(this._repo) : super(const TransactionState());

  Future<void> loadTransactions({TransactionType? type}) async {
    final effectiveType = type ?? state.selectedType;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      page: 1,
      transactions: [],
      selectedType: effectiveType,
    );
    try {
      final txs = await _repo.getMyTransactions(
        page: 1,
        type: effectiveType?.toJson(),
      );
      state = state.copyWith(
        isLoading: false,
        transactions: txs,
        page: 1,
        hasMore: txs.length >= 20,
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

  Future<void> filterByType(TransactionType? type) async {
    await loadTransactions(type: type);
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoading: true);
    try {
      final more = await _repo.getMyTransactions(
        page: nextPage,
        type: state.selectedType?.toJson(),
      );
      state = state.copyWith(
        isLoading: false,
        transactions: [...state.transactions, ...more],
        page: nextPage,
        hasMore: more.length >= 20,
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

  Future<bool> deposit({
    required int amount,
    required MomoProvider provider,
    required String phone,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final tx = await _repo.deposit(
        DepositRequest(
          amount: amount,
          momoProvider: provider,
          momoPhone: phone,
        ),
      );
      state = state.copyWith(
        isSubmitting: false,
        transactions: [tx, ...state.transactions],
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

  Future<bool> withdraw({
    required int amount,
    required MomoProvider provider,
    required String number,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final tx = await _repo.withdraw(
        WithdrawalRequest(
          amount: amount,
          momoProvider: provider,
          momoNumber: number,
        ),
      );
      state = state.copyWith(
        isSubmitting: false,
        transactions: [tx, ...state.transactions],
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

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>(
      (ref) => TransactionNotifier(ref.watch(transactionRepositoryProvider)),
    );
