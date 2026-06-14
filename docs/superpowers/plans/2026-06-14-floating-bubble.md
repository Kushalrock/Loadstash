# Floating Bubble Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a keyboard-triggered floating bubble that lets users insert prompts into any Android text field (including ChatGPT) via clipboard + accessibility paste.

**Architecture:** A `BubbleService` foreground service owns the draggable bubble window. `LoadstashAccessibilityService` detects keyboard open/close and triggers paste. `BubbleOverlayActivity` hosts the existing Flutter overlay UI in bubble mode. Flutter communicates with both services via two new MethodChannels.

**Tech Stack:** Kotlin (Android Services, WindowManager, AccessibilityService) · Flutter/Dart (MethodChannel, Riverpod) · Existing overlay UI reused via `OverlayMode` enum

---

## File Structure

```
android/app/src/main/kotlin/com/example/promptezy/
  BubbleService.kt                     NEW — foreground service, owns bubble window
  LoadstashAccessibilityService.kt     NEW — keyboard detection + paste
  BubbleOverlayActivity.kt             NEW — FlutterActivity for bubble path
  MainActivity.kt                      MODIFY — add SettingsChannel handler

android/app/src/main/res/
  xml/accessibility_service_config.xml NEW — accessibility service config
  drawable/bubble_background.xml       NEW — circular accent-colour shape
  values/strings.xml                   NEW — accessibility description string

android/app/src/main/
  AndroidManifest.xml                  MODIFY — permissions, services, activity

lib/services/
  bubble_channel.dart                  NEW — MethodChannel("com.loadstash/bubble")
  settings_channel.dart                NEW — MethodChannel("com.loadstash/settings")

lib/features/overlay/
  overlay_screen.dart                  MODIFY — add OverlayMode enum, mode param

lib/features/settings/
  settings_screen.dart                 MODIFY — add Floating Bubble toggle section

lib/app.dart                           MODIFY — add /bubble-overlay route
```

---

## Task 1: Android Resources

**Files:**
- Create: `android/app/src/main/res/xml/accessibility_service_config.xml`
- Create: `android/app/src/main/res/drawable/bubble_background.xml`
- Create: `android/app/src/main/res/values/strings.xml`

- [ ] **Step 1: Create res/xml/ directory and accessibility config**

```bash
mkdir -p android/app/src/main/res/xml
```

Create `android/app/src/main/res/xml/accessibility_service_config.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<accessibility-service xmlns:android="http://schemas.android.com/apk/res/android"
    android:accessibilityEventTypes="typeWindowsChanged"
    android:accessibilityFeedbackType="feedbackGeneric"
    android:canRetrieveWindowContent="true"
    android:description="@string/accessibility_service_description"
    android:notificationTimeout="100" />
```

- [ ] **Step 2: Create bubble background drawable**

Create `android/app/src/main/res/drawable/bubble_background.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="oval">
    <solid android:color="#8B7DF6" />
</shape>
```

- [ ] **Step 3: Create strings.xml**

Create `android/app/src/main/res/values/strings.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="accessibility_service_description">Loadstash uses accessibility to detect when the keyboard opens and to paste your selected prompt into the focused text field. It only reads which windows are open — nothing else.</string>
    <string name="notification_channel_name">Loadstash Bubble</string>
    <string name="notification_channel_desc">Shows when the floating bubble is active</string>
    <string name="notification_text">Bubble active — tap to insert prompts</string>
</resources>
```

- [ ] **Step 4: Verify resources are valid XML**

```bash
xmllint --noout android/app/src/main/res/xml/accessibility_service_config.xml && echo "OK"
xmllint --noout android/app/src/main/res/drawable/bubble_background.xml && echo "OK"
xmllint --noout android/app/src/main/res/values/strings.xml && echo "OK"
```

Expected: three "OK" lines.

- [ ] **Step 5: Commit**

```bash
git add android/app/src/main/res/
git commit -m "feat: add accessibility config, bubble drawable, strings resources"
```

---

## Task 2: LoadstashAccessibilityService

**Files:**
- Create: `android/app/src/main/kotlin/com/example/promptezy/LoadstashAccessibilityService.kt`

- [ ] **Step 1: Create the service file**

