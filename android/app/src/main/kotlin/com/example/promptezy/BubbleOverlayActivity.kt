package com.example.promptezy

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class BubbleOverlayActivity : FlutterActivity() {

    private val channelName = "com.loadstash/bubble"

    override fun getInitialRoute(): String = "/bubble-overlay"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "insertText" -> {
                        val text = call.argument<String>("text") ?: ""
                        val clipboard = getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
                        clipboard.setPrimaryClip(ClipData.newPlainText("prompt", text))
                        LoadstashAccessibilityService.pasteAfterDelay()
                        result.success(null)
                        finish()
                    }
                    "cancel" -> {
                        result.success(null)
                        finish()
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
