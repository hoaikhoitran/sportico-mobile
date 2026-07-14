/// Retry policy for providers that own a visible screen state.
///
/// Riverpod retries a failed provider up to ten times with a growing backoff.
/// For a screen that already offers "Thử lại" + pull-to-refresh that is the
/// wrong default: a 403 or a dead backend would keep the user staring at a
/// loading skeleton for half a minute while the API is hit ten more times, and
/// the error state would never show.
///
/// Pass this as `retry:` so the failure surfaces immediately and retrying stays
/// the user's decision.
Duration? noRetry(int retryCount, Object error) => null;
