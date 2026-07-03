import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import 'training_package_repository.dart';

typedef SportOption = ({int id, String name});

/// The backend has no public sports-list endpoint (only admin
/// `POST /api/sports`), so pickers derive known sports from the public
/// catalog. Screens must still allow manual sport-id entry as a fallback.
/// Documented backend gap — do not invent a `/api/sports` GET.
final sportOptionsProvider = FutureProvider.autoDispose<List<SportOption>>((
  ref,
) async {
  final result = await ref
      .watch(trainingPackageRepositoryProvider)
      .publicList(pageSize: 50);

  return switch (result) {
    ApiSuccess(:final data) => () {
      final seen = <int, String>{};
      for (final package in data.items) {
        if (package.sportId > 0 && package.sportName.isNotEmpty) {
          seen[package.sportId] = package.sportName;
        }
      }
      return [
        for (final entry in seen.entries) (id: entry.key, name: entry.value),
      ];
    }(),
    ApiFailure() => const <SportOption>[],
  };
});
