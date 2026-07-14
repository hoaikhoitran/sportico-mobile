import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../shared/models/admin_status.dart';

/// `PostResponse` — the coach post shown in the admin moderation queue.
class AdminPost {
  const AdminPost({
    required this.id,
    required this.coachId,
    required this.sportId,
    required this.sportName,
    required this.title,
    this.description,
    required this.price,
    this.location,
    this.isOnline = false,
    this.status = AdminPostStatus.unknown,
    this.createdAt,
    this.updatedAt,
    this.imageUrls = const [],
  });

  final String id;
  final String coachId;
  final int sportId;
  final String sportName;
  final String title;
  final String? description;
  final num price;
  final String? location;
  final bool isOnline;
  final AdminPostStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> imageUrls;

  String get priceLabel => CurrencyFormatter.vnd(price);

  factory AdminPost.fromJson(Map<String, dynamic> json) {
    return AdminPost(
      id: json['id'] as String? ?? '',
      coachId: json['coachId'] as String? ?? '',
      sportId: (json['sportId'] as num?)?.toInt() ?? 0,
      sportName: json['sportName'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      price: CurrencyFormatter.parseAmount(json['price']),
      location: json['location'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      status: AdminPostStatus.parse(json['status'] as String?),
      createdAt: DateFormatter.parseUtc(json['createdAt'] as String?),
      updatedAt: DateFormatter.parseUtc(json['updatedAt'] as String?),
      imageUrls: (json['imageUrls'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .where((url) => url.isNotEmpty)
          .toList(),
    );
  }
}
