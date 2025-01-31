// ignore_for_file: unreachable_from_main, avoid_print, cascade_invocations, avoid_redundant_argument_values, lines_longer_than_80_chars

import 'dart:async';

import 'package:multithreading/wait_group.dart';

//

void main() async {
  print('begin');
  await test0();
  print('end');
}

//

const delay = Duration(seconds: 1);

Future<void> task(int index) => Future.delayed(delay, () => print(index));

Task<void> createTask(int index) => () => task(index + 1);

final tasks = List.generate(10, createTask);

//

Future<void> test0() async {
  final wg = WaitGroup();

  /// failed assertion
  wg.done();
}

//

Future<void> test1() async {
  final wg = WaitGroup();

  /// failed assertion
  await wg.wait();
}

//

Future<void> test2() async {
  final wg = WaitGroup();

  /// failed assertion
  wg.add(-1);

  await wg.wait();
}

//

Future<void> test3() async {
  final wg = WaitGroup();

  wg.add(1);

  /// unexpected exit
  await wg.wait();
}

//

Future<void> test4() async {
  final wg = WaitGroup();

  wg.add();
  wg.done();

  /// failed assertion
  await wg.wait();
}

//

Future<void> test5() async {
  final wg = WaitGroup();

  wg.add();
  unawaited(task(1).whenComplete(wg.done));

  /// logical error
  unawaited(wg.wait());
}

//

Future<void> test6() async {
  final wg = WaitGroup();

  wg.add();
  unawaited(task(1).whenComplete(wg.done));

  await wg.wait();

  wg.add();
  unawaited(task(2).whenComplete(wg.done));

  await wg.wait();
}

//

Future<void> test7() async {
  final wg = WaitGroup();

  wg.add();
  unawaited(task(1).whenComplete(wg.done));

  wg.add();
  unawaited(task(2).whenComplete(wg.done));

  await wg.wait();
}

//

Future<void> test8() async {
  final wg = WaitGroup();

  for (final task in tasks) {
    wg.add();
    unawaited(task().whenComplete(wg.done));
  }
  await wg.wait();
}

//

Future<void> test9() async {
  final wg = WaitGroup();

  wg.add(tasks.length);
  for (final task in tasks) {
    unawaited(task().whenComplete(wg.done));
  }
  await wg.wait();
}

//

Future<void> test10() async {
  final wg = WaitGroup();

  tasks.forEach(wg.launch);
  await wg.wait();
}

//

Future<void> test11(int step) async {
  final wg = WaitGroup();

  for (final (index, task) in tasks.indexed) {
    wg.launch(task);

    if ((index + 1) % step == 0) {
      await wg.wait();
    }
  }

  // if (wg.isNotEmpty) {
  //   await wg.wait();
  // }
}

//

Future<void> test12(int step) => WaitGroup.scoped((launch, wait) async* {
      for (final (index, task) in tasks.indexed) {
        launch(task);

        if ((index + 1) % step == 0) {
          yield wait;
        }
      }
    });

//

Future<void> test13() => WaitGroup.scoped((launch, wait) async* {
      /// impossible to call "add"
      /// impossible to call "done"
      ///
      ///   possible to call "wait" but
      /// impossible to mark "unawaited"
      ///
      /// failed assertion
      yield wait;
    });

//
