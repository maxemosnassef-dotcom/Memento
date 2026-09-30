import '../../core/result.dart';
import '../entities/memory.dart';
import '../value_objects/distance.dart';
import '../value_objects/geo_anchor.dart';

abstract interface class MemoryRepository {
  Future<Result<Memory>> save(Memory memory);

  Future<Result<Memory?>> findById(String id);

  Future<Result<List<Memory>>> findByDateRange(
    DateTime startUtcInclusive,
    DateTime endUtcExclusive,
  );

  Future<Result<List<Memory>>> findByCalendarDay({
    required int month,
    required int day,
  });

  Future<Result<List<Memory>>> findWithinRadius({
    required GeoAnchor center,
    required Distance radius,
  });

  Future<Result<List<Memory>>> findByTaggedContacts(Set<String> contactIds);

  Future<Result<List<Memory>>> findGeoAnchored({required int limit});

  Future<Result<void>> delete(String id);
}
