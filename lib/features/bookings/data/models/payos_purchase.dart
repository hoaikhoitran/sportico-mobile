/// `PurchaseTrainingPackagePayOsResponse` — the PayOS checkout handle for a
/// freshly created `pendingPayment` booking.
class PayOsPurchase {
  const PayOsPurchase({
    required this.bookingId,
    required this.orderCode,
    this.checkoutUrl,
    this.status = '',
    this.expiredAt,
  });

  final String bookingId;
  final int orderCode;

  /// PayOS hosted checkout page; opened in the external browser.
  final String? checkoutUrl;
  final String status;
  final DateTime? expiredAt;

  factory PayOsPurchase.fromJson(Map<String, dynamic> json) => PayOsPurchase(
    bookingId: json['bookingId'] as String? ?? '',
    orderCode: (json['orderCode'] as num?)?.toInt() ?? 0,
    checkoutUrl: json['checkoutUrl'] as String?,
    status: json['status'] as String? ?? '',
    expiredAt: DateTime.tryParse(json['expiredAt'] as String? ?? ''),
  );
}
