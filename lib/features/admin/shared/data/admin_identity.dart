import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_result.dart';
import '../../users/data/admin_users_api.dart';
import '../../users/data/models/admin_user.dart';

/// Resolves a user id to a displayable identity.
///
/// The moderation and finance DTOs carry only `coachId` / `reporterId` UUIDs —
/// no names. A raw UUID is useless to an admin, so screens resolve the person
/// through `GET /api/admin/users/{id}` (the same id space: a coach id *is* a
/// user id on the backend).
///
/// Lookups are memoized per id, so a list of ten withdrawals from three coaches
/// costs three requests and scrolling costs none. A failed lookup resolves to
/// `null` instead of throwing: a name we could not fetch must not blank out the
/// withdrawal it belongs to — the screen falls back to a neutral placeholder.
///
/// The cache lives only as long as the admin area is on screen (see
/// [adminIdentityCacheProvider]); leaving it — including logging out — disposes
/// the provider and drops the cached personal data.
class AdminIdentityCache {
  AdminIdentityCache(this._api);

  final AdminUsersApi _api;
  final Map<String, Future<AdminUser?>> _inFlight = {};

  Future<AdminUser?> resolve(String userId) {
    if (userId.isEmpty) return Future.value(null);
    return _inFlight.putIfAbsent(userId, () => _fetch(userId));
  }

  Future<AdminUser?> _fetch(String userId) async {
    final result = await _api.detail(userId);
    switch (result) {
      case ApiSuccess(:final data):
        return data;
      case ApiFailure():
        // Do not keep a failed lookup cached — a later screen can retry.
        _inFlight.remove(userId);
        return null;
    }
  }

  void clear() => _inFlight.clear();
}

final adminIdentityCacheProvider = Provider.autoDispose<AdminIdentityCache>((
  ref,
) {
  final cache = AdminIdentityCache(ref.watch(adminUsersApiProvider));
  ref.onDispose(cache.clear);
  return cache;
});

/// Identity of one user, for cards and detail headers.
final adminUserIdentityProvider = FutureProvider.autoDispose
    .family<AdminUser?, String>((ref, userId) {
      return ref.watch(adminIdentityCacheProvider).resolve(userId);
    });
