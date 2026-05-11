import 'package:flutter_riverpod/legacy.dart';

/// État frontend générique pour les actions asynchrones (submit, create, update).
/// Unifie la logique de loading/success/error répétée dans les providers.
class AsyncActionState<T> {
  final bool isSubmitting;
  final String? error;
  final T? data;
  final bool isSuccess;

  const AsyncActionState({
    this.isSubmitting = false,
    this.error,
    this.data,
    this.isSuccess = false,
  });

  /// État initial.
  factory AsyncActionState.initial() {
    return const AsyncActionState();
  }

  /// État de chargement.
  AsyncActionState<T> asLoading() {
    return AsyncActionState<T>(
      isSubmitting: true,
      error: null,
      isSuccess: false,
    );
  }

  /// État de succès avec données.
  AsyncActionState<T> asSuccess(T? data) {
    return AsyncActionState<T>(
      isSubmitting: false,
      error: null,
      data: data,
      isSuccess: true,
    );
  }

  /// État d'erreur.
  AsyncActionState<T> asError(String error) {
    return AsyncActionState<T>(
      isSubmitting: false,
      error: error,
      isSuccess: false,
    );
  }

  /// Réinitialise l'état.
  AsyncActionState<T> reset() {
    return AsyncActionState<T>();
  }

  /// Vérifie si une erreur est présente.
  bool get hasError => error != null;

  /// Vérifie si l'action est en cours.
  bool get isLoading => isSubmitting;

  AsyncActionState<T> copyWith({
    bool? isSubmitting,
    String? error,
    T? data,
    bool? isSuccess,
    bool clearError = false,
  }) {
    return AsyncActionState<T>(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : error ?? this.error,
      data: data ?? this.data,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Notifier générique pour les actions asynchrones.
/// Réduit la duplication dans les providers d'actions (submit, create, update).
class AsyncActionNotifier<T> extends StateNotifier<AsyncActionState<T>> {
  AsyncActionNotifier() : super(AsyncActionState.initial());

  /// Exécute une action asynchrone.
  Future<bool> execute(Future<T?> Function() action) async {
    state = state.asLoading();
    try {
      final result = await action();
      state = state.asSuccess(result);
      return true;
    } catch (e) {
      state = state.asError('Erreur: ${e.toString()}');
      return false;
    }
  }

  /// Réessaye l'action.
  Future<bool> retry(Future<T?> Function() action) async {
    return execute(action);
  }

  /// Efface l'erreur.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Réinitialise l'état.
  void reset() {
    state = state.reset();
  }
}

/// Notifier générique pour les actions asynchrones sans données de retour.
class SimpleActionNotifier extends StateNotifier<AsyncActionState<void>> {
  SimpleActionNotifier() : super(AsyncActionState.initial());

  /// Exécute une action asynchrone sans données de retour.
  Future<bool> execute(Future<void> Function() action) async {
    state = state.asLoading();
    try {
      await action();
      state = state.asSuccess(null);
      return true;
    } catch (e) {
      state = state.asError('Erreur: ${e.toString()}');
      return false;
    }
  }

  /// Réessaye l'action.
  Future<bool> retry(Future<void> Function() action) async {
    return execute(action);
  }

  /// Efface l'erreur.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Réinitialise l'état.
  void reset() {
    state = state.reset();
  }
}
