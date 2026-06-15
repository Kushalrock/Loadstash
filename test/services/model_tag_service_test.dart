import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadstash/services/model_tag_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('initializes with 4 default tags', () async {
    await ModelTagService.initialize();
    expect(ModelTagService.all.length, 4);
    expect(ModelTagService.all.map((t) => t.key),
        containsAll(['claude', 'chatgpt', 'gemini', 'local']));
  });

  test('colorForKey returns correct color for known key', () async {
    await ModelTagService.initialize();
    expect(ModelTagService.colorForKey('claude').value,
        const Color(0xFFD97757).value);
  });

  test('colorForKey returns fallback grey for unknown key', () async {
    await ModelTagService.initialize();
    expect(ModelTagService.colorForKey('unknown').value,
        const Color(0xFF8A909C).value);
  });

  test('save and reload persists tags', () async {
    await ModelTagService.initialize();
    final newTags = [
      ...ModelTagService.all,
      const ModelTag(key: 'myai', label: 'My AI', color: '#F43F5E'),
    ];
    await ModelTagService.save(newTags);
    await ModelTagService.initialize();
    expect(ModelTagService.all.length, 5);
    expect(ModelTagService.all.last.key, 'myai');
  });

  test('ModelTag.colorValue parses hex correctly', () {
    const tag = ModelTag(key: 'x', label: 'X', color: '#F43F5E');
    expect(tag.colorValue.value, const Color(0xFFF43F5E).value);
  });
}
