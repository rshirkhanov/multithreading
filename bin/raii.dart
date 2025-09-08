//

import 'package:multithreading/multithreading.dart';

//

import 'wait_group.dart';

//

Future<void> main() => Worker.resource.scoped(
      (debugName: null, capacity: Capacity.unlimited),
      (it) {
        it
          ..perform(createTask(0))
          ..perform(createTask(1))
          ..perform(createTask(2))
          ..perform(createTask(3));
      },
    );

//
