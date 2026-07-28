class AuthorizationException implements Exception {
  const AuthorizationException(this.message);

  final String message;

  @override
  String toString() => 'AuthorizationException: $message';
}
