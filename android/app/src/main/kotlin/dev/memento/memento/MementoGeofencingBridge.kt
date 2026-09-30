package dev.memento.memento

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingEvent
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

object MementoGeofencingBridge {

    const val COMMAND_CHANNEL = "memento.dev/geofencing"
    const val EVENT_CHANNEL = "memento.dev/geofencing/events"

    private const val TRANSITION_ENTER = "enter"
    private const val TRANSITION_EXIT = "exit"

    @Volatile
    var eventSink: EventChannel.EventSink? = null
        private set

    fun attach(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    fun dispatch(regionId: String, transition: String) {
        eventSink?.success(
            mapOf(
                "id" to regionId,
                "transition" to transition,
                "at" to java.time.OffsetDateTime.now().toString(),
            ),
        )
    }

    @SuppressLint("MissingPermission")
    fun replace(context: Context, regions: List<Map<String, Any?>>, result: MethodChannel.Result) {
        try {
            val client = LocationServices.getGeofencingClient(context)
            client.removeGeofences(pendingIntent(context))
            if (regions.isEmpty()) {
                result.success(null)
                return
            }
            val fences = regions.map { region ->
                Geofence.Builder()
                    .setRequestId(region["id"] as String)
                    .setCircularRegion(
                        (region["latitude"] as Number).toDouble(),
                        (region["longitude"] as Number).toDouble(),
                        ((region["radiusMeters"] as Number).toDouble().toFloat())
                            .coerceIn(50f, 2000f),
                    )
                    .setTransitionTypes(
                        Geofence.GEOFENCE_TRANSITION_ENTER or Geofence.GEOFENCE_TRANSITION_EXIT,
                    )
                    .setExpirationDuration(Geofence.NEVER_EXPIRE)
                    .setNotificationResponsiveness(5 * 60 * 1000)
                    .build()
            }
            val request = GeofencingRequest.Builder()
                .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
                .addGeofences(fences)
                .build()
            client.addGeofences(request, pendingIntent(context))
            result.success(null)
        } catch (e: SecurityException) {
            result.error("permission", e.message, null)
        } catch (e: Exception) {
            result.error("geofence", e.message, null)
        }
    }

    fun decodeIntent(intent: Intent?): Pair<String, String>? {
        val event = intent?.let { GeofencingEvent.fromIntent(it) } ?: return null
        if (event.hasError()) return null
        val transition = when (event.geofenceTransition) {
            Geofence.GEOFENCE_TRANSITION_ENTER -> TRANSITION_ENTER
            Geofence.GEOFENCE_TRANSITION_EXIT -> TRANSITION_EXIT
            else -> return null
        }
        val region = event.triggeringGeofences?.firstOrNull() ?: return null
        return Pair(region.requestId, transition)
    }

    private fun pendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, MementoGeofenceReceiver::class.java)
        return PendingIntent.getBroadcast(
            context,
            1907,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
        )
    }
}
