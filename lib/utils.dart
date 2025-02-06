//

part of 'multithreading.dart';

//

typedef Any = Object?;

//

extension AnyLetX<T> on T {
  R let<R>(R Function(T) expression) => expression(this);
}

//

extension StreamWhereTypeX<A> on Stream<A> {
  Stream<B> whereType<B extends A>() => where((it) => it is B).cast();
}

//
