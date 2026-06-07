/// Base for all app-level errors that carry a user-facing [message].
class AppException implements Exception {
  final String message;
  final String? details;

  const AppException(this.message, {this.details});

  @override
  String toString() => message;
}

/// No connectivity / failed host lookup.
class NetworkException extends AppException {
  const NetworkException([
    super.message = 'No internet connection. Check your network and try again.',
  ]);
}

/// Auth failures (wrong credentials, weak password, email in use…).
class AuthException extends AppException {
  const AuthException(super.message, {super.details});
}

/// Thrown by a remote service when the relevant `.env` value is missing, so the
/// UI can point the user at Settings → Integrations.
class NotConfiguredException extends AppException {
  const NotConfiguredException(super.message);
}

/// A backend/server error (non-2xx response, malformed payload…).
class ServerException extends AppException {
  const ServerException([
    super.message = 'The server could not complete that request.',
  ]);
}
