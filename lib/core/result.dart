import 'error/failures.dart';

sealed class Result<T> {
  const Result();

  factory Result.ok(T value) = Ok<T>;

  factory Result.err(Failure failure) = Err<T>;

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T? getOrNull() => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  Failure? failureOrNull() => switch (this) {
        Ok<T>() => null,
        Err<T>(:final failure) => failure,
      };

  R fold<R>({
    required R Function(Failure failure) onError,
    required R Function(T value) onSuccess,
  }) =>
      switch (this) {
        Ok<T>(:final value) => onSuccess(value),
        Err<T>(:final failure) => onError(failure),
      };

  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        final Ok<T> ok => Result.ok(transform(ok.value)),
        final Err<T> err => Result.err(err.failure),
      };

  Future<Result<R>> flatMap<R>(Future<Result<R>> Function(T value) transform) =>
      switch (this) {
        final Ok<T> ok => transform(ok.value),
        final Err<T> err => Future.value(Result<R>.err(err.failure)),
      };
}

final class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

final class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);
}
