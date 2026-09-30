import '../../core/result.dart';
import '../../core/use_case.dart';
import '../repositories/location_port.dart';
import '../repositories/memory_repository.dart';
import '../value_objects/distance.dart';

class HotspotSyncReport {
  final int regionsRegistered;
  final bool permissionSufficient;

  const HotspotSyncReport({
    required this.regionsRegistered,
    required this.permissionSufficient,
  });
}

class SyncMemoryHotspots extends UseCase<HotspotSyncReport, NoParams> {
  static const int _maxRegions = 90;
  static const int _clusterPrecision = 6;
  static const double _regionRadiusMeters = 150;

  final MemoryRepository _memories;
  final LocationPort _location;
  final double Function() _radiusMetersResolver;

  SyncMemoryHotspots(
    this._memories,
    this._location, {
    double Function()? radiusMetersResolver,
  }) : _radiusMetersResolver =
            radiusMetersResolver ?? (() => _regionRadiusMeters);

  @override
  Future<Result<HotspotSyncReport>> execute(NoParams input) async {
    final permission = await _location.checkPermission();
    if (permission != LocationPermissionState.always) {
      return Result.ok(const HotspotSyncReport(
        regionsRegistered: 0,
        permissionSufficient: false,
      ));
    }

    final anchoredResult =
        await _memories.findGeoAnchored(limit: _maxRegions * 4);
    if (anchoredResult.isErr) return Result.err(anchoredResult.failureOrNull()!);

    final clusters = <String, GeofenceRegion>{};
    for (final memory in anchoredResult.getOrNull()!) {
      final anchor = memory.anchor!;
      final cellKey = anchor.geohashAt(_clusterPrecision);
      clusters.putIfAbsent(cellKey, () {
        return GeofenceRegion(
          id: 'hotspot.$cellKey',
          center: anchor,
          radius: Distance.ofMeters(_radiusMetersResolver()),
        );
      });
      if (clusters.length >= _maxRegions) break;
    }

    final replaceResult = await _location.replaceGeofences(
      Set.unmodifiable(clusters.values),
    );
    return replaceResult.map((_) => HotspotSyncReport(
          regionsRegistered: clusters.length,
          permissionSufficient: true,
        ));
  }
}