```kotlin
package com.example.promptezy

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityWindowInfo

class LoadstashAccessibilityService : AccessibilityService() {

    companion object {
        var instance: LoadstashAccessibilityService? = null

        fun pasteAfterDelay() {
            instance?.doPaste()
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var keyboardVisible = false

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType != AccessibilityEvent.TYPE_WINDOWS_CHANGED) return

        val hasKeyboard = windows.any { it.type == AccessibilityWindowInfo.TYPE_INPUT_METHOD }

        if (hasKeyboard && !keyboardVisible) {
            keyboardVisible = true
            BubbleService.show()
        } else if (!hasKeyboard && keyboardVisible) {
            keyboardVisible = false
            BubbleService.hide()
        }
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        super.onDestroy()
        instance = null
    }

    fun doPaste() {
        handler.postDelayed({
            performGlobalAction(GLOBAL_ACTION_PASTE)
        }, 300)
    }
}
```

- [ ] **Step 2: Build to verify no compile errors**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 3: Commit**

```bash
git add android/app/src/main/kotlin/com/example/promptezy/LoadstashAccessibilityService.kt
git commit -m "feat: LoadstashAccessibilityService — keyboard detection and paste"
```

---

## Task 3: BubbleService

**Files:**
- Create: `android/app/src/main/kotlin/com/example/promptezy/BubbleService.kt`

- [ ] **Step 1: Create the service file**

```kotlin
package com.example.promptezy

import android.animation.ValueAnimator
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.IBinder
import android.view.Gravity
import android.view.MotionEvent
import android.view.WindowManager
import android.widget.TextView
import androidx.core.app.NotificationCompat
import kotlin.math.abs

class BubbleService : Service() {

    companion object {
        var instance: BubbleService? = null
        const val ACTION_STOP = "com.loadstash.STOP_BUBBLE"
        private const val CHANNEL_ID = "loadstash_bubble"
        private const val NOTIF_ID = 1

        fun show() { instance?.showBubble() }
        fun hide() { instance?.hideBubble() }
    }

    private lateinit var windowManager: WindowManager
    private lateinit var bubbleView: TextView
    private lateinit var params: WindowManager.LayoutParams

    private var initialX = 0
    private var initialY = 0
    private var initialTouchX = 0f
    private var initialTouchY = 0f
    private var isDragging = false

    private val bubbleSizePx: Int
        get() = (56 * resources.displayMetrics.density).toInt()

    override fun onCreate() {
        super.onCreate()
        instance = this
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        createNotificationChannel()
        createBubbleView()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        startForeground(NOTIF_ID, buildNotification())
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        if (::bubbleView.isInitialized) {
            try { windowManager.removeView(bubbleView) } catch (_: Exception) {}
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // region Bubble view

    private fun createBubbleView() {
        bubbleView = TextView(this).apply {
            text = "L"
            textSize = 22f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = android.view.Gravity.CENTER
            setBackgroundResource(R.drawable.bubble_background)
            elevation = 8f * resources.displayMetrics.density
        }

        params = WindowManager.LayoutParams(
            bubbleSizePx, bubbleSizePx,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = getScreenWidth() - bubbleSizePx - 16.dpToPx()
            y = getScreenHeight() / 2
        }

        windowManager.addView(bubbleView, params)
        bubbleView.visibility = android.view.View.GONE

        bubbleView.setOnTouchListener { _, event ->
            handleTouch(event)
        }
    }

    private fun showBubble() {
        bubbleView.visibility = android.view.View.VISIBLE
    }

    private fun hideBubble() {
        bubbleView.visibility = android.view.View.GONE
    }

    // endregion

    // region Touch handling

    private fun handleTouch(event: MotionEvent): Boolean {
        return when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                initialX = params.x
                initialY = params.y
                initialTouchX = event.rawX
                initialTouchY = event.rawY
                isDragging = false
                true
            }
            MotionEvent.ACTION_MOVE -> {
                val dx = event.rawX - initialTouchX
                val dy = event.rawY - initialTouchY
                if (abs(dx) > 8.dpToPx() || abs(dy) > 8.dpToPx()) isDragging = true
                if (isDragging) {
                    params.x = initialX + dx.toInt()
                    params.y = initialY + dy.toInt()
                    windowManager.updateViewLayout(bubbleView, params)
                }
                true
            }
            MotionEvent.ACTION_UP -> {
                if (!isDragging) {
                    onBubbleTapped()
                } else {
                    snapToEdge()
                }
                true
            }
            else -> false
        }
    }

    private fun onBubbleTapped() {
        val intent = Intent(this, BubbleOverlayActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(intent)
    }

    private fun snapToEdge() {
        val screenWidth = getScreenWidth()
        val targetX = if (params.x + bubbleSizePx / 2 < screenWidth / 2) 0
                      else screenWidth - bubbleSizePx

        ValueAnimator.ofInt(params.x, targetX).apply {
            duration = 200
            addUpdateListener { animator ->
                params.x = animator.animatedValue as Int
                try { windowManager.updateViewLayout(bubbleView, params) } catch (_: Exception) {}
            }
            start()
        }
    }

    // endregion

    // region Notification

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.notification_channel_name),
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = getString(R.string.notification_channel_desc)
            setShowBadge(false)
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification {
        val stopIntent = PendingIntent.getService(
            this, 0,
            Intent(this, BubbleService::class.java).apply { action = ACTION_STOP },
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Loadstash")
            .setContentText(getString(R.string.notification_text))
            .setSmallIcon(R.mipmap.ic_launcher)
            .addAction(0, "Stop", stopIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    // endregion

    // region Helpers

    private fun getScreenWidth(): Int {
        return if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
            windowManager.currentWindowMetrics.bounds.width()
        } else {
            @Suppress("DEPRECATION")
            val point = android.graphics.Point()
            @Suppress("DEPRECATION")
            windowManager.defaultDisplay.getRealSize(point)
            point.x
        }
    }

    private fun getScreenHeight(): Int {
        return if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
            windowManager.currentWindowMetrics.bounds.height()
        } else {
            @Suppress("DEPRECATION")
            val point = android.graphics.Point()
            @Suppress("DEPRECATION")
            windowManager.defaultDisplay.getRealSize(point)
            point.y
        }
    }

    private fun Int.dpToPx(): Int = (this * resources.displayMetrics.density).toInt()

    // endregion
}
```

