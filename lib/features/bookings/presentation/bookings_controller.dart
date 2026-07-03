import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_config.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/paged_result.dart';
import '../../../core/utils/paged_list_state.dart';
import '../../sessions/data/models/training_session.dart';
import '../../sessions/data/training_session_repository.dart';
import '../data/booking_repository.dart';
import '../data/models/booking.dart';

/// Shared list logic for learner (`/bookings/me`) and coach
/// (`/bookings/coach`) booking lists, filterable by status.
class BookingsController extends AsyncNotifier<PagedListState<Booking>> {
  BookingsController(this.asCoach);

  /// Family argument: coach view or learner view.
  final bool asCoach;

  BookingStatus? _statusFilter;

  BookingStatus? get statusFilter => _statusFilter;

  @override
  Future<PagedListState<Booking>> build() => _fetchFirstPage();

  String? get _statusParam => switch (_statusFilter) {
    null || BookingStatus.unknown => null,
    BookingStatus.pendingPayment => 'pending_payment',
    final s => s.name,
  };

  Future<PagedListState<Booking>> _fetchFirstPage() =>
      _fetchPage(pageNumber: 1).then(PagedListState.fromFirstPage);

  Future<PagedResult<Booking>> _fetchPage({required int pageNumber}) async {
    final repository = ref.read(bookingRepositoryProvider);
    final result = asCoach
        ? await repository.coachBookings(
            status: _statusParam,
            pageNumber: pageNumber,
            pageSize: AppConfig.defaultPageSize,
          )
        : await repository.myBookings(
            status: _statusParam,
            pageNumber: pageNumber,
            pageSize: AppConfig.defaultPageSize,
          );
    return switch (result) {
      ApiSuccess(:final data) => data,
      ApiFailure(:final error) => throw error,
    };
  }

  Future<void> setFilter(BookingStatus? status) async {
    _statusFilter = status;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasNext || current.loadingMore) return;

    state = AsyncData(current.withLoadingMore(true));
    try {
      final page = await _fetchPage(pageNumber: current.pageNumber + 1);
      state = AsyncData(current.appendPage(page));
    } on Object {
      // Keep the loaded items; scrolling again retries.
      state = AsyncData(current.withLoadingMore(false));
    }
  }
}

/// `arg == true` → coach view, otherwise learner view.
final bookingsControllerProvider =
    AsyncNotifierProvider.family<
      BookingsController,
      PagedListState<Booking>,
      bool
    >(BookingsController.new);

typedef BookingDetailArgs = ({String id, bool asCoach});

final bookingDetailProvider = FutureProvider.autoDispose
    .family<Booking, BookingDetailArgs>((ref, args) async {
      final repository = ref.watch(bookingRepositoryProvider);
      final result = args.asCoach
          ? await repository.coachBookingDetail(args.id)
          : await repository.myBookingDetail(args.id);
      return switch (result) {
        ApiSuccess(:final data) => data,
        ApiFailure(:final error) => throw error,
      };
    });

/// All sessions of a booking, sorted by start time.
final bookingSessionsProvider = FutureProvider.autoDispose
    .family<List<TrainingSession>, String>((ref, bookingId) async {
      final result = await ref
          .watch(trainingSessionRepositoryProvider)
          .byBooking(bookingId);
      return switch (result) {
        ApiSuccess(:final data) =>
          data.items..sort((a, b) {
            final at = a.startTime, bt = b.startTime;
            if (at == null || bt == null) return 0;
            return at.compareTo(bt);
          }),
        ApiFailure(:final error) => throw error,
      };
    });
