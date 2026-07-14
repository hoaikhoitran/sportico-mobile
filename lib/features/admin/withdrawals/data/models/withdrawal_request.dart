import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../shared/models/admin_status.dart';

/// `WithdrawalRequestResponse` — a coach's request to cash out wallet funds.
class WithdrawalRequest {
  const WithdrawalRequest({
    required this.id,
    required this.coachId,
    required this.coachWalletId,
    this.coachPayoutAccountId,
    required this.amount,
    this.status = WithdrawalStatus.unknown,
    this.adminNote,
    this.reviewedByUserId,
    this.reviewedAt,
    this.payOsPayoutId,
    this.payOsReferenceId,
    this.payOsPayoutStatus,
    this.failureReason,
    this.processingAt,
    this.paidAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String coachId;
  final String coachWalletId;
  final String? coachPayoutAccountId;
  final num amount;
  final WithdrawalStatus status;
  final String? adminNote;
  final String? reviewedByUserId;
  final DateTime? reviewedAt;

  /// PayOS payout identifiers — present once a payout has been initiated.
  final String? payOsPayoutId;
  final String? payOsReferenceId;
  final String? payOsPayoutStatus;
  final String? failureReason;

  final DateTime? processingAt;
  final DateTime? paidAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get amountLabel => CurrencyFormatter.vnd(amount);

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequest(
      id: json['id'] as String? ?? '',
      coachId: json['coachId'] as String? ?? '',
      coachWalletId: json['coachWalletId'] as String? ?? '',
      coachPayoutAccountId: json['coachPayoutAccountId'] as String?,
      amount: CurrencyFormatter.parseAmount(json['amount']),
      status: WithdrawalStatus.parse(json['status'] as String?),
      adminNote: json['adminNote'] as String?,
      reviewedByUserId: json['reviewedByUserId'] as String?,
      reviewedAt: DateFormatter.parseUtc(json['reviewedAt'] as String?),
      payOsPayoutId: json['payOsPayoutId'] as String?,
      payOsReferenceId: json['payOsReferenceId'] as String?,
      payOsPayoutStatus: json['payOsPayoutStatus'] as String?,
      failureReason: json['failureReason'] as String?,
      processingAt: DateFormatter.parseUtc(json['processingAt'] as String?),
      paidAt: DateFormatter.parseUtc(json['paidAt'] as String?),
      createdAt: DateFormatter.parseUtc(json['createdAt'] as String?),
      updatedAt: DateFormatter.parseUtc(json['updatedAt'] as String?),
    );
  }

  /// Keep payout identifiers out of logs and crash reports.
  @override
  String toString() => 'WithdrawalRequest($id, ${status.name})';
}

/// Which admin actions the backend will actually accept for a withdrawal.
///
/// Mirrors `WithdrawalService` exactly — the UI must not offer an action that
/// the service is going to reject with a 409:
///
/// * **approve** — `pending` only. (`approved` is also accepted by the service,
///   but re-approving is either a no-op or a second payout attempt, so it is
///   not offered.)
/// * **reject / mark-paid** — blocked while `processing` or `paid`. Both move
///   the reserved funds out of `PendingBalance`, which only holds them while the
///   request is `pending` or `approved`.
/// * **refresh payout status** — needs a PayOS payout id; without one the
///   service throws.
/// * **retry payout** — `failed` only.
/// * **receipt** — always available.
abstract final class WithdrawalActions {
  static bool canApprove(WithdrawalRequest w) =>
      w.status == WithdrawalStatus.pending;

  static bool canReject(WithdrawalRequest w) =>
      w.status == WithdrawalStatus.pending ||
      w.status == WithdrawalStatus.approved;

  static bool canMarkPaid(WithdrawalRequest w) =>
      w.status == WithdrawalStatus.approved;

  static bool canRefreshPayoutStatus(WithdrawalRequest w) =>
      w.payOsPayoutId != null && w.payOsPayoutId!.isNotEmpty;

  static bool canRetryPayout(WithdrawalRequest w) =>
      w.status == WithdrawalStatus.failed;

  static bool canViewReceipt(WithdrawalRequest w) => true;

  static bool hasAny(WithdrawalRequest w) =>
      canApprove(w) ||
      canReject(w) ||
      canMarkPaid(w) ||
      canRefreshPayoutStatus(w) ||
      canRetryPayout(w);
}

/// `WithdrawalReceiptResponse` — the payout record for a withdrawal.
///
/// The backend already masks the account number ([maskedAccountNumber]); the
/// client never receives the full number here.
class WithdrawalReceipt {
  const WithdrawalReceipt({
    this.receiptNumber,
    required this.withdrawalRequestId,
    required this.coachId,
    this.coachName,
    this.coachEmail,
    required this.amount,
    this.currency,
    this.status = WithdrawalStatus.unknown,
    this.payOsPayoutId,
    this.payOsReferenceId,
    this.payOsPayoutStatus,
    this.failureReason,
    this.createdAt,
    this.processingAt,
    this.paidAt,
    this.bankName,
    this.bankBin,
    this.maskedAccountNumber,
    this.accountHolderName,
    this.adminNote,
    this.note,
  });

  final String? receiptNumber;
  final String withdrawalRequestId;
  final String coachId;
  final String? coachName;
  final String? coachEmail;
  final num amount;
  final String? currency;
  final WithdrawalStatus status;
  final String? payOsPayoutId;
  final String? payOsReferenceId;
  final String? payOsPayoutStatus;
  final String? failureReason;
  final DateTime? createdAt;
  final DateTime? processingAt;
  final DateTime? paidAt;
  final String? bankName;
  final String? bankBin;
  final String? maskedAccountNumber;
  final String? accountHolderName;
  final String? adminNote;
  final String? note;

  String get amountLabel => CurrencyFormatter.vnd(amount);

  factory WithdrawalReceipt.fromJson(Map<String, dynamic> json) {
    return WithdrawalReceipt(
      receiptNumber: json['receiptNumber'] as String?,
      withdrawalRequestId: json['withdrawalRequestId'] as String? ?? '',
      coachId: json['coachId'] as String? ?? '',
      coachName: json['coachName'] as String?,
      coachEmail: json['coachEmail'] as String?,
      amount: CurrencyFormatter.parseAmount(json['amount']),
      currency: json['currency'] as String?,
      status: WithdrawalStatus.parse(json['status'] as String?),
      payOsPayoutId: json['payOsPayoutId'] as String?,
      payOsReferenceId: json['payOsReferenceId'] as String?,
      payOsPayoutStatus: json['payOsPayoutStatus'] as String?,
      failureReason: json['failureReason'] as String?,
      createdAt: DateFormatter.parseUtc(json['createdAt'] as String?),
      processingAt: DateFormatter.parseUtc(json['processingAt'] as String?),
      paidAt: DateFormatter.parseUtc(json['paidAt'] as String?),
      bankName: json['bankName'] as String?,
      bankBin: json['bankBin'] as String?,
      maskedAccountNumber: json['maskedAccountNumber'] as String?,
      accountHolderName: json['accountHolderName'] as String?,
      adminNote: json['adminNote'] as String?,
      note: json['note'] as String?,
    );
  }

  @override
  String toString() => 'WithdrawalReceipt($withdrawalRequestId)';
}