- [ ] **Step 2: Build to verify**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 3: Commit**

```bash
git add android/app/src/main/kotlin/com/example/promptezy/BubbleService.kt
git commit -m "feat: BubbleService — foreground service with draggable overlay bubble"
```

---

## Task 4: BubbleOverlayActivity

**Files:**
- Create: `android/app/src/main/kotlin/com/example/promptezy/BubbleOverlayActivity.kt`

- [ ] **Step 1: Create the activity**

```kotlin
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
```

- [ ] **Step 2: Build to verify**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 3: Commit**

```bash
git add android/app/src/main/kotlin/com/example/promptezy/BubbleOverlayActivity.kt
git commit -m "feat: BubbleOverlayActivity — Flutter host for bubble overlay path"
```

---

## Task 5: Update AndroidManifest + MainActivity

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `android/app/src/main/kotlin/com/example/promptezy/MainActivity.kt`

- [ ] **Step 1: Replace AndroidManifest.xml**

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />

    <application
        android:name=".LoadstashApplication"
        android:label="Loadstash"
        android:icon="@mipmap/ic_launcher">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <activity
            android:name=".ProcessTextActivity"
            android:exported="true"
            android:theme="@style/TransparentTheme"
            android:label="Loadstash"
            android:taskAffinity=""
            android:excludeFromRecents="true">
            <intent-filter>
                <action android:name="android.intent.action.PROCESS_TEXT" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:mimeType="text/plain" />
            </intent-filter>
        </activity>

        <activity
            android:name=".BubbleOverlayActivity"
            android:exported="false"
            android:theme="@style/TransparentTheme"
            android:taskAffinity=""
            android:excludeFromRecents="true" />

        <service
            android:name=".BubbleService"
            android:exported="false"
            android:foregroundServiceType="specialUse">
            <property
                android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
                android:value="Floating overlay bubble for prompt insertion" />
        </service>

        <service
            android:name=".LoadstashAccessibilityService"
            android:exported="true"
            android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE">
            <intent-filter>
                <action android:name="android.accessibilityservice.AccessibilityService" />
            </intent-filter>
            <meta-data
                android:name="android.accessibilityservice"
                android:resource="@xml/accessibility_service_config" />
        </service>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>

    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT" />
            <data android:mimeType="text/plain" />
        </intent>
    </queries>
