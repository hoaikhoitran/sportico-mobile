import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/retry_policy.dart';
import '../../coaches/data/coach_directory_api.dart';
import 'training_package_repository.dart';

typedef SportOption = ({int id, String name});

/// The backend has no sports-list endpoint (only admin `POST /api/Sports`), so
/// pickers derive the catalogue from the public data that *does* carry sports.
/// Documented backend gap — do not invent a `/api/sports` GET.
///
/// Two sources are merged, because either one alone can legitimately be empty:
/// published packages (empty on a fresh platform) and public coach profiles
/// (empty before the first coach registers). A sport is known if it appears in
/// either.
///
/// A failure is **thrown**, not swallowed into an empty list: "no sport exists
/// yet" and "the request failed" must not look the same, otherwise the picker
/// tells the user to type a sport id by hand when the real problem is that the
/// backend is unreachable. Screens still keep manual id entry as a fallback for
/// a genuinely empty catalogue.
final sportOptionsProvider = FutureProvider.autoDispose<List<SportOption>>((
  ref,
) async {
  final packagesResult = await ref
      .watch(trainingPackageRepositoryProvider)
      .publicList(pageSize: 50);
  final coachesResult = await ref
      .watch(coachDirectoryApiProvider)
      .publicCoaches(pageSize: 50);

  final seen = <int, String>{};
  ApiError? failure;

  switch (packagesResult) {
    case ApiSuccess(:final data):
      for (final package in data.items) {
        if (package.sportId > 0 && package.sportName.isNotEmpty) {
          seen[package.sportId] = package.sportName;
        }
      }
    case ApiFailure(:final error):
      failure = error;
  }

  switch (coachesResult) {
    case ApiSuccess(:final data):
      for (final coach in data.items) {
        for (final sport in coach.sports) {
          if (sport.id > 0 && sport.name.isNotEmpty) {
            seen[sport.id] = sport.name;
          }
        }
      }
    case ApiFailure(:final error):
      failure = error;
  }

  // Nothing came back *and* something went wrong → surface the error so the
  // screen can offer a retry instead of a misleading "no catalogue" note.
  if (seen.isEmpty && failure != null) throw failure;

  final options = [
    for (final entry in seen.entries) (id: entry.key, name: entry.value),
  ]..sort((a, b) => a.id.compareTo(b.id));
  return options;
}, retry: noRetry);
