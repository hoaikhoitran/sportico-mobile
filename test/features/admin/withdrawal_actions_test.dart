import 'package:flutter_test/flutter_test.dart';
import 'package:group_prj/features/admin/shared/models/admin_status.dart';
import 'package:group_prj/features/admin/withdrawals/data/models/withdrawal_request.dart';

WithdrawalRequest _withdrawal(WithdrawalStatus status, {String? payoutId}) {
  return WithdrawalRequest(
    id: 'w-1',
    coachId: 'c-1',
    coachWalletId: 'cw-1',
    amount: 1000000,
    status: status,
    payOsPayoutId: payoutId,
  );
}

/// The action set must match `WithdrawalService` — offering an action the
/// service rejects with a 409 is the bug these tests exist to prevent.
void main() {
  group('pending', () {
    final w = _withdrawal(WithdrawalStatus.pending);

    test('can be approved or rejected', () {
      expect(WithdrawalActions.canApprove(w), isTrue);
      expect(WithdrawalActions.canReject(w), isTrue);
    });

    test('cannot be marked paid before it is approved', () {
      expect(WithdrawalActions.canMarkPaid(w), isFalse);
    });

    test('offers no payout refresh or retry yet', () {
      expect(WithdrawalActions.canRefreshPayoutStatus(w), isFalse);
      expect(WithdrawalActions.canRetryPayout(w), isFalse);
    });
  });

  group('approved', () {
    final w = _withdrawal(WithdrawalStatus.approved);

    test('can be marked paid or rejected, but not re-approved', () {
      expect(WithdrawalActions.canMarkPaid(w), isTrue);
      expect(WithdrawalActions.canReject(w), isTrue);
      expect(WithdrawalActions.canApprove(w), isFalse);
    });
  });

  group('processing', () {
    final w = _withdrawal(WithdrawalStatus.processing, payoutId: 'PO-1');

    test('is frozen: no approve, reject or manual mark-paid', () {
      // The backend blocks all three while PayOS holds the money in flight.
      expect(WithdrawalActions.canApprove(w), isFalse);
      expect(WithdrawalActions.canReject(w), isFalse);
      expect(WithdrawalActions.canMarkPaid(w), isFalse);
    });

    test('only offers a payout-status refresh', () {
      expect(WithdrawalActions.canRefreshPayoutStatus(w), isTrue);
      expect(WithdrawalActions.canRetryPayout(w), isFalse);
    });
  });

  group('failed', () {
    final w = _withdrawal(WithdrawalStatus.failed, payoutId: 'PO-1');

    test('is the only status that can be retried', () {
      expect(WithdrawalActions.canRetryPayout(w), isTrue);
      for (final status in [
        WithdrawalStatus.pending,
        WithdrawalStatus.approved,
        WithdrawalStatus.processing,
        WithdrawalStatus.paid,
        WithdrawalStatus.rejected,
        WithdrawalStatus.cancelled,
      ]) {
        expect(
          WithdrawalActions.canRetryPayout(_withdrawal(status)),
          isFalse,
          reason: '$status must not be retryable',
        );
      }
    });

    test('cannot be rejected or marked paid (funds already returned)', () {
      expect(WithdrawalActions.canReject(w), isFalse);
      expect(WithdrawalActions.canMarkPaid(w), isFalse);
    });
  });

  group('paid', () {
    final w = _withdrawal(WithdrawalStatus.paid, payoutId: 'PO-1');

    test('is terminal — no money-moving action remains', () {
      expect(WithdrawalActions.canApprove(w), isFalse);
      expect(WithdrawalActions.canReject(w), isFalse);
      expect(WithdrawalActions.canMarkPaid(w), isFalse);
      expect(WithdrawalActions.canRetryPayout(w), isFalse);
    });

    test('still exposes its receipt', () {
      expect(WithdrawalActions.canViewReceipt(w), isTrue);
    });
  });

  test('refresh needs a PayOS payout id, whatever the status', () {
    expect(
      WithdrawalActions.canRefreshPayoutStatus(
        _withdrawal(WithdrawalStatus.processing),
      ),
      isFalse,
      reason: 'without a payout id the backend throws',
    );
    expect(
      WithdrawalActions.canRefreshPayoutStatus(
        _withdrawal(WithdrawalStatus.processing, payoutId: 'PO-1'),
      ),
      isTrue,
    );
  });

  test('rejected and cancelled expose no actions at all', () {
    expect(
      WithdrawalActions.hasAny(_withdrawal(WithdrawalStatus.rejected)),
      isFalse,
    );
    expect(
      WithdrawalActions.hasAny(_withdrawal(WithdrawalStatus.cancelled)),
      isFalse,
    );
  });
}
