//

part of 'multithreading.dart';

//

@unsendable
abstract interface class Dispatcher {
  const Dispatcher._();

  static const spawn = _DispatcherUnsafeAPI.spawn;

  Future<T> dispatch<T>(Task<T> task);
  Future<void> die();
}

//

// TODO(rshirkhanov): implement
final class _Dispatcher implements Dispatcher {
  _Dispatcher();

  @override
  Future<T> dispatch<T>(Task<T> task) => _dispatch(task);

  @override
  Future<void> die() => _die();
}

//

// TODO(rshirkhanov): implement
extension _DispatcherPrivateAPI on _Dispatcher {
  @alwaysInline
  Future<T> _dispatch<T>(Task<T> task) => throw UnimplementedError();

  @alwaysInline
  Future<void> _die() => throw UnimplementedError();
}

//

// TODO(rshirkhanov): implement
extension _DispatcherUnsafeAPI on Dispatcher {
  static const maxWorkerCountGTAvailableWorkersCount =
      '"maxWorkerCount" must be less than or equal to "_availableWorkersCount"';

  static Future<Dispatcher> spawn({
    required DispatcherRules rules,
  }) {
    assert(
      rules.initialization.maxWorkerCount <= _availableWorkersCount,
      maxWorkerCountGTAvailableWorkersCount,
    );
    throw UnimplementedError();
  }
}

//
