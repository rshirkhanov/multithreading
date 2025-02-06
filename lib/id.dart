// ignore_for_file: sort_constructors_first, avoid_equals_and_hash_code_on_mutable_classes, lines_longer_than_80_chars

part of 'multithreading.dart';

//

final class Id {
  factory Id() => Id._(++_counter);
  static var _counter = -1;

  const Id._(this._value);
  final int _value;

  @override
  int get hashCode => _value.hashCode;
  @override
  bool operator ==(Object? other) => other is Id && other.hashCode == hashCode;
}

//
