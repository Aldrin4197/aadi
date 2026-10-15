/// Lightweight functional result type used across repositories.
///
/// Repositories may either throw [AppException] or return a [Result]. The
/// sealed type makes exhaustive handling easy in controllers/UI.
sealed class Result<T> {
  const Result();
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.failure);
  final AppException failure;
}

/// Domain-level failure with a user-safe [message].
class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'AppException: $message';
}
