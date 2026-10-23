package com.nhm.asha.asha_platform

import android.Manifest
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Supplies high-precision GPS satellite location to the Flutter map screen.
 *
 * Prioritizes hardware GPS_PROVIDER for pinpoint meter-level accuracy (exact colony and street).
 * Falls back gracefully to NETWORK_PROVIDER and recent location fixes if satellite lock is unavailable.
 */
class LocationPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var activityBinding: ActivityPluginBinding? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "asha_platform/location")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivity() {
        activityBinding = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "openLocationSettings") {
            val activity = activityBinding?.activity
            if (activity == null) {
                result.error("ACTIVITY_UNAVAILABLE", "The map activity is not available.", null)
                return
            }
            activity.startActivity(Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS))
            result.success(null)
            return
        }
        if (call.method != "getCurrentLocation") {
            result.notImplemented()
            return
        }

        val activity = activityBinding?.activity
        if (activity == null) {
            result.error("ACTIVITY_UNAVAILABLE", "The map activity is not available.", null)
            return
        }

        val hasFine = ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.ACCESS_FINE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        val hasCoarse = ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        if (!hasFine && !hasCoarse) {
            result.error("PERMISSION_DENIED", "Location permission has not been granted.", null)
            return
        }

        val manager = activity.getSystemService(LocationManager::class.java)
        if (manager == null) {
            result.error("SERVICE_UNAVAILABLE", "LocationManager is not available.", null)
            return
        }

        val isGpsEnabled = manager.isProviderEnabled(LocationManager.GPS_PROVIDER)
        val isNetworkEnabled = manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)

        if (!isGpsEnabled && !isNetworkEnabled) {
            result.error("GPS_DISABLED", "GPS and Location services are disabled. Please enable them.", null)
            return
        }

        // Check best recent last-known location
        var bestLocation: Location? = null

        @Suppress("MissingPermission")
        fun checkLastKnown(provider: String) {
            if (manager.isProviderEnabled(provider)) {
                val loc = manager.getLastKnownLocation(provider) ?: return
                // Check age (within 2 minutes)
                val ageMillis = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.JELLY_BEAN_MR1) {
                    (SystemClock.elapsedRealtimeNanos() - loc.elapsedRealtimeNanos) / 1_000_000
                } else {
                    System.currentTimeMillis() - loc.time
                }
                if (ageMillis < 120_000) {
                    if (bestLocation == null || loc.accuracy < (bestLocation?.accuracy ?: Float.MAX_VALUE)) {
                        bestLocation = loc
                    }
                }
            }
        }

        if (hasFine && isGpsEnabled) {
            checkLastKnown(LocationManager.GPS_PROVIDER)
        }
        if (isNetworkEnabled) {
            checkLastKnown(LocationManager.NETWORK_PROVIDER)
        }

        // If we have a very fresh and precise GPS fix (< 15s old and <= 10m accuracy), return immediately
        bestLocation?.let { loc ->
            if (loc.provider == LocationManager.GPS_PROVIDER && loc.accuracy <= 10f) {
                result.success(loc.toMap())
                return
            }
        }

        // Otherwise, request active high-accuracy location updates to lock onto GPS satellites
        val handler = Handler(Looper.getMainLooper())
        var isResultReturned = false

        fun returnResult(location: Location?) {
            if (isResultReturned) return
            isResultReturned = true
            result.success(location?.toMap())
        }

        val listener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                // Keep the location with the best accuracy
                if (bestLocation == null || location.accuracy < (bestLocation?.accuracy ?: Float.MAX_VALUE)) {
                    bestLocation = location
                }

                // If we get a high-accuracy GPS fix (<= 12 meters), return immediately!
                if ((location.provider == LocationManager.GPS_PROVIDER || hasFine) && location.accuracy <= 12f) {
                    @Suppress("MissingPermission")
                    manager.removeUpdates(this)
                    handler.removeCallbacksAndMessages(null)
                    returnResult(location)
                }
            }

            override fun onProviderEnabled(provider: String) = Unit
            override fun onProviderDisabled(provider: String) = Unit
            @Suppress("DEPRECATION")
            override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) = Unit
        }

        // Set a 5-second timeout to return the best fix acquired so far (preventing UI freeze if indoor)
        val timeoutRunnable = Runnable {
            @Suppress("MissingPermission")
            manager.removeUpdates(listener)
            returnResult(bestLocation)
        }
        handler.postDelayed(timeoutRunnable, 5000)

        @Suppress("MissingPermission")
        try {
            // Register GPS provider with 0 distance and 0 time delta for instant satellite updates
            if (hasFine && isGpsEnabled) {
                manager.requestLocationUpdates(
                    LocationManager.GPS_PROVIDER,
                    0L,
                    0f,
                    listener,
                    Looper.getMainLooper(),
                )
            }
            // Also register network provider as fast fallback
            if (isNetworkEnabled) {
                manager.requestLocationUpdates(
                    LocationManager.NETWORK_PROVIDER,
                    0L,
                    0f,
                    listener,
                    Looper.getMainLooper(),
                )
            }
        } catch (e: Exception) {
            handler.removeCallbacksAndMessages(null)
            @Suppress("MissingPermission")
            manager.removeUpdates(listener)
            returnResult(bestLocation)
        }
    }

    private fun Location.toMap(): Map<String, Any> = mutableMapOf<String, Any>(
        "latitude" to latitude,
        "longitude" to longitude,
        "accuracy" to accuracy.toDouble(),
        "altitude" to altitude,
        "speed" to speed.toDouble(),
        "time" to time.toDouble(),
        "provider" to (provider ?: "gps"),
    ).apply {
        if (hasBearing()) put("bearing", bearing.toDouble())
    }
}
