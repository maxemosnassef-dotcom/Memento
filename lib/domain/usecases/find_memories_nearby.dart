import '../../core/error/failures.dart';
import '../../core/result.dart';
import '../../core/use_case.dart';
import '../entities/memory.dart';
import '../repositories/location_port.dart';
import '../repositories/memory_repository.dart';
import '../value_objects/distance.dart';
import '../value_objects/geo_anchor.dart';

class NearbyQuery {
  final GeoAnchor? center;
  final Distance radius;

  const NearbyQuery({
    this.center,
    required this.radius,
  });
}

class FindMemoriesNearby extends UseCase<List<Memory>, NearbyQuery> {
  static final Distance defaultRadius = Distance.ofMeters(150);

  final MemoryRepository _memories;
  final LocationPort _location;

  const FindMemoriesNearby(this._memories, this._location);

  @override
  Future<Result<List<Memory>>> execute(NearbyQuery input) async {
    var anchor = input.center;
    if (anchor == null) {
      anchor = await _location.currentPosition(allowStale: false);
      if (anchor == null) {
        return Result.err(
          const PermissionFailure('Current location unavailable'),
        );
      }
    }
    return _memories.findWithinRadius(center: anchor, radius: input.radius);
  }
}
