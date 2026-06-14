package com.example.promptezy

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
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
        // Reinforce FLAG_RETRIEVE_INTERACTIVE_WINDOWS programmatically — the XML
        // attribute alone is not always honoured on Android 12+ builds.
        try {
            val info = serviceInfo ?: AccessibilityServiceInfo()
            info.flags = info.flags or AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
            info.eventTypes = AccessibilityEvent.TYPE_WINDOWS_CHANGED or
                    AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            serviceInfo = info
        } catch (_: Exception) {}
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType != AccessibilityEvent.TYPE_WINDOWS_CHANGED &&
            event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        checkKeyboardVisibility()
    }

    private fun checkKeyboardVisibility() {
        try {
            val hasKeyboard = windows?.any {
                it.type == AccessibilityWindowInfo.TYPE_INPUT_METHOD
            } ?: false
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
        // 800ms: gives React Native (ChatGPT, Claude) time to re-focus the text field
        // after the overlay activity finishes its transition back.
        handler.postDelayed({
            try {
                val root = rootInActiveWindow ?: return@postDelayed
                try {
                    val focused =
                        root.findFocus(android.view.accessibility.AccessibilityNodeInfo.FOCUS_INPUT)
                            ?: root.findFocus(android.view.accessibility.AccessibilityNodeInfo.FOCUS_ACCESSIBILITY)
                    if (focused != null) {
                        pasteIntoNode(focused)
                        focused.recycle()
                    }
                } finally {
                    root.recycle()
                }
            } catch (_: Exception) {}
        }, 800)
    }

    private fun pasteIntoNode(node: android.view.accessibility.AccessibilityNodeInfo) {
        // Primary: ACTION_PASTE — works for standard EditText
        if (node.performAction(android.view.accessibility.AccessibilityNodeInfo.ACTION_PASTE)) return

        // Fallback: ACTION_SET_TEXT — works for React Native TextInput (ChatGPT, Claude)
        // even when ACTION_PASTE is not supported by the component.
        val clipboard = getSystemService(android.content.Context.CLIPBOARD_SERVICE)
            as? android.content.ClipboardManager
        val text = clipboard?.primaryClip?.getItemAt(0)?.text?.toString() ?: return
        val args = android.os.Bundle().apply {
            putCharSequence(
                android.view.accessibility.AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE,
                text
            )
        }
        node.performAction(android.view.accessibility.AccessibilityNodeInfo.ACTION_SET_TEXT, args)
    }
}
