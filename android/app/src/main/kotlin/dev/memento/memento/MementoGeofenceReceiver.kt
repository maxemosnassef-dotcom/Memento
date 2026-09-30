package dev.memento.memento

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class MementoGeofenceReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val hit = MementoGeofencingBridge.decodeIntent(intent) ?: return
        val (regionId, transition) = hit
        MementoGeofencingBridge.dispatch(regionId, transition)
    }
}
