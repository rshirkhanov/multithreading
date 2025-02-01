//

part of 'multithreading.dart';

//

typedef Task<T> = Future<T> Function();

//

extension TaskPublicAPI<T> on Task<T> {
  Future<T> run() => this.call();
}

//
