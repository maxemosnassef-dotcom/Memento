import CoreLocation
import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
  private let locationManager = CLLocationManager()
  private var geofenceEventSink: FlutterEventSink?
  private let commandChannelName = "memento.dev/geofencing"
  private let eventChannelName = "memento.dev/geofencing/events"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    locationManager.delegate = self
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerGeofencingChannels(with: engineBridge.pluginRegistry)
  }

  private func registerGeofencingChannels(with registry: NSObject) {
    guard let messenger = registry.value(forKey: "binaryMessenger") as? FlutterBinaryMessenger
    else { return }

    FlutterMethodChannel(name: commandChannelName, binaryMessenger: messenger)
      .setMethodCallHandler { [weak self] call, result in
        guard let self = self else { return }
        switch call.method {
        case "replace":
          guard let regions = call.arguments as? [[String: Any]] else {
            result(FlutterError(code: "geofence", message: "Invalid regions payload", details: nil))
            return
          }
          self.replaceGeofences(regions, result: result)
        default:
          result(FlutterMethodNotImplemented)
        }
      }

    FlutterEventChannel(name: eventChannelName, binaryMessenger: messenger)
      .setStreamHandler(GeofenceStreamHandler { [weak self] sink in
        self?.geofenceEventSink = sink
      })
  }

  private func replaceGeofences(_ regions: [[String: Any]], result: @escaping FlutterResult) {
    for region in locationManager.monitoredRegions {
      locationManager.stopMonitoring(for: region)
    }
    if regions.isEmpty {
      result(nil)
      return
    }
    for entry in regions {
      guard
        let id = entry["id"] as? String,
        let latitude = entry["latitude"] as? Double,
        let longitude = entry["longitude"] as? Double,
        let radiusMeters = entry["radiusMeters"] as? Double
      else {
        result(FlutterError(code: "geofence", message: "Malformed region", details: nil))
        return
      }
      let clampedRadius = min(max(radiusMeters, 50), 2000)
      let region = CLCircularRegion(
        center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
        radius: clampedRadius,
        identifier: id
      )
      region.notifyOnEntry = true
      region.notifyOnExit = true
      locationManager.startMonitoring(for: region)
    }
    result(nil)
  }

  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    emit(region.identifier, transition: "enter")
  }

  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    emit(region.identifier, transition: "exit")
  }

  private func emit(_ regionId: String, transition: String) {
    let formatter = ISO8601DateFormatter()
    geofenceEventSink?([
      "id": regionId,
      "transition": transition,
      "at": formatter.string(from: Date()),
    ])
  }
}

final class GeofenceStreamHandler: NSObject, FlutterStreamHandler {
  private let onListenCallback: (FlutterEventSink?) -> Void

  init(onListen callback: @escaping (FlutterEventSink?) -> Void) {
    onListenCallback = callback
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError? {
    onListenCallback(events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    onListenCallback(nil)
    return nil
  }
}
