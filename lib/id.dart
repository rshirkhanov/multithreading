//

part of 'multithreading.dart';

//

final class _Id {
  factory _Id() => _Id._(++_counter);

  const _Id._(this.value);

  final int value;

  static var _counter = -1;
}

//
