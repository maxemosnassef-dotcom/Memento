sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => '$runtimeType($message)';
}

final class CacheException extends AppException {
  const CacheException(super.message);
}

final class MappingException extends AppException {
  const MappingException(super.message);
}

final class CryptoException extends AppException {
  const CryptoException(super.message);
}

final class SandboxEscapeException extends AppException {
  const SandboxEscapeException(super.message);
}

final class PluginUnavailableException extends AppException {
  const PluginUnavailableException(super.message);
}
