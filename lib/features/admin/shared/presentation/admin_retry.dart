/// Retry policy for admin data providers.
///
/// Riverpod retries a failed provider up to ten times with a growing backoff.
/// For an admin screen that is the wrong default: a rejected request (403) or a
/// dead backend would leave the admin looking at a loading skeleton for half a
/// minute before the error state finally appears, and every failed load would
/// hammer the API ten times.
///
/// Admin screens fail fast instead and offer an explicit "Thử lại" button plus
/// pull-to-refresh, so a retry is always the admin's decision.
Duration? adminNoRetry(int retryCount, Object error) => null;
