//

part of 'multithreading.dart';

//

@unsendable
abstract interface class Worker {
  const Worker._();

  static const spawn = _spawn;

  Future<T> perform<T>(Task<T> task);
  Future<void> die();
}

//

typedef _Input<T> = ({_Id id, Task<T> task});

typedef _Output<T> = ({_Id id, Result<T, Object> result});

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
    _subscription = _received
        .where((it) => it is _Output)
        .cast<_Output>()
        .listen(_onReceived);
  }

  final ReceivePort _receivePort;
  final Stream _received;
  final ReceivePort _exitPort;
  final Isolate _isolate;
  final SendPort _sendPort;
  final HashMap<_Id, Completer> _pending;

  late final StreamSubscription<_Output> _subscription;

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
    final id = _Id();
    final completer = Completer<T>();
    _pending[id] = completer;
    final _Input input = (id: id, task: task);
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
Future<_IsolateWorker> _spawn({
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

  final pending = HashMap<_Id, Completer>();

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

  await for (final value in receivePort) {
    // TODO: TEST
    if (value case final _Input input) {
      // final result = await Result.fromAsync(input.task.run);
      // final _Output output = (id: input.id, result: result);
      // final _ = sendPort.send(output);

      final _ = Result.fromAsync(input.task.run)
          .then((result) => (id: input.id, result: result))
          .then(sendPort.send);
    } else {
      final _ = receivePort.close();
      Isolate.exit();
    }
  }
}

//

Future<void> loop<T>(
  int buffer,
  Stream<Task<T>> tasks,
  void Function<R>(R result) send,
) async {
  assert(buffer > 0);

  final wg = WaitGroup();

  var counter = 0;
  await for (final task in tasks) {
    counter += 1;

    wg.launch(task);

    if (counter == buffer) {
      counter = 0;
      await wg.wait();
    }
  }

  if (counter != 0) {
    await wg.wait();
  }
}

//
