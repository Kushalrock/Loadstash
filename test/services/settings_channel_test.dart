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

  test('all bool methods return false on exception', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'ERROR');
    });
    expect(await SettingsChannel.hasOverlayPermission(), false);
    expect(await SettingsChannel.isAccessibilityEnabled(), false);
    expect(await SettingsChannel.isBubbleRunning(), false);
  });
}
