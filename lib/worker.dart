//

part of 'multithreading.dart';

//

@unsendable
abstract interface class Worker {
  const Worker._();

  static const spawn = _WorkerUnsafeAPI.spawn;
  static const scoped = _WorkerSafeAPI.scoped;

  Future<T> perform<T>(Task<T> task);
  Future<void> die();
}

//

typedef _Input<T> = ({Id id, Task<T> task});

typedef _Output<T> = ({Id id, Result<T, Object> result});

//

@unsendable
final class _Worker implements Worker {
  _Worker._(
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

typedef _InitialMessage = (SendPort, Capacity);

//

extension _WorkerUnsafeAPI on Worker {
  @neverInline
  static Future<Worker> spawn({
    required WorkerRules rules,
  }) async {
    // TODO(rshirkhanov): assert availableWorkersCount

    final receivePort = ReceivePort();
    final received = receivePort.asBroadcastStream();

    final exitPort = ReceivePort();

    final initialMessage = (receivePort.sendPort, rules.capacity);

    final isolate = await Isolate.spawn<_InitialMessage>(
      _entryPoint,
      initialMessage,
      debugName: rules.debugName,
      onExit: exitPort.sendPort,
    );
    final sendPort = (await received.first) as SendPort;

    final pending = HashMap<Id, Completer<Any>>();

    return _Worker._(
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
  static Future<void> _entryPoint(_InitialMessage initialMessage) async {
    final (sendPort, capacity) = initialMessage;

    final receivePort = ReceivePort();
    final _ = sendPort.send(receivePort.sendPort);

    final wg = WaitGroup();

    await for (final (index, value) in receivePort.enumerated) {
      if (value case final _Input<Any> input) {
        wg.add();
        unawaited(_handle(input).then(sendPort.send).whenComplete(wg.done));

        if ((index + 1) % capacity.value == 0) {
          await wg.wait();
        }
      } else {
        if (wg.isNotEmpty) {
          await wg.wait();
        }

        final _ = receivePort.close();
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

typedef WorkerPerform = Future<T> Function<T>(Task<T> task);

//

typedef WorkerScope<R> = Future<R> Function(WorkerPerform perform);

//

extension _WorkerSafeAPI on Worker {
  static Future<R> scoped<R>(
    WorkerScope<R> scope, {
    required WorkerRules rules,
  }) async {
    final worker = await Worker.spawn(rules: rules);

    try {
      return await scope(worker.perform);
    } catch (_) {
      rethrow;
    } finally {
      await worker.die();
    }
  }
}

//
