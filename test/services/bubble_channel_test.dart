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
    await expectLater(BubbleChannel.insertText('text'), completes);
  });

  test('cancel sends cancel over channel', () async {
    await BubbleChannel.cancel();
    expect(calls.first.method, 'cancel');
  });
}
