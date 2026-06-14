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
        handler.postDelayed({
            try {
                val root = rootInActiveWindow ?: return@postDelayed
                try {
                    // Strategy 1: accessibility-focused input field (fast path, standard apps)
                    val focused =
                        root.findFocus(android.view.accessibility.AccessibilityNodeInfo.FOCUS_INPUT)
                            ?: root.findFocus(android.view.accessibility.AccessibilityNodeInfo.FOCUS_ACCESSIBILITY)
                    if (focused != null && pasteIntoNode(focused)) {
                        focused.recycle()
                        return@postDelayed
                    }
                    focused?.recycle()

                    // Strategy 2: tree traversal — finds the editable field even when
                    // the app (ChatGPT, Claude) hasn't re-registered accessibility focus yet.
                    val editable = findFirstEditable(root)
                    if (editable != null) {
                        pasteIntoNode(editable)
                        editable.recycle()
                    }
                } finally {
                    root.recycle()
                }
            } catch (_: Exception) {}
        }, 800)
    }

    // DFS through the accessibility tree — returns the first editable node found.
    // Returns an obtained copy; caller must recycle it.
    @Suppress("DEPRECATION")
    private fun findFirstEditable(
        node: android.view.accessibility.AccessibilityNodeInfo
    ): android.view.accessibility.AccessibilityNodeInfo? {
        if (node.isEditable) {
            return android.view.accessibility.AccessibilityNodeInfo.obtain(node)
        }
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val found = findFirstEditable(child)
            child.recycle()
            if (found != null) return found
        }
        return null
    }

    // Returns true if paste succeeded via either strategy.
    private fun pasteIntoNode(node: android.view.accessibility.AccessibilityNodeInfo): Boolean {
        // Primary: ACTION_PASTE (standard EditText)
        if (node.performAction(android.view.accessibility.AccessibilityNodeInfo.ACTION_PASTE)) return true

        // Fallback: ACTION_SET_TEXT — works for React Native TextInput and many
        // custom components that block ACTION_PASTE but honour direct text setting.
        val clipboard = getSystemService(android.content.Context.CLIPBOARD_SERVICE)
            as? android.content.ClipboardManager
        val text = clipboard?.primaryClip?.getItemAt(0)?.text?.toString() ?: return false
        val args = android.os.Bundle().apply {
            putCharSequence(
                android.view.accessibility.AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE,
                text
            )
        }
        return node.performAction(android.view.accessibility.AccessibilityNodeInfo.ACTION_SET_TEXT, args)
    }
}
