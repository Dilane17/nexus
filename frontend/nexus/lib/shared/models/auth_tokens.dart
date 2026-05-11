import 'auth_user.dart';

/// Modèle pour les tokens JWT (access et refresh).
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final AuthUser? user;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user:
          json['user'] != null
              ? AuthUser.fromJson(json['user'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'user': user?.toJson(),
    };
  }
}