</manifest>
```

- [ ] **Step 2: Update MainActivity.kt**

Replace `android/app/src/main/kotlin/com/example/promptezy/MainActivity.kt`:

```kotlin
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
```

- [ ] **Step 3: Build to verify**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 4: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml \
        android/app/src/main/kotlin/com/example/promptezy/MainActivity.kt
git commit -m "feat: manifest permissions, BubbleService + AccessibilityService declarations, SettingsChannel in MainActivity"
```

---

## Task 6: Flutter BubbleChannel + SettingsChannel

**Files:**
- Create: `lib/services/bubble_channel.dart`
- Create: `lib/services/settings_channel.dart`
- Create: `test/services/bubble_channel_test.dart`
- Create: `test/services/settings_channel_test.dart`

- [ ] **Step 1: Create bubble_channel.dart**

```dart
// lib/services/bubble_channel.dart
import 'package:flutter/services.dart';

class BubbleChannel {
  static const _channel = MethodChannel('com.loadstash/bubble');

  static Future<void> insertText(String text) async {
    try {
      await _channel.invokeMethod('insertText', {'text': text});
    } catch (_) {}
  }

  static Future<void> cancel() async {
    try {
      await _channel.invokeMethod('cancel');
    } catch (_) {}
  }
}
```

- [ ] **Step 2: Create settings_channel.dart**

```dart
// lib/services/settings_channel.dart
import 'package:flutter/services.dart';

class SettingsChannel {
  static const _channel = MethodChannel('com.loadstash/settings');

  static Future<bool> hasOverlayPermission() async {
    try {
      return await _channel.invokeMethod<bool>('hasOverlayPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isAccessibilityEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('isAccessibilityEnabled') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isBubbleRunning() async {
    try {
      return await _channel.invokeMethod<bool>('isBubbleRunning') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> startBubble() async {
    try {
      await _channel.invokeMethod('startBubble');
    } catch (_) {}
  }

  static Future<void> stopBubble() async {
    try {
      await _channel.invokeMethod('stopBubble');
    } catch (_) {}
  }

  static Future<void> openOverlaySettings() async {
    try {
      await _channel.invokeMethod('openOverlaySettings');
    } catch (_) {}
  }

  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (_) {}
  }
}
```

- [ ] **Step 3: Write bubble channel tests**

Create `test/services/bubble_channel_test.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/services/bubble_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.loadstash/bubble');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('insertText sends text over channel', () async {
    await BubbleChannel.insertText('Hello {{name}}');
    expect(calls.length, 1);
    expect(calls.first.method, 'insertText');
    expect(calls.first.arguments['text'], 'Hello {{name}}');
  });

  test('insertText swallows exceptions', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'ERROR');
    });
    expect(() => BubbleChannel.insertText('text'), returnsNormally);
  });

  test('cancel sends cancel over channel', () async {
    await BubbleChannel.cancel();
    expect(calls.first.method, 'cancel');
  });
}
```

- [ ] **Step 4: Write settings channel tests**

Create `test/services/settings_channel_test.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/services/settings_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.loadstash/settings');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'hasOverlayPermission': return true;
        case 'isAccessibilityEnabled': return false;
        case 'isBubbleRunning': return false;
        default: return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('hasOverlayPermission returns bool from channel', () async {
    expect(await SettingsChannel.hasOverlayPermission(), true);
  });

  test('isAccessibilityEnabled returns bool from channel', () async {
    expect(await SettingsChannel.isAccessibilityEnabled(), false);
  });

  test('isBubbleRunning returns false when not running', () async {
    expect(await SettingsChannel.isBubbleRunning(), false);
  });

  test('all methods return false/null on exception', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'ERROR');
    });
    expect(await SettingsChannel.hasOverlayPermission(), false);
    expect(await SettingsChannel.isAccessibilityEnabled(), false);
    expect(await SettingsChannel.isBubbleRunning(), false);
  });
}
```

- [ ] **Step 5: Run tests**

