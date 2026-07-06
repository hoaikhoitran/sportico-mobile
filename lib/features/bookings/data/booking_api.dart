import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/network_exceptions.dart';
import '../../../core/network/paged_result.dart';
import 'models/booking.dart';
import 'models/payos_purchase.dart';

/// docs/api/bookings.md.
class BookingApi {
  BookingApi(this._dio);

  final Dio _dio;

  static PagedResult<Booking> _paged(dynamic data) =>
      PagedResult.fromJson(data as Map<String, dynamic>, Booking.fromJson);

  static Booking _single(dynamic data) =>
      Booking.fromJson(data as Map<String, dynamic>);

  /// Activates immediately and auto-creates the training sessions from the
  /// package schedule. The production backend disables this in favor of
  /// PayOS (`MANUAL_PURCHASE_DISABLED`).
  Future<ApiResult<Booking>> purchaseManual(String trainingPackageId) {
    return safeApiCall(
      () => _dio.post(
        ApiEndpoints.purchaseManual,
        data: {'trainingPackageId': trainingPackageId},
      ),
      _single,
    );
  }

  /// Creates a `pendingPayment` booking plus a PayOS checkout link. The
  /// booking activates via webhook once the payment completes.
  Future<ApiResult<PayOsPurchase>> purchasePayOs(String trainingPackageId) {
    return safeApiCall(
      () => _dio.post(
        ApiEndpoints.purchasePayOs,
        data: {'trainingPackageId': trainingPackageId},
      ),
      (data) => PayOsPurchase.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<PagedResult<Booking>>> myBookings({
    String? status,
    int pageNumber = 1,
    int pageSize = 10,
  }) {
    return safeApiCall(
      () => _dio.get(
        ApiEndpoints.myBookings,
        queryParameters: {
          'status': ?status,
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      ),
      _paged,
    );
  }

  Future<ApiResult<Booking>> myBookingDetail(String id) {
    return safeApiCall(() => _dio.get(ApiEndpoints.booking(id)), _single);
  }

  Future<ApiResult<PagedResult<Booking>>> coachBookings({
    String? status,
    int pageNumber = 1,
    int pageSize = 10,
  }) {
    return safeApiCall(
      () => _dio.get(
        ApiEndpoints.coachBookings,
        queryParameters: {
          'status': ?status,
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      ),
      _paged,
    );
  }

  Future<ApiResult<Booking>> coachBookingDetail(String id) {
    return safeApiCall(() => _dio.get(ApiEndpoints.coachBooking(id)), _single);
  }
}

final bookingApiProvider = Provider<BookingApi>((ref) {
  return BookingApi(ref.watch(dioProvider));
});
