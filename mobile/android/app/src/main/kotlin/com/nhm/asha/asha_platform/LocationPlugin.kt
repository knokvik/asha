package com.nhm.asha.asha_platform

import android.Manifest
import android.content.pm.PackageManager
import android.location.Criteria
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Supplies a permission-gated current Android location to the map screen. */
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
        val provider = manager.getBestProvider(
            Criteria().apply {
                accuracy = if (hasFine) Criteria.ACCURACY_FINE else Criteria.ACCURACY_COARSE
                isCostAllowed = false
            },
            true,
        ) ?: run {
            result.success(null)
            return
        }

        @Suppress("MissingPermission")
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
            manager.getCurrentLocation(provider, null, activity.mainExecutor) { location ->
                result.success(location?.toMap())
            }
        } else {
            @Suppress("DEPRECATION")
            val listener = object : LocationListener {
                override fun onLocationChanged(location: Location) {
                    @Suppress("DEPRECATION")
                    manager.removeUpdates(this)
                    result.success(location.toMap())
                }

                override fun onProviderEnabled(providerName: String) = Unit

                override fun onProviderDisabled(providerName: String) = Unit

                @Suppress("DEPRECATION")
                override fun onStatusChanged(providerName: String?, status: Int, extras: Bundle?) = Unit
            }
            @Suppress("DEPRECATION")
            manager.requestSingleUpdate(provider, listener, Looper.getMainLooper())
        }
    }

    private fun Location.toMap(): Map<String, Double> = mapOf(
        "latitude" to latitude,
        "longitude" to longitude,
    )
}
