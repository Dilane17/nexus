class ServerException implements Exception {
  final String message;

  const ServerException([this.message = 'Erreur serveur inattendue']);

  @override
  String toString() => 'ServerException: $message';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException([this.message = 'Erreur de connexion réseau']);

  @override
  String toString() => 'NetworkException: $message';
}
