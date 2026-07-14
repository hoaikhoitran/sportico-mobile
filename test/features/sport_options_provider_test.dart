import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:group_prj/core/network/api_error.dart';
import 'package:group_prj/core/network/api_result.dart';
import 'package:group_prj/core/network/paged_result.dart';
import 'package:group_prj/features/coaches/data/coach_directory_api.dart';
import 'package:group_prj/features/coaches/data/models/public_coach.dart';
import 'package:group_prj/features/training_packages/data/models/training_package.dart';
import 'package:group_prj/features/training_packages/data/sport_options_provider.dart';
import 'package:group_prj/features/training_packages/data/training_package_api.dart';

PagedResult<T> _page<T>(List<T> items) => PagedResult(
  items: items,
  pageNumber: 1,
  pageSize: 50,
  totalCount: items.length,
  totalPages: 1,
  hasPrevious: false,
  hasNext: false,
);

const _error = ApiError(
  code: 'NETWORK_ERROR',
  message: 'Không thể kết nối tới máy chủ. Kiểm tra mạng của bạn.',
  type: 'Network',
);

TrainingPackage _package(int sportId, String sportName) => TrainingPackage(
  id: 'p-$sportId',
  coachId: 'c-1',
  sportId: sportId,
  sportName: sportName,
  title: 'Gói tập',
  price: 1000000,
  sessionCount: 4,
  durationDays: 30,
);

PublicCoach _coach(List<CoachSport> sports) =>
    PublicCoach(coachId: 'c-1', fullName: 'HLV', sports: sports);

class _FakePackageApi extends TrainingPackageApi {
  _FakePackageApi(this.result) : super(Dio());

  final ApiResult<PagedResult<TrainingPackage>> result;

  @override
  Future<ApiResult<PagedResult<TrainingPackage>>> publicList({
    String? keyword,
    int? sportId,
    int pageNumber = 1,
    int pageSize = 10,
  }) async => result;
}

class _FakeCoachApi extends CoachDirectoryApi {
  _FakeCoachApi(this.result) : super(Dio());

  final ApiResult<PagedResult<PublicCoach>> result;

  @override
  Future<ApiResult<PagedResult<PublicCoach>>> publicCoaches({
    String? keyword,
    int? sportId,
    int pageNumber = 1,
    int pageSize = 10,
  }) async => result;
}

ProviderContainer _container({
  required ApiResult<PagedResult<TrainingPackage>> packages,
  required ApiResult<PagedResult<PublicCoach>> coaches,
}) {
  final container = ProviderContainer(
    overrides: [
      trainingPackageApiProvider.overrideWithValue(_FakePackageApi(packages)),
      coachDirectoryApiProvider.overrideWithValue(_FakeCoachApi(coaches)),
    ],
  );
  addTearDown(container.dispose);
  container.listen(sportOptionsProvider, (_, _) {}, onError: (_, _) {});
  return container;
}

/// The backend exposes no sports-list endpoint, so the picker derives the
/// catalogue from published packages *and* public coach profiles.
void main() {
  test('merges sports from packages and coaches, de-duplicated', () async {
    final container = _container(
      packages: ApiSuccess(_page([_package(1, 'Badminton')])),
      coaches: ApiSuccess(
        _page([
          _coach(const [
            CoachSport(id: 1, name: 'Badminton'),
            CoachSport(id: 2, name: 'Tennis'),
          ]),
        ]),
      ),
    );

    final options = await container.read(sportOptionsProvider.future);

    expect(options, hasLength(2));
    expect(options.map((s) => s.id), [1, 2]);
    expect(options.first.name, 'Badminton');
  });

  test('a sport known only to a coach still shows up', () async {
    // A fresh platform can have coaches but no published package yet.
    final container = _container(
      packages: ApiSuccess(_page(const <TrainingPackage>[])),
      coaches: ApiSuccess(
        _page([
          _coach(const [CoachSport(id: 3, name: 'Football')]),
        ]),
      ),
    );

    final options = await container.read(sportOptionsProvider.future);
    expect(options.single.name, 'Football');
  });

  test('one failing source does not hide the sports of the other', () async {
    final container = _container(
      packages: const ApiFailure(_error),
      coaches: ApiSuccess(
        _page([
          _coach(const [CoachSport(id: 1, name: 'Badminton')]),
        ]),
      ),
    );

    final options = await container.read(sportOptionsProvider.future);
    expect(options.single.name, 'Badminton');
  });

  test(
    'when both sources fail the error surfaces instead of an empty list',
    () async {
      final container = _container(
        packages: const ApiFailure(_error),
        coaches: const ApiFailure(_error),
      );

      // The picker must be able to say "không tải được" + offer a retry, rather
      // than claim there are no sports and demand a manual id.
      await expectLater(
        container.read(sportOptionsProvider.future),
        throwsA(isA<ApiError>()),
      );
    },
  );

  test('an empty backend returns an empty catalogue, not an error', () async {
    final container = _container(
      packages: ApiSuccess(_page(const <TrainingPackage>[])),
      coaches: ApiSuccess(_page(const <PublicCoach>[])),
    );

    final options = await container.read(sportOptionsProvider.future);
    expect(options, isEmpty);
  });
}
