//

part of 'multithreading.dart';

//

sealed class Result<S, F> {
  const Result();

  const factory Result.success(S value) = Success;

  const factory Result.failure(
    F error, [
    StackTrace? stackTrace,
  ]) = Failure;

  static const fromAsync = _fromAsync;
}

//

Future<Result<S, Object>> _fromAsync<S>(
  Future<S> Function() expression,
) async {
  try {
    final value = await expression();
    return Result.success(value);
  } catch (e, st) {
    return Result.failure(e, st);
  }
}

//

final class Success<S, F> implements Result<S, F> {
  const Success(this.value);

  final S value;
}

//

final class Failure<S, F> implements Result<S, F> {
  const Failure(
    this.error, [
    this.stackTrace,
  ]);

  final F error;
  final StackTrace? stackTrace;
}

//

extension ResultPublicAPI<S, F> on Result<S, F> {
  R match<R>({
    required R Function(S value) success,
    required R Function(F error) failure,
  }) =>
      switch (this) {
        Success(value: final value) => success(value),
        Failure(error: final error) => failure(error),
      };
}

//