```bash
flutter test test/services/bubble_channel_test.dart test/services/settings_channel_test.dart
```

Expected: 7 tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/services/bubble_channel.dart lib/services/settings_channel.dart \
        test/services/bubble_channel_test.dart test/services/settings_channel_test.dart
git commit -m "feat: BubbleChannel and SettingsChannel Flutter wrappers with tests"
```

---

## Task 7: OverlayScreen OverlayMode Refactor

**Files:**
- Modify: `lib/features/overlay/overlay_screen.dart`

Read `lib/features/overlay/overlay_screen.dart` before editing.

- [ ] **Step 1: Add OverlayMode enum and mode parameter**

At the top of `lib/features/overlay/overlay_screen.dart`, after the imports, add the enum and update the widget class signature. The complete updated file:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/database/app_database.dart';
import '../../providers/overlay_provider.dart';
import '../../providers/repository_providers.dart';
import '../../services/bubble_channel.dart';
import '../../services/process_text_channel.dart';
import '../../services/variable_detector.dart';
import 'widgets/overlay_search_bar.dart';
import 'widgets/overlay_prompt_row.dart';
import 'widgets/variable_fill_sheet.dart';

enum OverlayMode { processText, bubble }

class OverlayScreen extends ConsumerStatefulWidget {
  const OverlayScreen({super.key, this.mode = OverlayMode.processText});
  final OverlayMode mode;

  @override
  ConsumerState<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends ConsumerState<OverlayScreen> {
  String _query = '';
  List<Prompt> _prompts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.mode == OverlayMode.processText) {
      final intentData = await ProcessTextChannel.getIntentData();
      if (intentData != null && mounted) {
        ref.read(overlayIntentProvider.notifier).state = intentData;
      }
      final callingPkg = intentData?.callingPackage ?? '';
      final ranked =
          await ref.read(usageRepositoryProvider).getRankedPrompts(callingPkg);
      if (mounted) setState(() { _prompts = ranked; _loading = false; });
    } else {
      // bubble mode: no selected text, rank without callingPackage
      final ranked =
          await ref.read(usageRepositoryProvider).getRankedPrompts('');
      if (mounted) setState(() { _prompts = ranked; _loading = false; });
    }
  }

  Future<void> _onPromptTapped(Prompt prompt) async {
    final vars = VariableDetector.detect(prompt.body);
    if (vars.isEmpty) {
      await _insertAndClose(prompt.body, prompt.id);
    } else {
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (sheetCtx) => VariableFillSheet(
          promptBody: prompt.body,
          variableNames: vars,
          onInsert: (assembled) async {
            Navigator.of(sheetCtx).pop();
            await _insertAndClose(assembled, prompt.id);
          },
        ),
      );
    }
  }

  Future<void> _insertAndClose(String text, int promptId) async {
    if (widget.mode == OverlayMode.processText) {
      final intentData = ref.read(overlayIntentProvider);
      if (intentData != null) {
        await ref
            .read(usageRepositoryProvider)
            .recordUsage(promptId, intentData.callingPackage);
      }
      await ProcessTextChannel.setResult(text);
    } else {
      await BubbleChannel.insertText(text);
    }
  }

  List<Prompt> get _filtered {
    if (_query.isEmpty) return _prompts;
    final q = _query.toLowerCase();
    return _prompts
        .where((p) =>
            p.title.toLowerCase().contains(q) ||
            p.body.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () {
                if (widget.mode == OverlayMode.processText) {
                  ProcessTextChannel.cancel();
                } else {
                  BubbleChannel.cancel();
                }
              },
              child: Container(color: Colors.black54),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textTertiary.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: OverlaySearchBar(
                        onChanged: (q) => setState(() => _query = q),
                      ),
                    ),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: AppColors.accent),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => OverlayPromptRow(
                            prompt: _filtered[i],
                            onTap: () => _onPromptTapped(_filtered[i]),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run all tests to verify no regressions**

```bash
flutter test
```

Expected: all 27+ tests pass.

- [ ] **Step 3: Commit**

```bash
git add lib/features/overlay/overlay_screen.dart
git commit -m "feat: OverlayMode enum — processText and bubble paths share same overlay widget"
```

---

## Task 8: Update app.dart + Settings Screen

**Files:**
- Modify: `lib/app.dart`
- Modify: `lib/features/settings/settings_screen.dart`

- [ ] **Step 1: Add /bubble-overlay route to app.dart**

Read `lib/app.dart`. Find the routes list and add the bubble-overlay route. Add it alongside the `/overlay` route:

```dart
GoRoute(path: '/overlay', builder: (_, __) => const OverlayScreen()),
GoRoute(
  path: '/bubble-overlay',
  builder: (_, __) => const OverlayScreen(mode: OverlayMode.bubble),
),
```

Also add the import at the top of app.dart:
```dart
import 'features/overlay/overlay_screen.dart';
```
(already present — `OverlayMode` is defined in that file, so the import covers it)

- [ ] **Step 2: Replace settings_screen.dart**

Read `lib/features/settings/settings_screen.dart` first. Then replace it with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../services/settings_channel.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  bool _bubbleRunning = false;
  bool _togglingBubble = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshBubbleState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshBubbleState();
  }

  Future<void> _refreshBubbleState() async {
    final running = await SettingsChannel.isBubbleRunning();
    if (mounted) setState(() => _bubbleRunning = running);
  }

  Future<void> _onBubbleToggle(bool value) async {
    if (_togglingBubble) return;
    setState(() => _togglingBubble = true);

    try {
      if (value) {
        await _enableBubble();
      } else {
        await SettingsChannel.stopBubble();
        if (mounted) setState(() => _bubbleRunning = false);
      }
    } finally {
      if (mounted) setState(() => _togglingBubble = false);
    }
  }

  Future<void> _enableBubble() async {
    final hasOverlay = await SettingsChannel.hasOverlayPermission();
    if (!hasOverlay) {
      if (!mounted) return;
      final grant = await _showPermissionDialog(
        title: 'Draw Over Other Apps',
        body:
            'Loadstash needs the "Draw over other apps" permission to show the floating bubble.',
        action: 'Grant',
      );
      if (grant == true) await SettingsChannel.openOverlaySettings();
      return; // onResume will re-check
    }

    final hasA11y = await SettingsChannel.isAccessibilityEnabled();
    if (!hasA11y) {
      if (!mounted) return;
      final open = await _showPermissionDialog(
        title: 'Accessibility Permission',
        body:
            'Loadstash uses accessibility to detect when the keyboard opens and to paste your prompt. It only reads which windows are open — nothing else.',
        action: 'Open Settings',
      );
      if (open == true) await SettingsChannel.openAccessibilitySettings();
      return; // onResume will re-check
    }

    await SettingsChannel.startBubble();
    if (mounted) setState(() => _bubbleRunning = true);
  }

  Future<bool?> _showPermissionDialog({
    required String title,
    required String body,
    required String action,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface2,
        title: Text(title, style: AppTypography.label),
        content: Text(body, style: AppTypography.bodySmall),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action,
                style: const TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppTypography.screenTitle),
        backgroundColor: AppColors.bgBase,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionLabel('Floating Bubble'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: SwitchListTile(
              title: Text('Enable bubble', style: AppTypography.label),
              subtitle: Text(
                _bubbleRunning
                    ? 'Bubble is active — opens on keyboard'
                    : 'Appears when keyboard opens in any app',
                style: AppTypography.bodySmall,
              ),
              value: _bubbleRunning,
              onChanged: _togglingBubble ? null : _onBubbleToggle,
              activeColor: AppColors.accent,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 24),
          _sectionLabel('Privacy'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: Text(
              'All your prompts and usage data are stored locally on your device. '
              'Nothing is sent to any server. Your browsing habits and prompt '
              'choices never leave your phone.',
              style: AppTypography.bodySmall,
            ),
          ),
          const SizedBox(height: 24),
          _sectionLabel('About'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Loadstash', style: AppTypography.label),
                const SizedBox(height: 4),
                Text('v1.0.0 · Local-first prompt library',
                    style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title.toUpperCase(),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
```

