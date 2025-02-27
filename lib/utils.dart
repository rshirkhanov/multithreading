//

part of 'multithreading.dart';

//

typedef Any = Object?;

//

@preferInline
T the<T>(T value) => value;

@preferInline
T safeCast<U, T extends U>(T value) => value;

@preferInline
T unsafeCast<U, T>(U value) => value as T;

@preferInline
T? tryCast<U, T>(U value) => value is T ? value : null;

//

extension AnyLetX<T> on T {
  @preferInline
  R let<R>(R Function(T) expression) => expression(this);

  @preferInline
  T also(void Function(T) callback) => this..let(callback);
}

//

extension StreamWhereTypeX<A> on Stream<A> {
  @preferInline
  Stream<B> whereType<B extends A>() => where((it) => it is B).cast();
}

//

extension StreamEnumeratedX<A> on Stream<A> {
  Stream<(int, A)> get enumerated async* {
    var index = -1;
    await for (final value in this) {
      yield (++index, value);
    }
  }
}

//
