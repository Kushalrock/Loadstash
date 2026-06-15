import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelTag {
  const ModelTag({
    required this.key,
    required this.label,
    required this.color,
    this.builtin = false,
  });

  final String key;
  final String label;
  final String color; // hex e.g. "#D97757"
  final bool builtin;

  Color get colorValue {
    try {
      final hex = color.startsWith('#') ? color.substring(1) : color;
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF8A909C);
    }
  }

  Map<String, dynamic> toJson() =>
      {'key': key, 'label': label, 'color': color, 'builtin': builtin};

  factory ModelTag.fromJson(Map<String, dynamic> json) => ModelTag(
        key: json['key'] as String,
        label: json['label'] as String,
        color: json['color'] as String,
        builtin: json['builtin'] as bool? ?? false,
      );

  ModelTag copyWith({String? key, String? label, String? color, bool? builtin}) =>
      ModelTag(
        key: key ?? this.key,
        label: label ?? this.label,
        color: color ?? this.color,
        builtin: builtin ?? this.builtin,
      );
}

abstract final class ModelTagService {
  static const _key = 'model_tags';

  static List<ModelTag> _cache = [];

  static const _defaults = [
    ModelTag(key: 'claude',  label: 'Claude',  color: '#D97757', builtin: true),
    ModelTag(key: 'chatgpt', label: 'ChatGPT', color: '#10A37F', builtin: true),
    ModelTag(key: 'gemini',  label: 'Gemini',  color: '#5B9CF6', builtin: true),
    ModelTag(key: 'local',   label: 'Local',   color: '#8A909C', builtin: true),
  ];

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      _cache = List.of(_defaults);
      await _persist(prefs);
    } else {
      try {
        final list = jsonDecode(raw) as List;
        _cache = list
            .map((e) => ModelTag.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _cache = List.of(_defaults);
      }
    }
  }

  static List<ModelTag> get all => List.unmodifiable(_cache);

  static Color colorForKey(String key) {
    try {
      return _cache.firstWhere((t) => t.key == key).colorValue;
    } catch (_) {
      return const Color(0xFF8A909C);
    }
  }

  static Future<void> save(List<ModelTag> tags) async {
    _cache = List.of(tags);
    final prefs = await SharedPreferences.getInstance();
    await _persist(prefs);
  }

  static Future<void> _persist(SharedPreferences prefs) async {
    await prefs.setString(
        _key, jsonEncode(_cache.map((t) => t.toJson()).toList()));
  }
}