- [ ] **Step 3: Run all tests**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 4: Build APK**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 5: Commit**

```bash
git add lib/app.dart lib/features/settings/settings_screen.dart
git commit -m "feat: bubble-overlay route, settings screen with bubble toggle and permission onboarding"
```

---

## Task 9: End-to-End Build Verification + Integration Test

**Files:**
- Create: `test/integration/bubble_flow_test.dart`

- [ ] **Step 1: Write bubble flow integration test**

Create `test/integration/bubble_flow_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/data/database/app_database.dart';
import 'package:loadstash/data/repositories/prompt_repository.dart';
import 'package:loadstash/data/repositories/usage_repository.dart';
import 'package:loadstash/services/variable_detector.dart';

// Verifies the bubble insertion path end-to-end:
// create prompt → rank (no callingPackage) → detect vars → substitute → record usage

void main() {
  late AppDatabase db;
  late PromptRepository promptRepo;
  late UsageRepository usageRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    promptRepo = PromptRepository(db);
    usageRepo = UsageRepository(db);
  });

  tearDown(() async => db.close());

  test('bubble path: create prompt, rank without callingPackage, substitute vars', () async {
    final id = await promptRepo.create(
      title: 'Write an email',
      body: 'Write a professional email about: {{topic}}\n\nTone: {{tone}}',
    );

    // Bubble mode ranks without callingPackage — should still return the prompt
    final ranked = await usageRepo.getRankedPrompts('');
    expect(ranked.any((p) => p.id == id), true);

    final prompt = await promptRepo.getById(id);
    final vars = VariableDetector.detect(prompt!.body);
    expect(vars, ['topic', 'tone']);

    final assembled = VariableDetector.substitute(
      prompt.body,
      {'topic': 'project update', 'tone': 'formal'},
    );
    expect(assembled, contains('project update'));
    expect(assembled, isNot(contains('{{topic}}')));

    // Record usage with empty package (bubble mode)
    await usageRepo.recordUsage(id, '');
    final stat = await db.usageDao.getUsageStat(id, '');
    expect(stat!.count, 1);
  });

  test('OverlayMode.bubble path does not require callingPackage', () async {
    await promptRepo.create(title: 'A', body: 'Body A');
    await promptRepo.create(title: 'B', body: 'Body B');

    final ranked = await usageRepo.getRankedPrompts('');
    expect(ranked.length, 2);
  });
}
```

