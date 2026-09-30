sealed class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => '$runtimeType($message)';
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Local encrypted store unavailable']);
}

final class CryptoFailure extends Failure {
  const CryptoFailure([super.message = 'Cryptographic operation failed']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}

final class PermissionFailure extends Failure {
  final bool permanentlyDenied;
  const PermissionFailure([
    super.message = 'Required permission not granted',
    this.permanentlyDenied = false,
  ]);
}

final class CapabilityFailure extends Failure {
  const CapabilityFailure([super.message = 'Device capability unavailable']);
}

final class NotificationFailure extends Failure {
  const NotificationFailure([super.message = 'Notification could not be delivered']);
}
