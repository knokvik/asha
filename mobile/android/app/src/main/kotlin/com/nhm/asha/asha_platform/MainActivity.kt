package com.nhm.asha.asha_platform

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Register the security plugin that exposes FLAG_SECURE toggling
        // via the 'com.nhm.asha/security' MethodChannel.
        // Requirements: 2.2
        flutterEngine.plugins.add(SecurityPlugin())
    }
}
