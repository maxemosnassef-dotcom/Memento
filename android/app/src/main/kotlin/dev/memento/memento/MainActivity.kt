package dev.memento.memento

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MementoGeofencingBridge.COMMAND_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "replace" -> {
                    @Suppress("UNCHECKED_CAST")
                    val regions = call.argument<List<Map<String, Any?>>>("regions")
                        ?: emptyList()
                    MementoGeofencingBridge.replace(applicationContext, regions, result)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MementoGeofencingBridge.EVENT_CHANNEL,
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                MementoGeofencingBridge.attach(events)
            }

            override fun onCancel(arguments: Any?) {
                MementoGeofencingBridge.attach(null)
            }
        })
    }
}
