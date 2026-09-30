import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';

import '../../core/error/failures.dart';
import '../../core/result.dart';
import '../../domain/repositories/location_port.dart';
import '../../domain/value_objects/geo_anchor.dart';

class GeolocatorLocationPort implements LocationPort {
  static const MethodChannel _commands =
      MethodChannel('memento.dev/geofencing');
  static const EventChannel _eventStream =
      EventChannel('memento.dev/geofencing/events');

  final LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.low,
    distanceFilter: 25,
  );

  @override
  Stream<GeofenceHit> get hits => _eventStream
      .receiveBroadcastStream()
      .map(_decodeHit);

  @override
  Future<LocationPermissionState> checkPermission() async {
    final permission = await Geolocator.checkPermission();
    return _mapPermission(permission);
  }

  @override
  Future<LocationPermissionState> requestWhileInUse() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionState.deniedPermanently;
    }
    return _mapPermission(permission);
  }

  @override
  Future<LocationPermissionState> requestAlways() async {
    var state = await requestWhileInUse();
    if (state == LocationPermissionState.always ||
        state == LocationPermissionState.deniedPermanently) {
      return state;
    }
    try {
      await Geolocator.openAppSettings();
    } finally {
      state = await checkPermission();
    }
    return state;
  }

  @override
  Future<GeoAnchor?> currentPosition({bool allowStale = true}) async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      Position? position;
      if (allowStale) {
        position = await Geolocator.getLastKnownPosition();
      }
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings,
      );
      return GeoAnchor.of(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on Exception {
      return null;
    }
  }

  @override
  Future<Result<void>> replaceGeofences(Set<GeofenceRegion> regions) async {
    try {
      await _commands.invokeMethod<void>('replace', {
        'regions': [
          for (final region in regions)
            {
              'id': region.id,
              'latitude': region.center.latitude,
              'longitude': region.center.longitude,
              'radiusMeters': region.radius.meters,
            },
        ],
      });
      return Result.ok(null);
    } on MissingPluginException {
      return Result.err(
        const CapabilityFailure('Native geofencing bridge is not registered'),
      );
    } on PlatformException catch (e) {
      return Result.err(CapabilityFailure(e.message ?? 'Geofencing call failed'));
    }
  }

  @override
  Future<Result<void>> clearGeofences() => replaceGeofences(const {});

  GeofenceHit _decodeHit(Object? raw) {
    final map = Map<Object?, Object?>.from(raw! as Map);
    return GeofenceHit(
      regionId: map['id']! as String,
      transition:
          map['transition'] == 'enter' ? GeofenceTransition.entered : GeofenceTransition.exited,
      occurredAtUtc: DateTime.tryParse(map['at'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }

  LocationPermissionState _mapPermission(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.always => LocationPermissionState.always,
        LocationPermission.whileInUse => LocationPermissionState.whileInUse,
        LocationPermission.deniedForever =>
          LocationPermissionState.deniedPermanently,
        LocationPermission.unableToDetermine =>
          LocationPermissionState.undetermined,
        LocationPermission.denied => LocationPermissionState.denied,
      };
}
