//

part of 'multithreading.dart';

//

@unsendable
abstract interface class Dispatcher {
  const Dispatcher();

  Future<T> dispatch<T>(Task<T> task);
  Future<void> die();
}

//

// TODO(rshirkhanov): implement
final class _Dispatcher implements Dispatcher {
  _Dispatcher(this._workers, this._tasks);

  final Set<Worker> _workers;
  final Queue<Task<Any>> _tasks;

  @override
  Future<T> dispatch<T>(Task<T> task) => _dispatch(task);

  @override
  Future<void> die() => _die();
}

//

// TODO(rshirkhanov): implement
extension on _Dispatcher {
  Future<T> _dispatch<T>(Task<T> task) => throw UnimplementedError();

  Future<void> _die() => throw UnimplementedError();
}

//

// TODO(rshirkhanov): implement spawn(config) method
// TODO(rshirkhanov): check that config.workerCount <= availableWorkersCount

//
