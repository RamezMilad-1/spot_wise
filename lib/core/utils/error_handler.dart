import 'dart:async';

import 'app_exception.dart';

/// Converts any thrown object into a short, friendly sentence for the UI.
/// Avoids `dart:io` so it compiles for web as well as mobile/desktop.
String friendlyError(Object error) {
  if (error is AppException) return error.message;
  if (error is TimeoutException) {
    return 'The request timed out. Please try again.';
  }

  final text = error.toString();
  if (text.contains('SocketException') ||
      text.contains('Failed host lookup') ||
      text.contains('Connection refused') ||
      text.contains('ClientException') ||
      text.contains('XMLHttpRequest')) {
    return 'No internet connection. Check your network and try again.';
  }

  return 'Something went wrong. Please try again.';
}

/// Wraps an async call, returning its value or rethrowing as an [AppException]
/// with a friendly message (keeps provider code tidy).
Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on AppException {
    rethrow;
  } catch (e) {
    throw AppException(friendlyError(e));
  }
}
