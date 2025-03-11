//

part of 'multithreading.dart';

//

// TODO(rshirkhanov): T extends Object
abstract interface class Mortal<T> {
  const Mortal();

  // TODO(rshirkhanov): () -> T?
  T get self;

  Future<void> die();
}

//

typedef Ctor<A, T> = Future<Mortal<T>> Function(A args);

//

typedef Scope<T, R> = FutureOr<R> Function(T it);

//

sealed class RAII<A, T> {
  const RAII();

  const factory RAII.of(Ctor<A, T> ctor) = _RAII;

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
