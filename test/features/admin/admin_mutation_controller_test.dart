import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:group_prj/core/network/api_error.dart';
import 'package:group_prj/core/network/api_result.dart';
import 'package:group_prj/features/admin/shared/presentation/admin_mutation_controller.dart';

/// The duplicate-submit guard every admin action goes through.
void main() {
  ProviderContainer container() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.listen(adminMutationControllerProvider, (_, _) {});
    return c;
  }

  test(
    'a second call on the same key is dropped while the first runs',
    () async {
      final c = container();
      final controller = c.read(adminMutationControllerProvider.notifier);
      final completer = Completer<ApiResult<String>>();
      var calls = 0;

      Future<ApiResult<String>> action() {
        calls++;
        return completer.future;
      }

      final first = controller.run('approve:pkg-1', action);
      final second = controller.run('approve:pkg-1', action);

      expect(controller.isBusy('approve:pkg-1'), isTrue);

      completer.complete(const ApiSuccess('ok'));
      await first;
      await second;

      // Only one request reached the API.
      expect(calls, 1);
      expect(controller.isBusy('approve:pkg-1'), isFalse);
    },
  );

  test('two different actions on the same entity run independently', () async {
    final c = container();
    final controller = c.read(adminMutationControllerProvider.notifier);
    var approveCalls = 0;
    var rejectCalls = 0;

    await Future.wait([
      controller.run('approve:pkg-1', () async {
        approveCalls++;
        return const ApiSuccess('ok');
      }),
      controller.run('reject:pkg-2', () async {
        rejectCalls++;
        return const ApiSuccess('ok');
      }),
    ]);

    expect(approveCalls, 1);
    expect(rejectCalls, 1);
    expect(c.read(adminMutationControllerProvider), isEmpty);
  });

  test('onSuccess runs before the busy flag clears', () async {
    final c = container();
    final controller = c.read(adminMutationControllerProvider.notifier);
    var busyDuringRefresh = false;

    await controller.run(
      'approve:pkg-1',
      () async => const ApiSuccess('ok'),
      onSuccess: (_) async {
        // A list refresh must complete while the button is still disabled.
        busyDuringRefresh = controller.isBusy('approve:pkg-1');
      },
    );

    expect(busyDuringRefresh, isTrue);
    expect(controller.isBusy('approve:pkg-1'), isFalse);
  });

  test(
    'a failure returns the error and releases the key for a retry',
    () async {
      final c = container();
      final controller = c.read(adminMutationControllerProvider.notifier);

      final error = await controller.run(
        'approve:pkg-1',
        () async => ApiFailure<String>(
          ApiError.fromJson(const {
            'code': 'INVALID_TRAINING_PACKAGE_STATUS',
            'message': 'Wrong status',
            'type': 'Conflict',
          }),
        ),
      );

      expect(error, isNotNull);
      expect(error!.code, 'INVALID_TRAINING_PACKAGE_STATUS');
      // Vietnamese copy comes from the shared error mapping.
      expect(error.userMessage, contains('Trạng thái gói tập'));
      // The admin can try again.
      expect(controller.isBusy('approve:pkg-1'), isFalse);
    },
  );
}
