//

part of 'multithreading.dart';

//

@unsendable
final class WaitGroup {
  WaitGroup();

  static const scoped = _WaitGroupSafeAPI.scoped;

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
  void launch(Task<void> task) async {
    try {
      add();
      await task.run();
    } catch (_) {
      rethrow;
    } finally {
      done();
    }
  }
}

//

@unsendable
final class WaitGroupToken {
  const WaitGroupToken._(this.value);
  final int value;
}

//

typedef WaitGroupLaunch = WaitGroupToken Function(Task<void>);

//

typedef WaitGroupScope = Stream<WaitGroupToken> Function(
  WaitGroupLaunch launch,
);

//

extension _WaitGroupSafeAPI on WaitGroup {
  static const _tokenIsOld = '"token" must be fresh';
  static const _tokenUsedTwice = '"token" must be used only once';

  static Future<void> scoped(WaitGroupScope scope) async {
    final waitGroup = WaitGroup();

    var counter = -1;
    final tokens = scope((Task<void> task) {
      final _ = waitGroup.launch(task);
      return WaitGroupToken._(++counter);
    });

    WaitGroupToken? lastToken;
    await for (final token in tokens) {
      assert(token.value == counter, _tokenIsOld);
      assert(token != lastToken, _tokenUsedTwice);
      await waitGroup.wait();
      lastToken = token;
    }

    if (waitGroup.isNotEmpty) {
      await waitGroup.wait();
    }
  }
}

//
