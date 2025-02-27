//

part of 'multithreading.dart';

//

final _availableWorkersCount = Platform.numberOfProcessors - 1;

//

sealed class Initialization {
  const Initialization._();
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

extension _InitializationMaxWorkerCountX on Initialization {
  int get maxWorkerCount => switch (this) {
        final Eager self => self.workerCount,
        final Lazy self => self.workerCount.max,
      };
}

//

final class Capacity {
  const Capacity.exact(int this.value)
      : assert(
          1 <= value,
          '"value" must be greater than or equal to 1',
        );

  const Capacity._unlimited() : value = double.infinity;

  static const unlimited = Capacity._unlimited();

  final num value;
}

//

final class DispatcherRules {
  const DispatcherRules({
    required this.initialization,
    this.debugName,
  });

  final Initialization initialization;
  final String? debugName;
}

//

final class WorkerRules {
  const WorkerRules({
    this.capacity = Capacity.unlimited,
    this.debugName,
  });

  final Capacity capacity;
  final String? debugName;
}

//
