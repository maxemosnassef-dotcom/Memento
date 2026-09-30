import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../core/error/mapping.dart';
import '../../core/geo/geo_math.dart';
import '../../core/result.dart';
import '../../domain/entities/memory.dart';
import '../../domain/repositories/memory_repository.dart';
import '../../domain/value_objects/distance.dart';
import '../../domain/value_objects/geo_anchor.dart';
import '../datasources/local/memory_local_data_source.dart';
import '../mappers/entity_mappers.dart';

class MemoryRepositoryImpl implements MemoryRepository {
  final MemoryLocalDataSource _local;

  const MemoryRepositoryImpl(this._local);

  @override
  Future<Result<Memory>> save(Memory memory) async => _guard(() async {
        final row = MemoryMapper.toRow(memory, seq: 0);
        await _local.upsert(row);
        final persisted = await _local.byId(memory.id);
        if (persisted == null) {
          throw StateError('Persisted memory vanished immediately after upsert');
        }
        return MemoryMapper.toDomain(persisted);
      });

  @override
  Future<Result<Memory?>> findById(String id) async => _guard(() async {
        final row = await _local.byId(id);
        return row == null ? null : MemoryMapper.toDomain(row);
      });

  @override
  Future<Result<List<Memory>>> findByDateRange(
    DateTime startUtcInclusive,
    DateTime endUtcExclusive,
  ) async =>
      _guard(() async {
        final rows = await _local.between(
          startUtcInclusive.millisecondsSinceEpoch,
          endUtcExclusive.millisecondsSinceEpoch,
        );
        return MemoryMapper.listToDomain(rows);
      });

  @override
  Future<Result<List<Memory>>> findByCalendarDay({
    required int month,
    required int day,
  }) async =>
      _guard(() async =>
          MemoryMapper.listToDomain(await _local.onCalendarDay(month: month, day: day)));

  @override
  Future<Result<List<Memory>>> findWithinRadius({
    required GeoAnchor center,
    required Distance radius,
  }) async =>
      _guard(() async {
        final span = GeoMath.degreeSpan(
          radiusMeters: radius.meters,
          latitude: center.latitude,
        );
        final candidates = await _local.withinBoundingBox(
          minLat: center.latitude - span.deltaLat,
          maxLat: center.latitude + span.deltaLat,
          minLng: center.longitude - span.deltaLng,
          maxLng: center.longitude + span.deltaLng,
        );

        final scored = <(Memory, double)>[];
        for (final row in candidates) {
          if (!row.isGeoAnchored) continue;
          final meters = GeoMath.distanceMeters(
            lat1: center.latitude,
            lng1: center.longitude,
            lat2: row.latitude!,
            lng2: row.longitude!,
          );
          if (meters <= radius.meters) {
            scored.add((MemoryMapper.toDomain(row), meters));
          }
        }
        scored.sort((a, b) => a.$2.compareTo(b.$2));
        return scored.map((pair) => pair.$1).toList(growable: false);
      });

  @override
  Future<Result<List<Memory>>> findByTaggedContacts(
      Set<String> contactIds) async =>
      _guard(() async =>
          MemoryMapper.listToDomain(await _local.taggedWith(contactIds)));

  @override
  Future<Result<List<Memory>>> findGeoAnchored({required int limit}) async =>
      _guard(() async =>
          MemoryMapper.listToDomain(await _local.geoAnchored(limit: limit)));

  @override
  Future<Result<void>> delete(String id) async =>
      _guard(() => _local.delete(id));

  Future<Result<T>> _guard<T>(Future<T> Function() operation) async {
    try {
      return Result.ok(await operation());
    } on AppException catch (e) {
      return Result.err(e.toFailure());
    } catch (e) {
      return Result.err(DatabaseFailure('$e'));
    }
  }
}
