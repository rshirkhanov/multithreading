//

import 'package:multithreading/multithreading.dart';

import 'wait_group.dart';

//

Future<void> main() => const RAII.of(Worker.spawn).scoped(
      (debugName: null, capacity: Capacity.unlimited),
      (it) async => it.perform(createTask(0)),
    );

//
