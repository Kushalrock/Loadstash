# Floating Bubble — Design Spec

**Goal:** Let users insert prompts into any Android text field (including apps like ChatGPT that don't support ACTION_PROCESS_TEXT) via a keyboard-triggered floating bubble.

**Approach:** Foreground service owns the bubble window. Accessibility service detects keyboard and pastes. BubbleOverlayActivity hosts the Flutter overlay UI. Clipboard is the insertion bridge.

---

## User Flow

1. User opens Loadstash → Settings → toggles **Floating Bubble** ON
2. App checks `SYSTEM_ALERT_WINDOW` — if not granted, opens system Overlay Permission screen
3. App checks Accessibility Service enabled — if not, opens Accessibility Settings with a dialog explaining the purpose
4. Once both granted: `BubbleService` starts, foreground notification appears ("Bubble active — tap to insert prompts" + **Stop** action)
5. User switches to any app (ChatGPT, Claude, browser, etc.) and opens a text field
6. `LoadstashAccessibilityService` detects keyboard open → `BubbleService.showBubble()`
7. A circular "L" icon appears at the screen edge (draggable)
8. User taps the bubble → `BubbleOverlayActivity` launches (transparent, same overlay UI)
9. User searches, picks a prompt, fills variables → assembled text ready
10. `BubbleChannel.insertText(text)` → text copied to clipboard → activity finishes → 300ms delay → `performGlobalAction(GLOBAL_ACTION_PASTE)` inserts it
11. Keyboard closes → bubble hides

User can stop the bubble from the notification **Stop** action or from the Settings toggle.

---

## Architecture

```
Settings toggle (Flutter)
    │
    ▼ SettingsChannel ("com.loadstash/settings")
    │
    ▼
BubbleService (foreground, Android)
  • owns floating bubble View in WindowManager (TYPE_APPLICATION_OVERLAY)
  • shows/hides on BUBBLE_SHOW / BUBBLE_HIDE broadcasts
  • draggable, snaps to nearest edge on release
  • tapping → startActivity(BubbleOverlayActivity, FLAG_ACTIVITY_NEW_TASK)
  • foreground notification: "Bubble active" + Stop action
    │
    │  local broadcasts
    ▼
LoadstashAccessibilityService (Android)
  • onAccessibilityEvent(TYPE_WINDOWS_CHANGED)
      present TYPE_INPUT_METHOD window → sendBroadcast(BUBBLE_SHOW)
      absent  TYPE_INPUT_METHOD window → sendBroadcast(BUBBLE_HIDE)
  • on PASTE_BROADCAST → Handler.postDelayed(300ms) → performGlobalAction(GLOBAL_ACTION_PASTE)

BubbleOverlayActivity (FlutterActivity, transparent theme)
  • getInitialRoute() → "/bubble-overlay"
  • MethodChannel("com.loadstash/bubble"):
      insertText(text) → ClipboardManager.setPrimaryClip → sendBroadcast(PASTE_BROADCAST) → finish()
```

---

## New Files

### Kotlin
| File | Purpose |
|------|---------|
| `BubbleService.kt` | Foreground service, owns floating window |
| `LoadstashAccessibilityService.kt` | Keyboard detection + paste |
| `BubbleOverlayActivity.kt` | Flutter activity for bubble overlay path |
| `res/xml/accessibility_service_config.xml` | Accessibility service config |

### Flutter
| File | Purpose |
|------|---------|
| `lib/services/bubble_channel.dart` | MethodChannel wrapper for insertText |
| `lib/services/settings_channel.dart` | MethodChannel for permission checks + service control |

### Modified
| File | Change |
|------|--------|
| `lib/features/overlay/overlay_screen.dart` | Add `OverlayMode` enum (processText / bubble); skip getIntentData in bubble mode |
| `lib/features/settings/settings_screen.dart` | Add Floating Bubble toggle section with permission onboarding |
| `lib/app.dart` | Add `/bubble-overlay` route → `OverlayScreen(mode: OverlayMode.bubble)` |
| `android/app/src/main/AndroidManifest.xml` | New permissions, service + activity declarations |
| `android/app/src/main/res/values/strings.xml` | Accessibility service description string |

---

## Permissions

```xml
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
```

`BIND_ACCESSIBILITY_SERVICE` is declared on the service element (not a `<uses-permission>`).

---

## BubbleService detail

- View: 56dp circular `ImageView`, accent colour background `#8B7DF6`, white "L" text
- Initial position: right edge, vertically centred
- `WindowManager.LayoutParams`: `TYPE_APPLICATION_OVERLAY`, `FLAG_NOT_FOCUSABLE | FLAG_LAYOUT_IN_SCREEN`
- Drag: `ACTION_DOWN` records offset; `ACTION_MOVE` updates `params.x / params.y`; `ACTION_UP` snaps x to 0 (left) or `screenWidth - bubbleSize` (right), animates with `ObjectAnimator`
- Show/hide: `view.visibility = View.VISIBLE / GONE` (not remove/re-add, avoids flicker)
- Tap detection: distinguish from drag via `ACTION_DOWN` → `ACTION_UP` with `< 8dp` total movement

---

## LoadstashAccessibilityService detail

```xml
<!-- res/xml/accessibility_service_config.xml -->
<accessibility-service
    android:accessibilityEventTypes="typeWindowsChanged"
    android:accessibilityFeedbackType="feedbackGeneric"
    android:canRetrieveWindowContent="true"
    android:notificationTimeout="100" />
```

Keyboard detection:
```kotlin
override fun onAccessibilityEvent(event: AccessibilityEvent) {
    if (event.eventType != AccessibilityEvent.TYPE_WINDOWS_CHANGED) return
    val hasKeyboard = windows.any { it.type == AccessibilityWindowInfo.TYPE_INPUT_METHOD }
    val intent = Intent(if (hasKeyboard) ACTION_BUBBLE_SHOW else ACTION_BUBBLE_HIDE)
    sendBroadcast(intent)
}
```

Paste:
```kotlin
fun pasteAfterDelay() {
    Handler(Looper.getMainLooper()).postDelayed({
        performGlobalAction(GLOBAL_ACTION_PASTE)
    }, 300)
}
```

---

## Settings Permission Onboarding Flow

```
Toggle ON tapped
    │
    ├─ SYSTEM_ALERT_WINDOW not granted?
    │       → AlertDialog: "Loadstash needs Draw Over Other Apps permission to show the bubble"
    │         [Grant] → Settings.ACTION_MANAGE_OVERLAY_PERMISSION → onResume re-check
    │
    ├─ Accessibility not enabled?
    │       → AlertDialog: "Loadstash uses accessibility to detect the keyboard and paste prompts.
    │         It reads which windows are open — nothing else."
    │         [Open Settings] → Settings.ACTION_ACCESSIBILITY_SETTINGS
    │         onResume re-check
    │
    └─ Both granted → startService(BubbleService)
                      toggle shows ON + "Bubble is active" subtitle

Toggle OFF tapped → stopService(BubbleService) → toggle shows OFF
```

---

## SettingsChannel (Kotlin, registered in MainActivity)

Methods:
- `hasOverlayPermission` → `Settings.canDrawOverlays(context)`
- `isAccessibilityEnabled` → check `AccessibilityManager.getEnabledAccessibilityServiceList`
- `startBubble` → `startForegroundService(BubbleService)`
- `stopBubble` → `stopService(BubbleService)`
- `isBubbleRunning` → check if service is running via a static flag on `BubbleService`

---

## OverlayScreen mode change

```dart
enum OverlayMode { processText, bubble }

class OverlayScreen extends ConsumerStatefulWidget {
  const OverlayScreen({super.key, this.mode = OverlayMode.processText});
  final OverlayMode mode;
}
```

`_init()`:
- `processText` mode: call `ProcessTextChannel.getIntentData()`, load ranked prompts with callingPackage
- `bubble` mode: skip getIntentData, load ranked prompts with empty callingPackage

`_insertAndClose()`:
- `processText` mode: `ProcessTextChannel.setResult(text)`
- `bubble` mode: `BubbleChannel.insertText(text)`

---

## Out of scope (v1 of bubble)

- Saving the focused accessibility node before launching the activity (current approach uses `GLOBAL_ACTION_PASTE` after 300ms delay, which pastes into whatever is focused — good enough for v1)
- Per-app bubble enable/disable
- Bubble icon customisation
- Boot-on-start (RECEIVE_BOOT_COMPLETED is declared but not wired — v2)
