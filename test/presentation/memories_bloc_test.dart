import 'package:flutter_test/flutter_test.dart';
import 'package:memento/core/error/failures.dart';
import 'package:memento/core/result.dart';
import 'package:memento/domain/entities/memory.dart';
import 'package:memento/domain/repositories/location_port.dart';
import 'package:memento/domain/repositories/memory_repository.dart';
import 'package:memento/domain/usecases/find_memories_nearby.dart';
import 'package:memento/domain/usecases/get_on_this_day_memories.dart';
import 'package:memento/domain/usecases/query_memories_between.dart';
import 'package:memento/domain/value_objects/distance.dart';
import 'package:memento/domain/value_objects/geo_anchor.dart';
import 'package:memento/domain/value_objects/memory_moment.dart';
import 'package:memento/presentation/memories/bloc/memories_bloc.dart';

class FakeLocationPort implements LocationPort {
  @override
  Stream<GeofenceHit> get hits => const Stream.empty();

  @override
  Future<LocationPermissionState> checkPermission() async =>
      LocationPermissionState.denied;

  @override
  Future<LocationPermissionState> requestWhileInUse() async =>
      LocationPermissionState.denied;

  @override
  Future<LocationPermissionState> requestAlways() async =>
      LocationPermissionState.denied;

  @override
  Future<GeoAnchor?> currentPosition({bool allowStale = true}) async => null;

  @override
  Future<Result<void>> replaceGeofences(Set<GeofenceRegion> regions) async =>
      Result.ok(null);

  @override
  Future<Result<void>> clearGeofences() async => Result.ok(null);
}

class FakeMemoryRepository implements MemoryRepository {
  FakeMemoryRepository({this.memories = const [], this.failure});

  final List<Memory> memories;
  final Failure? failure;

  @override
  Future<Result<List<Memory>>> findByCalendarDay({
    required int month,
    required int day,
  }) async {
    if (failure != null) return Result.err(failure!);
    return Result.ok(
      memories
          .where((m) => m.moment.fallsOnCalendarDay(month: month, day: day))
          .toList(),
    );
  }

  @override
  Future<Result<Memory>> save(Memory memory) =>
      Future.value(Result.err(const DatabaseFailure('unused')));

  @override
  Future<Result<Memory?>> findById(String id) =>
      Future.value(Result.ok(null));

  @override
  Future<Result<List<Memory>>> findByDateRange(
    DateTime startUtcInclusive,
    DateTime endUtcExclusive,
  ) =>
      Future.value(Result.ok(const <Memory>[]));

  @override
  Future<Result<List<Memory>>> findWithinRadius({
    required GeoAnchor center,
    required Distance radius,
  }) =>
      Future.value(Result.ok(const <Memory>[]));

  @override
  Future<Result<List<Memory>>> findByTaggedContacts(
          Set<String> contactIds) =>
      Future.value(Result.ok(const <Memory>[]));

  @override
  Future<Result<List<Memory>>> findGeoAnchored({required int limit}) =>
      Future.value(Result.ok(const <Memory>[]));

  @override
  Future<Result<void>> delete(String id) => Future.value(Result.ok(null));
}

Memory _memoryAt(DateTime localWhen, String title) => Memory(
      id: 'id-$title',
      title: title,
      moment: MemoryMoment.at(localWhen),
      createdAtUtc: localWhen.toUtc(),
      updatedAtUtc: localWhen.toUtc(),
    );

void main() {
  group('MemoriesBloc', () {
    test('OnThisDayRequested returns only historical years, newest first',
        () async {
      final reference = DateTime(2026, 6, 15, 12);
      final repository = FakeMemoryRepository(memories: [
        _memoryAt(DateTime(2021, 6, 15, 9), 'older picnic'),
        _memoryAt(DateTime(2024, 6, 15, 10), 'recent beach'),
        _memoryAt(DateTime(2026, 6, 15, 8), 'today - excluded'),
        _memoryAt(DateTime(2023, 7, 4, 8), 'wrong day - excluded'),
      ]);

      final bloc = MemoriesBloc(
        onThisDay: GetOnThisDayMemories(repository),
        between: QueryMemoriesBetween(repository),
        nearby: FindMemoriesNearby(repository, FakeLocationPort()),
      );
      final emitted = <MemoriesState>[];
      bloc.stream.listen(emitted.add);

      bloc.add(OnThisDayRequested(referenceLocal: reference));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final ready = emitted.whereType<MemoriesReady>().single;
      expect(
        ready.memories.map((m) => m.title),
        ['recent beach', 'older picnic'],
      );

      await bloc.close();
    });

    test('repository failure surfaces as a failure state', () async {
      final repository =
          FakeMemoryRepository(failure: const DatabaseFailure('vault locked'));
      final bloc = MemoriesBloc(
        onThisDay: GetOnThisDayMemories(repository),
        between: QueryMemoriesBetween(repository),
        nearby: FindMemoriesNearby(repository, FakeLocationPort()),
      );
      final emitted = <MemoriesState>[];
      bloc.stream.listen(emitted.add);

      bloc.add(OnThisDayRequested(referenceLocal: DateTime(2026, 3, 3)));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(emitted.whereType<MemoriesFailureState>().isNotEmpty, isTrue);

      await bloc.close();
    });
  });
}
