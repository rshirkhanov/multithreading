//

part of 'multithreading.dart';

//

typedef WaitGroupLaunch = void Function(Task<void>);

//

enum WaitGroupSignal { _ }

//

typedef WaitGroupScope = Stream<WaitGroupSignal> Function(
  WaitGroupLaunch launch,
  WaitGroupSignal signal,
);

//

@unsendable
final class WaitGroup {
  WaitGroup();

  static const scoped = WaitGroupPublicAPI._scoped;

  var _pending = 0;
  Completer<void>? _completer;
}

//

extension WaitGroupPublicAPI on WaitGroup {
  bool get isEmpty => !isNotEmpty;

  bool get isNotEmpty => _pending > 0 && _completer != null;

  //

  static const _deltaLTE0 = '"delta" must be greater than zero';

  void add([int delta = 1]) {
    assert(delta > 0, _deltaLTE0);

    if (_pending == 0) {
      _completer = Completer<void>();
    }

    _pending += delta;
  }

  //

  static const _doneBeforeAdd = '"done" must be called after "add"';

  void done() {
    assert(isNotEmpty, _doneBeforeAdd);

    if (_pending == 1) {
      _completer!.complete();
    }

    _pending -= 1;
  }

  //

  static const _waitBeforeAdd = '"wait" must be called after "add"';
  static const _waitUnawaited = '"wait" must be awaited';

  Future<void> wait() async {
    assert(isNotEmpty, _waitBeforeAdd);

    await _completer!.future;
    _completer = null;

    assert(isEmpty, _waitUnawaited);
  }

  //

  // ignore: avoid_void_async
  void launch(Future<void> Function() operation) async {
    try {
      add();
      await operation();
    } catch (_) {
      rethrow;
    } finally {
      done();
    }
  }

  //

  static Future<void> _scoped(WaitGroupScope scope) async {
    final wg = WaitGroup();
    final signals = scope(wg.launch, WaitGroupSignal._);

    await for (final _ in signals) {
      await wg.wait();
    }

    if (wg.isNotEmpty) {
      await wg.wait();
    }
  }
}

//
