import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../shared/models/auth_user.dart';
import 'user_profile_provider.dart';

final sessionServiceProvider = Provider<SessionService>(
  (ref) => SessionService(),
);

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? errorMessage;
  final bool obscurePassword;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.obscurePassword = true,
  });

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? errorMessage,
    bool? obscurePassword,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      obscurePassword: obscurePassword ?? this.obscurePassword,
    );
  }

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get hasError => status == AuthStatus.error;
  bool get isLoggedIn => status == AuthStatus.authenticated;

  const AuthState.initial()
    : status = AuthStatus.initial,
      user = null,
      errorMessage = null,
      obscurePassword = true;
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    repository: ref.watch(authRepositoryProvider),
    session: ref.watch(sessionServiceProvider),
    ref: ref,
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SessionService _session;
  final Ref _ref;

  AuthNotifier({
    required AuthRepository repository,
    required SessionService session,
    required Ref ref,
  }) : _repository = repository,
       _session = session,
       _ref = ref,
       super(const AuthState.initial());

  // ── Login ──
  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final tokens = await _repository.login(email, password);
      await _session.saveTokens(tokens.accessToken, tokens.refreshToken);
      final user = await _repository.getMe();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      // Load profile after successful login
      _ref.read(userProfileProvider.notifier).loadProfile();
    } on ServerException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
    } on NetworkException catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Problème de connexion. Vérifiez votre réseau.',
      );
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Une erreur inattendue est survenue.',
      );
    }
  }

  // ── Register ── (reste unauthenticated — OTP email requis)
  Future<void> register({
    required String firstName,
    required String lastName,
    String? phone,
    required String email,
    required String password,
    required String city,
    required String district,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      await _repository.register(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
        password: password,
        city: city,
        district: district,
      );
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } on ServerException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
      rethrow;
    } on NetworkException catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Problème de connexion. Vérifiez votre réseau.',
      );
      rethrow;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Une erreur inattendue est survenue.',
      );
      rethrow;
    }
  }

  // ── Verify Email OTP ── (après register ou Google OAuth)
  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final tokens = await _repository.verifyEmail(email, code);
      await _session.saveTokens(tokens.accessToken, tokens.refreshToken);
      final user = await _repository.getMe();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      // Load profile after successful verification
      _ref.read(userProfileProvider.notifier).loadProfile();
    } on ServerException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
    } on NetworkException catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Problème de connexion. Vérifiez votre réseau.',
      );
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Une erreur inattendue est survenue.',
      );
    }
  }

  // ── Login with Google ──
  Future<void> loginWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final googleUser =
          await GoogleSignIn(scopes: ['email', 'profile']).signIn();
      if (googleUser == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw const ServerException('Token Google introuvable');
      }

      final tokens = await _repository.signInWithGoogleIdToken(idToken);
      if (tokens == null) {
        throw const ServerException('Connexion Google impossible');
      }

      await _session.saveTokens(tokens.accessToken, tokens.refreshToken);
      final user = await _repository.getMe();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      // Load profile after successful Google login
      _ref.read(userProfileProvider.notifier).loadProfile();
    } on ServerException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Impossible de se connecter avec Google.',
      );
    }
  }

  Future<void> restoreSession() async {
    final accessToken = await _session.getAccessToken();
    if (accessToken == null) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
      );
      return;
    }

    try {
      final user = await _repository.getMe();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      // Load profile after successful session restore
      _ref.read(userProfileProvider.notifier).loadProfile();
    } catch (_) {
      await _session.clearSession();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
      );
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      await _repository.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } on ServerException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
      rethrow;
    } on NetworkException catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Problème de connexion. Vérifiez votre réseau.',
      );
      rethrow;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Une erreur inattendue est survenue.',
      );
      rethrow;
    }
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? city,
    String? district,
  }) async {
    try {
      final updatedUser = await _repository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        city: city,
        district: district,
      );
      state = state.copyWith(user: updatedUser);
      return true;
    } on ServerException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    } on NetworkException catch (_) {
      state = state.copyWith(
        errorMessage: 'Problème de connexion. Vérifiez votre réseau.',
      );
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return true;
    } on ServerException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    } on NetworkException catch (_) {
      state = state.copyWith(
        errorMessage: 'Problème de connexion. Vérifiez votre réseau.',
      );
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
      await _session.clearSession();
    } catch (_) {
      // Déconnecter même si l'appel échoue
    } finally {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
  void togglePasswordVisibility() =>
      state = state.copyWith(obscurePassword: !state.obscurePassword);
}
