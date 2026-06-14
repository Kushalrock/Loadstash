import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/services/process_text_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.loadstash/overlay');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'getIntentData':
          return {
            'selectedText': 'selected text here',
            'isReadOnly': false,
            'callingPackage': 'com.anthropic.claude',
          };
        case 'setResult':
        case 'cancel':
          return null;
        default:
          throw PlatformException(code: 'NOT_IMPL');
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getIntentData returns OverlayIntentData', () async {
    final data = await ProcessTextChannel.getIntentData();
    expect(data, isNotNull);
    expect(data!.selectedText, 'selected text here');
    expect(data.isReadOnly, false);
    expect(data.callingPackage, 'com.anthropic.claude');
  });

  test('getIntentData returns null on PlatformException', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'ERROR');
    });
    final data = await ProcessTextChannel.getIntentData();
    expect(data, isNull);
  });

  test('setResult completes without error', () async {
    expect(ProcessTextChannel.setResult('Final prompt text'), completes);
  });
}
