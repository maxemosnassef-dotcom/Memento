import 'package:flutter_test/flutter_test.dart';
import 'package:memento/core/error/exceptions.dart';
import 'package:memento/core/error/failures.dart';
import 'package:memento/core/error/mapping.dart';
import 'package:memento/core/result.dart';

void main() {
  group('Result.ok', () {
    test('folds to success branch', () {
      final result = Result<int>.ok(42);
      final output = result.fold(
        onError: (failure) => -1,
        onSuccess: (value) => value,
      );
      expect(output, 42);
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), 42);
      expect(result.failureOrNull(), isNull);
    });

    test('map transforms the success value', () {
      final result = Result<int>.ok(2);
      expect(result.map((v) => v * 10).getOrNull(), 20);
    });
  });

  group('Result.err', () {
    const failure = ValidationFailure('bad input');

    test('folds to error branch', () {
      final result = Result<int>.err(failure);
      expect(result.isErr, isTrue);
      expect(result.getOrNull(), isNull);
      expect(result.failureOrNull(), same(failure));
    });

    test('map short-circuits and preserves the failure', () {
      final result = Result<int>.err(failure);
      final mapped = result.map((v) => v * 10);
      expect(mapped.failureOrNull(), same(failure));
    });

    test('flatMap propagates failures without invoking transform', () async {
      var invoked = false;
      final result = Result<int>.err(failure);
      await result.flatMap((_) async {
        invoked = true;
        return Future.value(Result<String>.ok('never'));
      });
      expect(invoked, isFalse);
    });
  });

  group('ExceptionToFailure', () {
    test('maps typed exceptions to matching failures', () {
      expect(const CacheException('db gone').toFailure(), isA<DatabaseFailure>());
      expect(
          const MappingException('oops').toFailure(), isA<ValidationFailure>());
      expect(const CryptoException('boom').toFailure(), isA<CryptoFailure>());
      expect(const PluginUnavailableException('no plugin').toFailure(),
          isA<CapabilityFailure>());
      expect(const SandboxEscapeException('../etc').toFailure(),
          isA<CryptoFailure>());
    });

    test('sandbox escape messages are preserved', () {
      final failure =
          const SandboxEscapeException('/etc/passwd').toFailure() as CryptoFailure;
      expect(failure.message, contains('/etc/passwd'));
    });
  });
}
