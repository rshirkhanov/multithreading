//

part of 'multithreading.dart';

//

final _availableWorkersCount = Platform.numberOfProcessors - 1;

//

sealed class Initialization {
  const Initialization();
}

//

final class Eager implements Initialization {
  const Eager(this.workerCount)
      : assert(
          1 <= workerCount,
          '"workerCount" must be greater than or equal to 1',
        );

  factory Eager.max() => Eager(_availableWorkersCount);

  final int workerCount;
}

//

final class Lazy implements Initialization {
  const Lazy({required int max, int min = 1})
      : assert(
          1 <= min,
          '"min" must be greater than or equal to 1',
        ),
        assert(
          min <= max,
          '"min" must be less than or equal to "max"',
        ),
        workerCount = (min: min, max: max);

  factory Lazy.max() => Lazy(max: _availableWorkersCount);

  final ({int min, int max}) workerCount;
}

//

final class Capacity {
  const Capacity.unlimited() : value = double.infinity;

  const Capacity.exact(int this.value)
      : assert(
          1 <= value,
          '"value" must be greater than or equal to 1',
        );

  final num value;
}

//

final class Config {
  const Config({
    required this.initialization,
    required this.debugName,
  });

  final Initialization initialization;
  final String? debugName;
}

//
