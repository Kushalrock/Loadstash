package com.example.promptezy

import android.app.Application
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

class LoadstashApplication : Application() {
    companion object {
        const val OVERLAY_ENGINE_ID = "overlay_engine"
    }

    override fun onCreate() {
        super.onCreate()

        val engine = FlutterEngine(this)
        engine.navigationChannel.setInitialRoute("/overlay")
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        FlutterEngineCache.getInstance().put(OVERLAY_ENGINE_ID, engine)
    }
}
