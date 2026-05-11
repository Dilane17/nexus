import 'package:flutter_riverpod/legacy.dart';

/// État frontend générique pour les listes paginées.
/// Unifie la logique de pagination répétée dans les providers.
class PaginatedState<T> {
  final List<T> items;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasMore;

  const PaginatedState({
    this.items = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.page = 1,
    this.limit = 10,
    this.total = 0,
    this.totalPages = 0,
    this.hasMore = true,
  });

  /// État initial vide.
  factory PaginatedState.initial({int limit = 10}) {
    return PaginatedState(limit: limit);
  }

  /// État de chargement initial.
  PaginatedState<T> asLoading() {
    return PaginatedState<T>(
      items: [],
      isLoading: true,
      error: null,
      page: 1,
      limit: limit,
      total: 0,
      totalPages: 0,
      hasMore: true,
    );
  }

  /// État de rafraîchissement (refresh).
  PaginatedState<T> asRefreshing() {
    return PaginatedState<T>(
      items: items,
      isLoading: false,
      isRefreshing: true,
      error: null,
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
      hasMore: hasMore,
    );
  }

  /// État de chargement de la page suivante.
  PaginatedState<T> asLoadingMore() {
    return PaginatedState<T>(
      items: items,
      isLoading: true,
      isRefreshing: false,
      error: null,
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
      hasMore: hasMore,
    );
  }

  /// État d'erreur.
  PaginatedState<T> asError(String error) {
    return PaginatedState<T>(
      items: items,
      isLoading: false,
      isRefreshing: false,
      error: error,
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
      hasMore: hasMore,
    );
  }

  /// État de succès avec nouvelles données.
  PaginatedState<T> withData({
    required List<T> newItems,
    required int page,
    required int total,
    required int totalPages,
    bool append = false,
  }) {
    final updatedItems = append ? [...items, ...newItems] : newItems;
    final hasMore = page < totalPages;

    return PaginatedState<T>(
      items: updatedItems,
      isLoading: false,
      isRefreshing: false,
      error: null,
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
      hasMore: hasMore,
    );
  }

  /// Vérifie si l'état est vide (pas d'items et pas de chargement).
  bool get isEmpty => items.isEmpty && !isLoading && !isRefreshing;

  /// Vérifie si l'état a des données.
  bool get hasData => items.isNotEmpty;

  /// Vérifie si une erreur est présente.
  bool get hasError => error != null;

  /// Vérifie si le chargement initial est en cours.
  bool get isInitialLoading => isLoading && page == 1;

  /// Vérifie si le chargement de la page suivante est en cours.
  bool get isLoadingMore => isLoading && page > 1;

  PaginatedState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    int? page,
    int? limit,
    int? total,
    int? totalPages,
    bool? hasMore,
    bool clearError = false,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : error ?? this.error,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Notifier générique pour la pagination.
/// Réduit la duplication dans les providers de listes paginées.
class PaginatedNotifier<T> extends StateNotifier<PaginatedState<T>> {
  final Future<List<T>> Function(int page, int limit) fetchItems;
  final int defaultLimit;

  PaginatedNotifier({required this.fetchItems, this.defaultLimit = 10})
    : super(PaginatedState.initial(limit: defaultLimit));

  /// Charge la première page.
  Future<void> load() async {
    state = state.asLoading();
    try {
      final items = await fetchItems(1, state.limit);
      state = state.withData(
        newItems: items,
        page: 1,
        total: items.length,
        totalPages: items.length < state.limit ? 1 : 2,
      );
    } catch (e) {
      state = state.asError('Erreur de chargement: ${e.toString()}');
    }
  }

  /// Rafraîchit la liste (recharge depuis la page 1).
  Future<void> refresh() async {
    state = state.asRefreshing();
    try {
      final items = await fetchItems(1, state.limit);
      state = state.withData(
        newItems: items,
        page: 1,
        total: items.length,
        totalPages: items.length < state.limit ? 1 : 2,
      );
    } catch (e) {
      state = state.asError('Erreur de rafraîchissement: ${e.toString()}');
    }
  }

  /// Charge la page suivante.
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;

    state = state.asLoadingMore();
    try {
      final nextPage = state.page + 1;
      final items = await fetchItems(nextPage, state.limit);
      state = state.withData(
        newItems: items,
        page: nextPage,
        total: state.total + items.length,
        totalPages: items.length < state.limit ? nextPage : nextPage + 1,
        append: true,
      );
    } catch (e) {
      state = state.asError('Erreur de chargement: ${e.toString()}');
    }
  }

  /// Réessaye le chargement après une erreur.
  Future<void> retry() async {
    await load();
  }

  /// Efface l'erreur.
  void clearError() {
    state = state.copyWith(error: null);
  }
}
