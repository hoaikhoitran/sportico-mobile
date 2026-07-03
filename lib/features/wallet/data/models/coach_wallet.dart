import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';

/// `CoachWalletResponse` — balances only; withdrawals are out of phase-1
/// scope on mobile.
class CoachWallet {
  const CoachWallet({
    required this.availableBalance,
    required this.pendingBalance,
    required this.totalEarned,
    required this.totalWithdrawn,
  });

  final num availableBalance;
  final num pendingBalance;
  final num totalEarned;
  final num totalWithdrawn;

  factory CoachWallet.fromJson(Map<String, dynamic> json) {
    return CoachWallet(
      availableBalance: CurrencyFormatter.parseAmount(json['availableBalance']),
      pendingBalance: CurrencyFormatter.parseAmount(json['pendingBalance']),
      totalEarned: CurrencyFormatter.parseAmount(json['totalEarned']),
      totalWithdrawn: CurrencyFormatter.parseAmount(json['totalWithdrawn']),
    );
  }
}

/// `CoachWalletTransactionResponse` ledger row.
class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.direction,
    required this.amount,
    this.note,
    this.createdAt,
  });

  final String id;

  /// e.g. `session_release`, `withdrawal`.
  final String type;

  /// `credit` | `debit`.
  final String direction;
  final num amount;
  final String? note;
  final DateTime? createdAt;

  bool get isCredit => direction == 'credit';

  String get typeLabel => switch (type) {
    'session_release' => 'Thu nhập buổi tập',
    'withdrawal' => 'Rút tiền',
    _ => type,
  };

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      direction: json['direction'] as String? ?? '',
      amount: CurrencyFormatter.parseAmount(json['amount']),
      note: json['note'] as String?,
      createdAt: DateFormatter.parseUtc(json['createdAt'] as String?),
    );
  }
}
