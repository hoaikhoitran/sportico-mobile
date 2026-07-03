import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import 'widgets/booking_list_body.dart';

/// Bookings on the coach's packages (`GET /api/bookings/coach`).
class CoachBookingsScreen extends StatelessWidget {
  const CoachBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Học viên đăng ký')),
      body: SafeArea(
        child: BookingListBody(
          asCoach: true,
          onOpen: (booking) =>
              context.push(RouteNames.coachBookingDetailPath(booking.id)),
        ),
      ),
    );
  }
}
