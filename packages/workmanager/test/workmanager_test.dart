import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:workmanager/src/workmanager.dart';

import 'workmanager_test.mocks.dart';

const testTaskName = 'ios-background-task-name';

Future<bool> testCallBackDispatcher(
  String task,
  Map<String, dynamic>? inputData,
) {
  return Future.value(true);
}

Future<void> callWorkmanagerMethods(Workmanager workmanager) async {
  await workmanager.initialize(testCallBackDispatcher);
  await workmanager.cancelAll();
  await workmanager.cancelByUniqueName(testTaskName);
}

@GenerateMocks([Workmanager])
void main() {
  group('singleton pattern', () {
    test('It always returns the same workmanager instance', () {
      final workmanager = Workmanager();
      final workmanager2 = Workmanager();

      expect(workmanager, same(workmanager2));
    });
  });

  group('mocked workmanager', () {
    late MockWorkmanager mockWorkmanager;

    setUp(() {
      mockWorkmanager = MockWorkmanager();
    });

    test('cancelAll - It calls methods on the mocked class', () async {
      await callWorkmanagerMethods(mockWorkmanager);

      verify(mockWorkmanager.initialize(testCallBackDispatcher));
      verify(mockWorkmanager.cancelAll());
    });

    test('cancelByUniqueName - It calls methods on the mocked class', () async {
      await callWorkmanagerMethods(mockWorkmanager);

      verify(mockWorkmanager.initialize(testCallBackDispatcher));
      verify(mockWorkmanager.cancelByUniqueName(testTaskName));
    });
  });
}
