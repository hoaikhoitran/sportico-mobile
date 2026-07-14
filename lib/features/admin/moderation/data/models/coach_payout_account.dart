import '../../../../../core/utils/date_formatter.dart';
import '../../../shared/models/admin_status.dart';

/// `CoachPayoutAccountResponse` — the bank account a coach is paid out to.
///
/// [bankAccountNumber] is sensitive: list surfaces render it through
/// `maskAccountNumber`, and it is never written to a log.
class CoachPayoutAccount {
  const CoachPayoutAccount({
    required this.id,
    required this.coachId,
    this.payoutMethod,
    this.bankName,
    this.bankBin,
    this.bankAccountNumber,
    this.bankAccountHolder,
    this.status = PayoutAccountStatus.unknown,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String coachId;
  final String? payoutMethod;
  final String? bankName;
  final String? bankBin;
  final String? bankAccountNumber;
  final String? bankAccountHolder;
  final PayoutAccountStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get maskedAccountNumber => maskAccountNumber(bankAccountNumber);

  factory CoachPayoutAccount.fromJson(Map<String, dynamic> json) {
    return CoachPayoutAccount(
      id: json['id'] as String? ?? '',
      coachId: json['coachId'] as String? ?? '',
      payoutMethod: json['payoutMethod'] as String?,
      bankName: json['bankName'] as String?,
      bankBin: json['bankBin'] as String?,
      bankAccountNumber: json['bankAccountNumber'] as String?,
      bankAccountHolder: json['bankAccountHolder'] as String?,
      status: PayoutAccountStatus.parse(json['status'] as String?),
      createdAt: DateFormatter.parseUtc(json['createdAt'] as String?),
      updatedAt: DateFormatter.parseUtc(json['updatedAt'] as String?),
    );
  }

  /// Never let an account number reach a log line or crash report.
  @override
  String toString() => 'CoachPayoutAccount($id, ${status.name})';
}
