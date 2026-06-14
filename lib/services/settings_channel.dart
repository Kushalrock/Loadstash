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