- [ ] **Step 2: Run integration test**

```bash
flutter test test/integration/bubble_flow_test.dart
```

Expected: 2 tests pass.

- [ ] **Step 3: Run full test suite**

```bash
flutter test
```

Expected: all tests pass (29+).

- [ ] **Step 4: Final build**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 5: Commit**

```bash
git add test/integration/bubble_flow_test.dart
git commit -m "feat: bubble flow integration test, floating bubble v1 complete"
```

---

## Self-Review: Spec Coverage

| Spec requirement | Task |
|---|---|
| Keyboard-triggered (show on keyboard open) | Task 2 (AccessibilityService TYPE_WINDOWS_CHANGED) |
| Floating circular bubble at screen edge | Task 3 (BubbleService WindowManager) |
| Draggable, snaps to edge | Task 3 (BubbleService touch + ValueAnimator) |
| Bubble tapped → launches overlay | Task 3 (onBubbleTapped → BubbleOverlayActivity) |
| BubbleOverlayActivity transparent theme | Task 5 (manifest TransparentTheme) |
| Same overlay UI, bubble mode | Task 7 (OverlayMode enum) |
| No getIntentData in bubble mode | Task 7 (_init() mode branch) |
| Clipboard + accessibility paste | Task 4 (BubbleOverlayActivity insertText + AccessibilityService.doPaste) |
| 300ms paste delay | Task 2 (Handler.postDelayed 300ms) |
| Foreground notification with Stop action | Task 3 (BubbleService.buildNotification) |
| Settings toggle with permission onboarding | Task 8 (SettingsScreen) |
| Overlay permission check + deep-link | Task 8 (_enableBubble → openOverlaySettings) |
| Accessibility permission check + deep-link | Task 8 (_enableBubble → openAccessibilitySettings) |
| onResume re-check after returning from Settings | Task 8 (WidgetsBindingObserver.didChangeAppLifecycleState) |
| SettingsChannel start/stop/check | Task 6 + Task 5 (MainActivity) |
| /bubble-overlay route | Task 8 (app.dart) |
