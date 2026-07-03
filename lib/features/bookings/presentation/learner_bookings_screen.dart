import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import 'widgets/booking_list_body.dart';

/// Learner's purchased packages (`GET /api/bookings/me`).
class LearnerBookingsScreen extends StatelessWidget {
  const LearnerBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đơn đăng ký của tôi')),
      body: SafeArea(
        child: BookingListBody(
          asCoach: false,
          onOpen: (booking) =>
              context.push(RouteNames.bookingDetailPath(booking.id)),
        ),
      ),
    );
  }
}
