//

part of 'multithreading.dart';

//

@unsendable
sealed class Worker {
  const Worker();

  static const spawn = _WorkerUnsafeAPI.spawn;
  static const resource = RAII.of(spawn);

  Future<T> perform<T>(Task<T> task);
}

//

typedef _Input<T> = ({Id id, Task<T> task});

typedef _Output<T> = ({Id id, Result<T, Object> result});

//

final class _Worker implements Worker, Mortal<Worker> {
  _Worker(
    this._receivePort,
    this._received,
    this._exitPort,
    this._isolate,
    this._sendPort,
    this._pending,
  ) {
    _subscription = _received.listen(_onReceived);
  }

  final ReceivePort _receivePort;
  final Stream<_Output<Any>> _received;
  final ReceivePort _exitPort;
  final Isolate _isolate;
  final SendPort _sendPort;
  final Map<Id, Completer<Any>> _pending;

  late final StreamSubscription<_Output<Any>> _subscription;

  @override
  Worker get self => this;

  @override
  Future<T> perform<T>(Task<T> task) => _perform(task);

  @override
  Future<void> die() => _die();
}

//

extension _WorkerPrivateAPI on _Worker {
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

extension _WorkerUnsafeAPI on Worker {
  @neverInline
  static Future<Mortal<Worker>> spawn(WorkerRules rules) async {
    // TODO(rshirkhanov): assert availableWorkersCount

    final receivePort = ReceivePort();
    final received = receivePort.asBroadcastStream();

    final exitPort = ReceivePort();

    final isolate = await Isolate.spawn(
      _entryPoint,
      receivePort.sendPort,
      debugName: rules.debugName,
      onExit: exitPort.sendPort,
    );
    final sendPort = (await received.first) as SendPort;

    final pending = HashMap<Id, Completer<Any>>();

    return _Worker(
      receivePort,
      received.whereType<_Output<Any>>(),
      exitPort,
      isolate,
      sendPort,
      pending,
    );
  }

  //

  @neverInline
  static Future<void> _entryPoint(SendPort sendPort) async {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    await for (final message in receivePort) {
      if (message case final _Input<Any> input) {
        unawaited(_handle(input).then(sendPort.send));
      } else {
        receivePort.close();
        Isolate.exit();
      }
    }
  }

  //

  @neverInline
  static Future<_Output<T>> _handle<T>(_Input<T> input) async {
    final result = await Result.fromTask(input.task.run);
    return (id: input.id, result: result);
  }
}

//
