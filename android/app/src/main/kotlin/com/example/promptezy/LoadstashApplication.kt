package com.example.promptezy

import android.app.Application

// Pre-warming removed: the overlay engine must start fresh inside ProcessTextActivity
// so that configureFlutterEngine() registers the MethodChannel handler BEFORE
// Dart's OverlayScreen calls getIntentData(). Pre-warming caused a race where
// Dart ran before any handler existed, leaving the overlay on an infinite spinner.
class LoadstashApplication : Application()
