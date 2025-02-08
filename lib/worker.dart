//

part of 'multithreading.dart';

//

@unsendable
abstract interface class Worker {
  const Worker._();

  static const spawn = _spawn;
  static const scoped = _WorkerSafeAPI.scoped;

  Future<T> perform<T>(Task<T> task);
  Future<void> die();
}

//

typedef _Input<T> = ({Id id, Task<T> task});

typedef _Output<T> = ({Id id, Result<T, Object> result});

//

@unsendable
final class _IsolateWorker implements Worker {
  _IsolateWorker._(
    this._receivePort,
    this._received,
    this._exitPort,
    this._isolate,
    this._sendPort,
    this._pending,
  ) {
    _subscription = _received.whereType<_Output<Any>>().listen(_onReceived);
  }

  final ReceivePort _receivePort;
  final Stream<Any> _received;
  final ReceivePort _exitPort;
  final Isolate _isolate;
  final SendPort _sendPort;
  final Map<Id, Completer<Any>> _pending;

  late final StreamSubscription<_Output<Any>> _subscription;

  @override
  Future<T> perform<T>(Task<T> task) => _perform(task);

  @override
  Future<void> die() => _die();
}

//

extension _ThreadPrivateAPI on _IsolateWorker {
  @neverInline
  void _onReceived<T>(_Output<T> output) {
    final completer = _pending.remove(output.id);
    if (completer != null) {
      return output.result.match(
        success: completer.complete,
        failure: completer.completeError,
      );
    }
  }

  @alwaysInline
  Future<T> _perform<T>(Task<T> task) {
    final id = Id();
    final completer = Completer<T>();
    _pending[id] = completer;
    final input = (id: id, task: task);
    final _ = _sendPort.send(input);
    return completer.future;
  }

  @alwaysInline
  Future<void> _die() async {
    final exit = _exitPort.first;
    _sendPort.send(#kill);
    await _subscription.cancel();
    _receivePort.close();
    _isolate.kill();
    await exit;
    _pending
      ..values.forEach(_completeError)
      ..clear();
  }

  @neverInline
  void _completeError<T>(Completer<T> it) =>
      it.completeError(RemoteError('Worker was killed', ''));
}

//

@neverInline
Future<Worker> _spawn({
  Capacity capacity = const Capacity.unlimited(),
  String? debugName,
}) async {
  final receivePort = ReceivePort();
  final received = receivePort.asBroadcastStream();

  final exitPort = ReceivePort();

  final isolate = await Isolate.spawn(
    _entryPoint,
    receivePort.sendPort,
    debugName: debugName,
    onExit: exitPort.sendPort,
  );
  final sendPort = (await received.first) as SendPort;

  final pending = HashMap<Id, Completer<Any>>();

  return _IsolateWorker._(
    receivePort,
    received,
    exitPort,
    isolate,
    sendPort,
    pending,
  );
}

//

@neverInline
Future<void> _entryPoint(SendPort sendPort) async {
  final receivePort = ReceivePort();
  final _ = sendPort.send(receivePort.sendPort);

  // TODO(rshirkhanov): use capacity

  await for (final value in receivePort) {
    if (value case final _Input<Any> input) {
      final result = await Result.fromTask(input.task.run);
      final output = (id: input.id, result: result);
      final _ = sendPort.send(output);
    } else {
      final _ = receivePort.close();
      Isolate.exit();
    }
  }
}

//

typedef WorkerPerform = Future<T> Function<T>(Task<T> task);

//

typedef WorkerScope<R> = Future<R> Function(WorkerPerform perform);

//

extension _WorkerSafeAPI on Worker {
  static const _methodUsedOutsideOfScope =
      'do not use methods outside of "scope"';

  static Future<R> scoped<R>(
    WorkerScope<R> scope, {
    Capacity capacity = const Capacity.unlimited(),
    String? debugName,
  }) async {
    try {
      final worker = await Worker.spawn(
        capacity: capacity,
        debugName: debugName,
      );

      try {
        final reference = WeakReference(worker);

        Future<T> perform<T>(Task<T> task) {
          assert(reference.target != null, _methodUsedOutsideOfScope);
          return reference.target!.perform(task);
        }

        return await scope(perform);
      } catch (_) {
        rethrow;
      } finally {
        await worker.die();
      }
    } catch (_) {
      rethrow;
    }
  }
}

//
