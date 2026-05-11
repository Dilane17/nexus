import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexus/core/error/exceptions.dart';
import 'package:nexus/features/tontine/data/models/tontine_models.dart';
import 'package:nexus/features/tontine/data/repositories/tontine_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class TontineState {
  final TontineScore? myScore;
  final List<TontineGroup> groups;
  final TontineGroup? selectedGroup;
  final List<TontineCycle> cycles;
  final bool isLoading;
  final bool isDetailLoading;
  final bool isScoreLoading;
  final bool isCyclesLoading;
  final bool isSubmitting;
  final String? error;
  final int page;
  final bool hasMore;

  const TontineState({
    this.myScore,
    this.groups = const [],
    this.selectedGroup,
    this.cycles = const [],
    this.isLoading = false,
    this.isDetailLoading = false,
    this.isScoreLoading = false,
    this.isCyclesLoading = false,
    this.isSubmitting = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
  });

  TontineState copyWith({
    TontineScore? myScore,
    List<TontineGroup>? groups,
    TontineGroup? selectedGroup,
    List<TontineCycle>? cycles,
    bool? isLoading,
    bool? isDetailLoading,
    bool? isScoreLoading,
    bool? isCyclesLoading,
    bool? isSubmitting,
    String? error,
    int? page,
    bool? hasMore,
    bool clearError = false,
    bool clearSelected = false,
  }) {
    return TontineState(
      myScore: myScore ?? this.myScore,
      groups: groups ?? this.groups,
      selectedGroup: clearSelected ? null : selectedGroup ?? this.selectedGroup,
      cycles: cycles ?? this.cycles,
      isLoading: isLoading ?? this.isLoading,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isScoreLoading: isScoreLoading ?? this.isScoreLoading,
      isCyclesLoading: isCyclesLoading ?? this.isCyclesLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : error ?? this.error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class TontineNotifier extends Notifier<TontineState> {
  TontineRepository get _repo => ref.watch(tontineRepositoryProvider);

  @override
  TontineState build() => const TontineState();

  Future<void> loadScore() async {
    state = state.copyWith(isScoreLoading: true);
    try {
      final score = await _repo.getMyScore();
      state = state.copyWith(isScoreLoading: false, myScore: score);
    } on ServerException catch (e) {
      state = state.copyWith(isScoreLoading: false, error: e.message);
    } on NetworkException catch (_) {
      state = state.copyWith(isScoreLoading: false);
    }
  }

  Future<void> loadGroups() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      page: 1,
      groups: [],
    );
    try {
      final list = await _repo.getGroups(page: 1);
      state = state.copyWith(
        isLoading: false,
        groups: list,
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
      final more = await _repo.getGroups(page: nextPage);
      state = state.copyWith(
        isLoading: false,
        groups: [...state.groups, ...more],
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

  Future<void> loadGroupDetail(String id) async {
    state = state.copyWith(isDetailLoading: true, clearError: true);
    try {
      final group = await _repo.getGroupById(id);
      state = state.copyWith(
        isDetailLoading: false,
        selectedGroup: group,
        cycles: group.cycles,
      );
    } on ServerException catch (e) {
      state = state.copyWith(isDetailLoading: false, error: e.message);
    } on NetworkException catch (_) {
      state = state.copyWith(
        isDetailLoading: false,
        error: 'Problème de connexion réseau',
      );
    }
  }

  Future<void> loadCycles(String groupId) async {
    state = state.copyWith(isCyclesLoading: true);
    try {
      final group = await _repo.getGroupById(groupId);
      state = state.copyWith(
        isCyclesLoading: false,
        cycles: group.cycles,
        selectedGroup: group,
      );
    } on ServerException catch (e) {
      state = state.copyWith(isCyclesLoading: false, error: e.message);
    } on NetworkException catch (_) {
      state = state.copyWith(isCyclesLoading: false);
    }
  }

  Future<TontineGroup?> createGroup({
    required String name,
    required int monthlyContribution,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final group = await _repo.createGroup(
        CreateTontineGroupRequest(
          name: name,
          monthlyContribution: monthlyContribution,
        ),
      );
      state = state.copyWith(
        isSubmitting: false,
        groups: [group, ...state.groups],
        selectedGroup: group,
      );
      return group;
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

  Future<bool> joinGroup(String id) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repo.joinGroup(id);
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

  Future<TontineCycle?> createCycle({
    required String groupId,
    required int cycleNumber,
    required DateTime startDate,
    required DateTime endDate,
    required String beneficiaryId,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final cycle = await _repo.createCycle(
        groupId,
        CreateCycleRequest(
          cycleNumber: cycleNumber,
          startDate: startDate,
          endDate: endDate,
          beneficiaryId: beneficiaryId,
        ),
      );
      state = state.copyWith(
        isSubmitting: false,
        cycles: [...state.cycles, cycle],
      );
      return cycle;
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

  Future<TontineCycle?> completeCycle({
    required String cycleId,
    required int membersPaid,
    required int membersDefaulted,
    required num totalCollected,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final updatedCycle = await _repo.completeCycle(
        cycleId,
        CompleteCycleRequest(
          membersPaid: membersPaid,
          membersDefaulted: membersDefaulted,
          totalCollected: totalCollected,
        ),
      );
      final updatedCycles =
          state.cycles.map((c) {
            return c.id == cycleId ? updatedCycle : c;
          }).toList();
      state = state.copyWith(isSubmitting: false, cycles: updatedCycles);
      return updatedCycle;
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

  void clearError() => state = state.copyWith(clearError: true);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final tontineProvider = NotifierProvider<TontineNotifier, TontineState>(
  TontineNotifier.new,
);
