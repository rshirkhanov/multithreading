// ignore_for_file: avoid_print

import 'package:multithreading/multithreading.dart';

//

(R, R) duplicate<R>(R Function() expression) => (expression(), expression());

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

extension<A> on Iterable<A> {
  Iterable<B> mapIndexed<B>(
    B Function(int index, A value) transform,
  ) sync* {
    var index = -1;
    for (final value in this) {
      yield transform(++index, value);
    }
  }
}

//

extension<T> on (T, T) {
  // ignore: avoid_positional_boolean_parameters
  T select(bool condition) => condition ? $1 : $2;
}

//

extension<A> on (A, A) {
  (B, B) map<B>(B Function(A) transform) => (transform($1), transform($2));
}

//

extension<T extends num> on Iterable<T> {
  T get sum => reduce((s, x) => (s + x) as T);
}

//

Future<void> main() async {
  print('BEGIN');

  const defaultRules = (capacity: Capacity.unlimited, debugName: null);
  final workers = await duplicate(() => Worker.spawn(rules: defaultRules)).wait;

  try {
    final results = await sequence(10, createTask)
        .mapIndexed((index, task) => workers.select(index.isEven).perform(task))
        .wait;

    print(results.sum);
  } catch (_, __) {
    rethrow;
  } finally {
    await workers.map((it) => it.die()).wait;
  }

  print('END');
}

//
