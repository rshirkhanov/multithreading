//

part of 'multithreading.dart';

//

@unsendable
abstract interface class Pool {
  const Pool();

  Future<T> enqueue<T>(Task<T> task);
  Future<void> close();
}

//

// TODO(rshirkhanov): implement
final class _Pool implements Pool {
  _Pool(this._workers, this._tasks);

  final LinkedHashSet<Worker> _workers;
  final Queue<Task<Any>> _tasks;

  @override
  Future<T> enqueue<T>(Task<T> task) => _enqueue(task);

  @override
  Future<void> close() => _close();
}

//

// TODO(rshirkhanov): implement
extension on _Pool {
  Future<T> _enqueue<T>(Task<T> task) => throw UnimplementedError();

  Future<void> _close() => throw UnimplementedError();
}

//
