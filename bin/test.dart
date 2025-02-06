// ignore_for_file: avoid_print

import 'package:multithreading/multithreading.dart';

//

typedef Lazy<R> = R Function();

//

(R, R) duplicate<R>(Lazy<R> expression) => (expression(), expression());

//

Iterable<T> sequence<T>(
  int count,
  T Function(int index) expression,
) sync* {
  assert(count > 0, '"count" must be greater than zero');
  for (var i = 0; i < count; i++) {
    yield expression(i);
  }
}

//

Task<int> createTask(int i) => () => Future.delayed(
      const Duration(seconds: 1),
      () => i + 1,
    );

//

extension IterableMapIndexedX<A> on Iterable<A> {
  Iterable<B> mapIndexed<B>(B Function(int index, A value) transform) sync* {
    var index = -1;
    for (final value in this) {
      yield transform(++index, value);
    }
  }
}

//

extension HomoPairChooseX<T> on (T, T) {
  // ignore: avoid_positional_boolean_parameters
  T choose(bool condition) => condition ? $1 : $2;
}

//

extension HomoPairMapX<A> on (A, A) {
  (B, B) map<B>(B Function(A) transform) => (transform($1), transform($2));
}

//

extension IterableNumSumX<T extends num> on Iterable<T> {
  T get sum => reduce((s, x) => (s + x) as T);
}

//

Future<void> main() async {
  final workers = await duplicate(Worker.spawn).wait;

  print('BEGIN');

  try {
    final results = await sequence(10, createTask)
        .mapIndexed((index, task) => workers.choose(index.isEven).perform(task))
        .wait;

    print(results.sum);
  } catch (exception, stackTrace) {
    print((exception, stackTrace));
  } finally {
    await workers.map((it) => it.die()).wait;
  }

  print('END');
}

//
