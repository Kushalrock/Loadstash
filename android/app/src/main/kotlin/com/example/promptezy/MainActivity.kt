package com.example.promptezy

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.loadstash/settings")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasOverlayPermission" ->
                        result.success(Settings.canDrawOverlays(this))

                    "isAccessibilityEnabled" ->
                        result.success(isAccessibilityServiceEnabled())

                    "isBubbleRunning" ->
                        result.success(BubbleService.instance != null)

                    "startBubble" -> {
                        startForegroundService(Intent(this, BubbleService::class.java))
                        result.success(null)
                    }

                    "stopBubble" -> {
                        stopService(Intent(this, BubbleService::class.java))
                        result.success(null)
                    }

                    "openOverlaySettings" -> {
                        startActivity(
                            Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            )
                        )
                        result.success(null)
                    }

                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val am = getSystemService(ACCESSIBILITY_SERVICE) as AccessibilityManager
        return am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
            .any { it.id.contains("LoadstashAccessibilityService") }
    }
}
