import 'package:flutter/services.dart';
import '../providers/overlay_provider.dart';

class ProcessTextChannel {
  static const _channel = MethodChannel('com.loadstash/overlay');

  static Future<OverlayIntentData?> getIntentData() async {
    try {
      final data = await _channel.invokeMapMethod<String, dynamic>('getIntentData');
      if (data == null) return null;
      return OverlayIntentData(
        selectedText: data['selectedText'] as String? ?? '',
        isReadOnly: data['isReadOnly'] as bool? ?? false,
        callingPackage: data['callingPackage'] as String? ?? '',
      );
    } on PlatformException {
      return null;
    }
  }

  static Future<void> setResult(String text) async {
    try {
      await _channel.invokeMethod('setResult', {'text': text});
    } on PlatformException {
      // Overlay closed or engine not ready — safe to ignore
    }
  }

  static Future<void> cancel() async {
    try {
      await _channel.invokeMethod('cancel');
    } on PlatformException {
      // Overlay closed or engine not ready — safe to ignore
    }
  }
}
