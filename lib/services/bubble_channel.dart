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
