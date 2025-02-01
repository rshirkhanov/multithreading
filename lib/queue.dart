//

part of 'multithreading.dart';

//

abstract interface class Queue<T> {
  const Queue();

  factory Queue.empty() = _Queue.new;

  void enqueue(T value);
  T? dequeue();
}

//

final class _Node<T> {
  _Node({
    required this.value,
    this.next,
  });

  final T value;
  _Node<T>? next;
}

//

final class _Queue<T> implements Queue<T> {
  _Queue();

  _Node<T>? _back;
  _Node<T>? _front;

  @override
  void enqueue(T value) => _enqueue(value);

  @override
  T? dequeue() => _dequeue();
}

//

extension<T> on _Queue<T> {
  void _enqueue(T value) {
    final newNode = _Node(value: value);
    if (_front == null) {
      _front = _back = newNode;
    } else {
      _back?.next = newNode;
      _back = newNode;
    }
  }

  T? _dequeue() {
    final value = _front?.value;
    _front = _front?.next;
    if (_front == null) {
      _back = null;
    }
    return value;
  }
}

//
