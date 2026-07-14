import 'package:flutter_test/flutter_test.dart';
import 'package:group_prj/core/network/api_result.dart';
import 'package:group_prj/core/network/paged_result.dart';
import 'package:group_prj/features/admin/dashboard/data/models/admin_dashboard.dart';
import 'package:group_prj/features/admin/moderation/data/models/admin_post.dart';
import 'package:group_prj/features/admin/moderation/data/models/coach_payout_account.dart';
import 'package:group_prj/features/admin/moderation/data/models/review_report.dart';
import 'package:group_prj/features/admin/settings/data/models/platform_commission.dart';
import 'package:group_prj/features/admin/shared/models/admin_status.dart';
import 'package:group_prj/features/admin/users/data/models/admin_user.dart';
import 'package:group_prj/features/admin/withdrawals/data/models/withdrawal_request.dart';

void main() {
  group('AdminUser', () {
    test('parses the full AdminUserResponse envelope', () {
      final result = ApiResult.fromEnvelope<AdminUser>({
        'isSuccess': true,
        'data': {
          'id': 'u-1',
          'email': 'coach@sportico.vn',
          'fullName': 'Trần Hoài Khôi',
          'phone': '0901234567',
          'avatarUrl': 'https://cdn.sportico.vn/a.png',
          'dateOfBirth': '1995-04-02T00:00:00Z',
          'status': 'active',
          'roles': ['learner', 'coach'],
          'createdAt': '2026-01-05T03:00:00Z',
          'updatedAt': '2026-02-01T03:00:00Z',
          'coachProfile': {
            'headline': 'HLV cầu lông',
            'experienceYears': 5,
            'rating': 4.8,
            'totalReviews': 12,
          },
          'learnerProfile': {'goal': 'Giảm cân'},
        },
        'error': null,
      }, (data) => AdminUser.fromJson(data as Map<String, dynamic>));

      final user = result.requireData;
      expect(user.id, 'u-1');
      expect(user.status, AdminUserStatus.active);
      expect(user.roles, ['learner', 'coach']);
      expect(user.isCoach, isTrue);
      expect(user.isAdmin, isFalse);
      expect(user.coachProfile?.experienceYears, 5);
      expect(user.learnerProfile?.goal, 'Giảm cân');
      expect(user.dateOfBirth, isNotNull);
    });

    test('tolerates every nullable field being absent', () {
      final user = AdminUser.fromJson({'id': 'u-2', 'email': 'a@b.vn'});

      expect(user.fullName, '');
      // With no name, the email is what an admin sees.
      expect(user.displayName, 'a@b.vn');
      expect(user.phone, isNull);
      expect(user.dateOfBirth, isNull);
      expect(user.roles, isEmpty);
      expect(user.coachProfile, isNull);
      expect(user.status, AdminUserStatus.unknown);
    });

    test('an unknown status string does not crash and falls back', () {
      final user = AdminUser.fromJson({'id': 'u-3', 'status': 'shadow_banned'});
      expect(user.status, AdminUserStatus.unknown);
      expect(user.status.label, 'Không xác định');
    });

    test('create request sends the backend field names and drops blanks', () {
      final json = const AdminCreateUserRequest(
        email: 'new@sportico.vn',
        fullName: 'Người Mới',
        password: 'secret123',
        status: AdminUserStatus.active,
        roles: ['learner'],
        phone: '   ',
        avatarUrl: '',
      ).toJson();

      expect(json['email'], 'new@sportico.vn');
      expect(json['status'], 'active');
      expect(json['roles'], ['learner']);
      // Blank optional fields are omitted, not sent as "".
      expect(json.containsKey('phone'), isFalse);
      expect(json.containsKey('avatarUrl'), isFalse);
      expect(json.containsKey('dateOfBirth'), isFalse);
    });

    test('update request never carries email or password', () {
      final json = const AdminUpdateUserRequest(
        fullName: 'Tên Mới',
        status: AdminUserStatus.banned,
        roles: ['coach'],
      ).toJson();

      expect(json.containsKey('email'), isFalse);
      expect(json.containsKey('password'), isFalse);
      expect(json['status'], 'banned');
    });
  });

  group('PagedResult of admin items', () {
    test('parses paging metadata and items', () {
      final result = ApiResult.fromEnvelope<PagedResult<AdminUser>>(
        {
          'isSuccess': true,
          'data': {
            'items': [
              {'id': 'u-1', 'email': 'a@b.vn', 'status': 'active'},
              {'id': 'u-2', 'email': 'c@d.vn', 'status': 'banned'},
            ],
            'pageNumber': 2,
            'pageSize': 10,
            'totalCount': 12,
            'totalPages': 2,
            'hasPrevious': true,
            'hasNext': false,
          },
        },
        (data) => PagedResult.fromJson(
          data as Map<String, dynamic>,
          AdminUser.fromJson,
        ),
      );

      final page = result.requireData;
      expect(page.items, hasLength(2));
      expect(page.items.last.status, AdminUserStatus.banned);
      expect(page.pageNumber, 2);
      expect(page.totalCount, 12);
      expect(page.hasNext, isFalse);
    });

    test('a 200 body with isSuccess:false is a failure, not empty data', () {
      final result = ApiResult.fromEnvelope<PagedResult<AdminUser>>(
        {
          'isSuccess': false,
          'data': null,
          'error': {
            'code': 'COMMON_FORBIDDEN',
            'message': 'Forbidden',
            'type': 'Forbidden',
          },
        },
        (data) => PagedResult.fromJson(
          data as Map<String, dynamic>,
          AdminUser.fromJson,
        ),
      );

      expect(result.isSuccess, isFalse);
      expect(result.requireError.isForbidden, isTrue);
      expect(result.requireError.userMessage, contains('không thể'));
    });
  });

  group('AdminDashboard', () {
    test('parses every KPI the backend returns', () {
      final dashboard = AdminDashboard.fromJson({
        'totalUsers': 120,
        'totalLearners': 90,
        'totalCoaches': 30,
        'publishedPackages': 45,
        'totalBookings': 200,
        'activeBookings': 20,
        'completedBookings': 170,
        'cancelledBookings': 10,
        'grossRevenue': 150000000,
        'platformFeeRevenue': 22500000,
        'coachPayable': 127500000,
        'totalWithdrawnPaid': 100000000,
        'pendingWithdrawals': 3,
        'processingWithdrawals': 1,
        'paidWithdrawals': 25,
        'failedWithdrawals': 2,
      });

      expect(dashboard.totalUsers, 120);
      expect(dashboard.pendingWithdrawals, 3);
      expect(dashboard.grossRevenueLabel, contains('₫'));
      expect(dashboard.platformFeeRevenueLabel, contains('22.500.000'));
    });

    test('missing counters read as zero instead of throwing', () {
      final dashboard = AdminDashboard.fromJson({});
      expect(dashboard.totalUsers, 0);
      expect(dashboard.grossRevenue, 0);
    });

    test('filter maps to the FromDate/ToDate query the backend expects', () {
      expect(DashboardFilter.allTime.toQuery(), isEmpty);

      final query = DashboardFilter.range(
        DateTime.utc(2026, 1, 1),
        DateTime.utc(2026, 1, 31),
        'Tháng 1',
      ).toQuery();

      expect(query.keys, containsAll(['FromDate', 'ToDate']));
      expect(query['FromDate'], startsWith('2026-01-01'));
    });
  });

  group('Moderation models', () {
    test('AdminPost keeps image urls and drops empty ones', () {
      final post = AdminPost.fromJson({
        'id': 'p-1',
        'coachId': 'c-1',
        'title': 'Lớp cầu lông buổi tối',
        'price': 350000,
        'status': 'pending',
        'imageUrls': ['https://cdn/1.png', '', 'https://cdn/2.png'],
        'createdAt': '2026-03-01T10:00:00Z',
      });

      expect(post.status, AdminPostStatus.pending);
      expect(post.status.isModeratable, isTrue);
      expect(post.imageUrls, ['https://cdn/1.png', 'https://cdn/2.png']);
      expect(post.priceLabel, contains('350.000'));
    });

    test('a draft post is moderatable, a published one is not', () {
      expect(AdminPostStatus.parse('draft').isModeratable, isTrue);
      expect(AdminPostStatus.parse('published').isModeratable, isFalse);
    });

    test('ReviewReport parses the review snapshot with null fields', () {
      final report = ReviewReport.fromJson({
        'id': 'r-1',
        'reporterId': 'u-9',
        'reviewId': 'rv-1',
        'reason': 'Ngôn từ xúc phạm',
        'status': 'pending',
        'createdAt': '2026-03-02T08:00:00Z',
        'reviewRating': 1,
        'reviewComment': 'Rất tệ',
        'reviewStatus': 'active',
      });

      expect(report.status, ReviewReportStatus.pending);
      expect(report.status.isResolvable, isTrue);
      expect(report.reviewRating, 1);
      expect(report.handledAt, isNull);
      expect(report.resolutionNote, isNull);
    });

    test('a resolved report can no longer be resolved', () {
      expect(ReviewReportStatus.parse('resolved').isResolvable, isFalse);
      expect(ReviewReportStatus.parse('rejected').isResolvable, isFalse);
    });

    test('resolve request carries exactly the three backend fields', () {
      final json = const ResolveReviewReportRequest(
        isValid: true,
        hideOrDeleteReview: true,
        resolutionNote: '  vi phạm  ',
      ).toJson();

      expect(json, {
        'isValid': true,
        'hideOrDeleteReview': true,
        'resolutionNote': 'vi phạm',
      });
    });

    test('an empty resolution note is omitted', () {
      final json = const ResolveReviewReportRequest(
        isValid: false,
        hideOrDeleteReview: false,
        resolutionNote: '   ',
      ).toJson();

      expect(json.containsKey('resolutionNote'), isFalse);
    });

    test('payout account masks its number and hides it from toString', () {
      final account = CoachPayoutAccount.fromJson({
        'id': 'pa-1',
        'coachId': 'c-1',
        'bankName': 'Vietcombank',
        'bankAccountNumber': '1234567890',
        'bankAccountHolder': 'TRAN HOAI KHOI',
        'status': 'pending',
      });

      expect(account.status, PayoutAccountStatus.pending);
      expect(account.maskedAccountNumber, '•••• 7890');
      // The full number must never leak through a log/crash line.
      expect(account.toString(), isNot(contains('1234567890')));
    });

    test('masking handles short and missing numbers', () {
      expect(maskAccountNumber(null), '—');
      expect(maskAccountNumber(''), '—');
      expect(maskAccountNumber('12'), '••••12');
    });
  });

  group('Withdrawals', () {
    test('parses the request with its PayOS fields', () {
      final withdrawal = WithdrawalRequest.fromJson({
        'id': 'w-1',
        'coachId': 'c-1',
        'coachWalletId': 'cw-1',
        'amount': 2500000,
        'status': 'processing',
        'payOsPayoutId': 'PO-123',
        'payOsPayoutStatus': 'PROCESSING',
        'processingAt': '2026-03-03T09:00:00Z',
        'createdAt': '2026-03-02T09:00:00Z',
      });

      expect(withdrawal.status, WithdrawalStatus.processing);
      expect(withdrawal.amountLabel, contains('2.500.000'));
      expect(withdrawal.paidAt, isNull);
      expect(withdrawal.toString(), isNot(contains('PO-123')));
    });

    test('an unknown withdrawal status is never sent back as a filter', () {
      final status = WithdrawalStatus.parse('escheated');
      expect(status, WithdrawalStatus.unknown);
      expect(status.wireValue, isNull);
      expect(WithdrawalStatus.pending.wireValue, 'pending');
    });

    test('receipt parses and keeps the backend-masked account number', () {
      final receipt = WithdrawalReceipt.fromJson({
        'receiptNumber': 'RC-000123',
        'withdrawalRequestId': 'w-1',
        'coachId': 'c-1',
        'coachName': 'Trần Hoài Khôi',
        'coachEmail': 'khoi@sportico.vn',
        'amount': 2500000,
        'currency': 'VND',
        'status': 'paid',
        'payOsPayoutId': 'PO-123',
        'payOsReferenceId': 'REF-9',
        'bankName': 'Vietcombank',
        'maskedAccountNumber': '****7890',
        'accountHolderName': 'TRAN HOAI KHOI',
        'paidAt': '2026-03-04T09:00:00Z',
      });

      expect(receipt.receiptNumber, 'RC-000123');
      expect(receipt.status, WithdrawalStatus.paid);
      expect(receipt.amountLabel, contains('2.500.000'));
      expect(receipt.maskedAccountNumber, '****7890');
      expect(receipt.failureReason, isNull);
    });

    test('receipt tolerates a payout that never completed', () {
      final receipt = WithdrawalReceipt.fromJson({
        'withdrawalRequestId': 'w-2',
        'coachId': 'c-2',
        'amount': 500000,
        'status': 'failed',
        'failureReason': 'Số tài khoản không hợp lệ',
      });

      expect(receipt.paidAt, isNull);
      expect(receipt.receiptNumber, isNull);
      expect(receipt.status, WithdrawalStatus.failed);
      expect(receipt.failureReason, isNotNull);
    });
  });

  group('PlatformCommission', () {
    test('reads commissionPercent as a percent, not a fraction', () {
      final commission = PlatformCommission.fromJson({
        'commissionPercent': 15,
        'updatedAt': '2026-03-01T10:00:00Z',
        'updatedByUserId': 'admin-1',
      });

      expect(commission.commissionPercent, 15);
      expect(commission.percentLabel, '15%');
      expect(commission.updatedAt, isNotNull);
    });

    test('formats a fractional percent in Vietnamese style', () {
      final commission = PlatformCommission.fromJson({
        'commissionPercent': 12.5,
      });
      expect(commission.percentLabel, '12,5%');
    });

    test('tolerates a missing updatedByUserId', () {
      final commission = PlatformCommission.fromJson({
        'commissionPercent': 0,
        'updatedByUserId': null,
      });
      expect(commission.updatedByUserId, isNull);
      expect(commission.percentLabel, '0%');
    });
  });
}
