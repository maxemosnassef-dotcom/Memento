import 'exceptions.dart';
import 'failures.dart';

extension ExceptionToFailure on Object {
  Failure toFailure() => switch (this) {
        final CacheException e => DatabaseFailure(e.message),
        final MappingException e => ValidationFailure(e.message),
        final CryptoException e => CryptoFailure(e.message),
        final SandboxEscapeException e =>
          CryptoFailure('Blocked sandbox escape: ${e.message}'),
        final PluginUnavailableException e => CapabilityFailure(e.message),
        _ => DatabaseFailure(toString()),
      };
}
