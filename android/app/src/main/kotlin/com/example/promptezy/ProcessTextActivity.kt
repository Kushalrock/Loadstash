package com.example.promptezy

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class ProcessTextActivity : FlutterActivity() {
    private val channelName = "com.loadstash/overlay"

    override fun getCachedEngineId(): String = LoadstashApplication.OVERLAY_ENGINE_ID

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getIntentData" -> {
                        val text = intent
                            .getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)
                            ?.toString() ?: ""
                        val readOnly = intent
                            .getBooleanExtra(Intent.EXTRA_PROCESS_TEXT_READONLY, false)
                        val pkg = callingPackage ?: ""
                        result.success(
                            mapOf(
                                "selectedText" to text,
                                "isReadOnly" to readOnly,
                                "callingPackage" to pkg,
                            )
                        )
                    }
                    "setResult" -> {
                        val text = call.argument<String>("text") ?: ""
                        val resultIntent = Intent().apply {
                            putExtra(Intent.EXTRA_PROCESS_TEXT, text)
                        }
                        setResult(RESULT_OK, resultIntent)
                        result.success(null)
                        finish()
                    }
                    "cancel" -> {
                        setResult(RESULT_CANCELED)
                        result.success(null)
                        finish()
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
