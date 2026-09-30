import 'dart:async';

import '../../core/result.dart';
import '../value_objects/distance.dart';
import '../value_objects/geo_anchor.dart';

enum LocationPermissionState { undetermined, denied, deniedPermanently, whileInUse, always }

class GeofenceRegion {
  final String id;
  final GeoAnchor center;
  final Distance radius;

  const GeofenceRegion({
    required this.id,
    required this.center,
    required this.radius,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GeofenceRegion && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

enum GeofenceTransition { entered, exited }

class GeofenceHit {
  final String regionId;
  final GeofenceTransition transition;
  final DateTime occurredAtUtc;

  const GeofenceHit({
    required this.regionId,
    required this.transition,
    required this.occurredAtUtc,
  });
}

abstract interface class LocationPort {
  Stream<GeofenceHit> get hits;

  Future<LocationPermissionState> checkPermission();

  Future<LocationPermissionState> requestWhileInUse();

  Future<LocationPermissionState> requestAlways();

  Future<GeoAnchor?> currentPosition({bool allowStale = true});

  Future<Result<void>> replaceGeofences(Set<GeofenceRegion> regions);

  Future<Result<void>> clearGeofences();
}
