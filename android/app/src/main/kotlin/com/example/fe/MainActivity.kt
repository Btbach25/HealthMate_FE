package com.example.fe

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app/health_connect")
            .setMethodCallHandler { call, result ->
                if (call.method == "openPermissionSettings") {
                    result.success(openHealthConnect())
                } else {
                    result.notImplemented()
                }
            }
    }

    /**
     * Mở màn hình Health Connect. Thử theo thứ tự:
     * 1. App Health Connect (Play Store, Android 13)
     * 2. Built-in Health Connect (Android 14)
     * 3. URI scheme healthconnect://app
     * 4. App settings của app này (fallback cuối)
     */
    private fun openHealthConnect(): Boolean {
        val candidates = listOf(
            "com.google.android.apps.healthdata",          // HC từ Play Store
            "com.android.healthconnect.controller",        // Built-in Android 14 (AOSP)
            "com.google.android.healthconnect.controller", // Built-in Android 14 (Google)
        )

        for (pkg in candidates) {
            val intent = packageManager.getLaunchIntentForPackage(pkg)
            if (intent != null) {
                startActivity(intent)
                return true
            }
        }

        // Thử URI scheme
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("healthconnect://app"))
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                return true
            }
        } catch (_: Exception) {}

        // Fallback: mở settings của app này
        try {
            val intent = Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.parse("package:$packageName"))
            startActivity(intent)
            return true
        } catch (_: Exception) {}

        return false
    }
}
