import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../data/models/learner_assessment.dart';
import '../data/models/progress_checkin.dart';
import '../data/models/training_plan.dart';
import '../data/training_plan_api.dart';

/// Null means "not created yet" (backend 404 `LEARNER_ASSESSMENT_NOT_FOUND`)
/// — the screen offers the create flow instead of an error state.
final assessmentProvider = FutureProvider.autoDispose
    .family<LearnerAssessment?, String>((ref, bookingId) async {
      final result = await ref
          .watch(trainingPlanApiProvider)
          .getAssessment(bookingId);
      return switch (result) {
        ApiSuccess(:final data) => data,
        ApiFailure(:final error) when error.isNotFound => null,
        ApiFailure(:final error) => throw error,
      };
    });

/// Null means the coach has not created a plan yet
/// (404 `TRAINING_PLAN_NOT_FOUND`).
final trainingPlanProvider = FutureProvider.autoDispose
    .family<TrainingPlan?, String>((ref, bookingId) async {
      final result = await ref
          .watch(trainingPlanApiProvider)
          .getPlan(bookingId);
      return switch (result) {
        ApiSuccess(:final data) => data,
        ApiFailure(:final error) when error.isNotFound => null,
        ApiFailure(:final error) => throw error,
      };
    });

/// Newest first. Check-in volume is small; one large page is enough.
final progressCheckInsProvider = FutureProvider.autoDispose
    .family<List<ProgressCheckIn>, String>((ref, bookingId) async {
      final result = await ref
          .watch(trainingPlanApiProvider)
          .checkIns(bookingId, pageSize: 50);
      return switch (result) {
        ApiSuccess(:final data) =>
          data.items..sort((a, b) {
            final ad = a.checkInDate, bd = b.checkInDate;
            if (ad == null || bd == null) return 0;
            return bd.compareTo(ad);
          }),
        ApiFailure(:final error) => throw error,
      };
    });

/// Vietnamese labels for goal/level enum strings used across the feature.
abstract final class PlanLabels {
  static const goalOptions = [
    ('muscle_gain', 'Tăng cơ'),
    ('weight_loss', 'Giảm cân'),
    ('endurance', 'Sức bền'),
    ('general_fitness', 'Thể lực chung'),
    ('skill_improvement', 'Nâng cao kỹ năng'),
  ];

  static const levelOptions = [
    ('beginner', 'Người mới'),
    ('intermediate', 'Trung cấp'),
    ('advanced', 'Nâng cao'),
  ];

  static String goal(String? raw) => switch (raw) {
    null || '' => '—',
    _ =>
      goalOptions.where((o) => o.$1 == raw).map((o) => o.$2).firstOrNull ?? raw,
  };

  static String level(String? raw) => switch (raw) {
    null || '' => '—',
    _ =>
      levelOptions.where((o) => o.$1 == raw).map((o) => o.$2).firstOrNull ??
          raw,
  };
}
