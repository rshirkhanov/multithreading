//

part of 'multithreading.dart';

//

abstract interface class Mortal<T> {
  const Mortal();

  T get self;
  Future<void> die();
}

//

typedef Ctor<A, T> = Future<Mortal<T>> Function(A args);

//

typedef Scope<T, R> = FutureOr<R> Function(T it);

//

abstract interface class RAII<A, T> {
  const RAII();

  const factory RAII.of(Ctor<A, T> ctor) = _RAII.new;

  Future<R> scoped<R>(A args, Scope<T, R> scope);
}

//

final class _RAII<A, T> implements RAII<A, T> {
  const _RAII(this._ctor);

  final Ctor<A, T> _ctor;

  @override
  Future<R> scoped<R>(A args, Scope<T, R> scope) async {
    final mortal = await _ctor(args);

    try {
      return await scope(mortal.self);
    } catch (_) {
      rethrow;
    } finally {
      await mortal.die();
    }
  }
}

//
