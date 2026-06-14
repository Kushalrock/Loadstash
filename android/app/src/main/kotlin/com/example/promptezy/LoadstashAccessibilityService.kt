package com.example.promptezy

import android.accessibilityservice.AccessibilityService
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityWindowInfo

class LoadstashAccessibilityService : AccessibilityService() {

    companion object {
        @Volatile
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
        try {
            val hasKeyboard = windows?.any { it.type == AccessibilityWindowInfo.TYPE_INPUT_METHOD } ?: false
            if (hasKeyboard && !keyboardVisible) {
                keyboardVisible = true
                BubbleService.show()
            } else if (!hasKeyboard && keyboardVisible) {
                keyboardVisible = false
                BubbleService.hide()
            }
        } catch (_: Exception) {}
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacksAndMessages(null)
        instance = null
    }

    fun doPaste() {
        handler.postDelayed({
            performGlobalAction(GLOBAL_ACTION_PASTE)
        }, 300)
    }
}
