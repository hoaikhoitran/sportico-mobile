import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:group_prj/core/network/api_result.dart';
import 'package:group_prj/core/network/paged_result.dart';
import 'package:group_prj/features/coaches/data/coach_directory_api.dart';
import 'package:group_prj/features/coaches/data/models/public_coach.dart';
import 'package:group_prj/features/coaches/presentation/coach_list_screen.dart';

/// Serves a fixed page of coaches so the screen never touches the network.
class _FakeCoachDirectoryApi extends CoachDirectoryApi {
  _FakeCoachDirectoryApi(this.coaches) : super(Dio());

  final List<PublicCoach> coaches;

  @override
  Future<ApiResult<PagedResult<PublicCoach>>> publicCoaches({
    String? keyword,
    int? sportId,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    return ApiSuccess(
      PagedResult(
        items: coaches,
        pageNumber: 1,
        pageSize: pageSize,
        totalCount: coaches.length,
        totalPages: 1,
        hasPrevious: false,
        hasNext: false,
      ),
    );
  }
}

PublicCoach _coach(String id, String name) => PublicCoach(
  coachId: id,
  fullName: name,
  headline: 'HLV cầu lông chuyên nghiệp, kèm 1-1',
  experienceYears: 5,
  teachingCity: 'Thành phố Hồ Chí Minh',
  teachingDistrict: 'Quận 9',
  isOnlineAvailable: true,
  rating: 4.8,
  totalReviews: 12,
  sports: const [CoachSport(id: 1, name: 'Badminton')],
);

Future<void> _pumpDirectory(
  WidgetTester tester,
  List<PublicCoach> coaches,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        coachDirectoryApiProvider.overrideWithValue(
          _FakeCoachDirectoryApi(coaches),
        ),
      ],
      child: const MaterialApp(home: CoachListScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('coach directory lays cards out two per row', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pumpDirectory(tester, [
      _coach('1', 'Nguyen Thanh Trung'),
      _coach('2', 'Truong Quang Dat'),
      _coach('3', 'Bao Hung'),
      _coach('4', 'Le Minh Khoi'),
    ]);

    // Centres, not top-left corners: the name is centre-aligned, so its box
    // starts at a different x for every name length.
    final first = tester.getCenter(find.text('Nguyen Thanh Trung'));
    final second = tester.getCenter(find.text('Truong Quang Dat'));
    final third = tester.getCenter(find.text('Bao Hung'));

    // Cards 1 and 2 share a row; card 3 starts the next one, back in column 1.
    expect(second.dy, first.dy);
    expect(second.dx, greaterThan(first.dx));
    expect(third.dy, greaterThan(first.dy));
    expect(third.dx, closeTo(first.dx, 1));
  });

  testWidgets('coach card survives a large system font scale', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coachDirectoryApiProvider.overrideWithValue(
            _FakeCoachDirectoryApi([
              _coach('1', 'Nguyen Thanh Trung'),
              _coach('2', 'Truong Quang Dat'),
            ]),
          ),
        ],
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: const MaterialApp(home: CoachListScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // A tile that overflows would have raised a render exception by now.
    expect(tester.takeException(), isNull);
    expect(find.text('Nguyen Thanh Trung'), findsOneWidget);
  });
}
