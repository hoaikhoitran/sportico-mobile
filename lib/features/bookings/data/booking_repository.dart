import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../../../core/network/paged_result.dart';
import 'booking_api.dart';
import 'models/booking.dart';

class BookingRepository {
  BookingRepository(this._api);

  final BookingApi _api;

  Future<ApiResult<Booking>> purchaseManual(String trainingPackageId) =>
      _api.purchaseManual(trainingPackageId);

  Future<ApiResult<PagedResult<Booking>>> myBookings({
    String? status,
    int pageNumber = 1,
    int pageSize = 10,
  }) => _api.myBookings(
    status: status,
    pageNumber: pageNumber,
    pageSize: pageSize,
  );

  Future<ApiResult<Booking>> myBookingDetail(String id) =>
      _api.myBookingDetail(id);

  Future<ApiResult<PagedResult<Booking>>> coachBookings({
    String? status,
    int pageNumber = 1,
    int pageSize = 10,
  }) => _api.coachBookings(
    status: status,
    pageNumber: pageNumber,
    pageSize: pageSize,
  );

  Future<ApiResult<Booking>> coachBookingDetail(String id) =>
      _api.coachBookingDetail(id);
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.watch(bookingApiProvider));
});
